/// obj_battle_manager :: Step Event
// Manages the battle flow using a state machine based on the speed queue (using string states).

// Check for pause or critical failures
if (instance_exists(obj_pause_menu)) exit; // Example pause check
if (!ds_exists(combatants_all, ds_type_list)) {
    show_debug_message("CRITICAL ERROR: combatants_all list missing!");
    global.battle_state = "defeat"; // Or some error state
}

// Check global state exists (safety)
if (!variable_global_exists("battle_state")) {
     show_debug_message("CRITICAL ERROR: global.battle_state missing!");
     global.battle_state = "defeat"; // Attempt recovery
}


switch (global.battle_state) {

    case "initializing":
         // Should quickly transition out of this state from Create Event
         show_debug_message("Manager Step: Still Initializing...");
         // Add a safety check to force start if stuck?
         if (get_timer() > room_speed * 2) { // After 2 seconds
             show_debug_message(" -> Forcing start calculation.");
             global.battle_state = "calculate_turn";
         }
         break;

    case "calculate_turn": // New state using string name
    {
        show_debug_message("Manager Step: calculate_turn");
        
        // Clean up dead/destroyed instances from the list before calculating
        for (var i = ds_list_size(combatants_all) - 1; i >= 0; i--) {
            var _inst = combatants_all[| i];
            if (!instance_exists(_inst)) {
                ds_list_delete(combatants_all, i);
                 show_debug_message(" -> Removed destroyed instance from combatants_all list.");
            } else if (variable_instance_exists(_inst, "data") && is_struct(_inst.data) && variable_struct_exists(_inst.data, "hp") && _inst.data.hp <= 0) {
                 // Keep dead units in the list for now, scr_SpeedQueue ignores them. check_win_loss handles removal.
            }
        }

        // Check for immediate win/loss conditions before calculating turn
         var _party_alive = false;
         var _enemies_alive = false;
         if (ds_exists(global.battle_party, ds_type_list)) {
             for(var i=0; i<ds_list_size(global.battle_party); i++){var p=global.battle_party[|i]; if(instance_exists(p) && variable_instance_exists(p,"data") && is_struct(p.data) && p.data.hp > 0){_party_alive=true; break;}}
         }
          if (ds_exists(global.battle_enemies, ds_type_list)) {
              for(var i=0; i<ds_list_size(global.battle_enemies); i++){var e=global.battle_enemies[|i]; if(instance_exists(e) && variable_instance_exists(e,"data") && is_struct(e.data) && e.data.hp > 0){_enemies_alive=true; break;}}
          }
          
          if (!_enemies_alive && _party_alive) { global.battle_state = "victory"; alarm[0] = 1; break; }
          if (!_party_alive) { global.battle_state = "defeat"; alarm[0] = 1; break; }
          if (!_enemies_alive && !_party_alive) { global.battle_state = "defeat"; alarm[0] = 1; break; }

        // Calculate next turn using the script
        var turn_result = script_exists(scr_SpeedQueue) ? scr_SpeedQueue(combatants_all, BASE_TICK_VALUE) : { actor: noone, time_advance: 0 };
        currentActor = turn_result.actor;

        if (currentActor == noone) {
            show_debug_message(" -> No valid actor found by speed queue. Checking win/loss.");
            global.battle_state = "check_win_loss"; 
        } else {
            // --- NEW: Check for Turn Skipping Status Effects ---
            var skip_turn = false;
            var status_info = script_exists(scr_GetStatus) ? scr_GetStatus(currentActor) : undefined;
            
            if (is_struct(status_info)) {
                switch (status_info.effect) {
                    case "shame":
                        show_debug_message(" -> Actor " + string(currentActor) + " turn skipped due to Shame!");
                        skip_turn = true;
                        // Optional: Popup text
                        // if (object_exists(obj_popup_damage)) { instance_create_layer(currentActor.x, currentActor.y-64, "Instances", obj_popup_damage).damage_amount = "Shamed!";}
                        break;
                    case "bind":
                        if (irandom(99) < 50) { // 50% chance to be bound
                             show_debug_message(" -> Actor " + string(currentActor) + " turn skipped due to Bind!");
                             skip_turn = true;
                             // Optional: Popup text
                             // if (object_exists(obj_popup_damage)) { instance_create_layer(currentActor.x, currentActor.y-64, "Instances", obj_popup_damage).damage_amount = "Bound!";}
                        }
                        break;
                    // Add other skipping statuses like "stop", "sleep", "petrify" here
                    // case "stop": skip_turn = true; break;
                }
            }
            
            // --- Determine Next State ---
            if (skip_turn) {
                 global.battle_state = "action_complete"; // Skip directly to finishing the turn
            } else {
                 // Determine if player or enemy (using the corrected check)
                 if (currentActor.object_index == obj_battle_player) { 
                     show_debug_message(" -> Next Actor is Player: " + string(currentActor));
                     stored_action_data = undefined;
                     selected_target_id = noone;
                     global.active_party_member_index = ds_list_find_index(global.battle_party, currentActor); 
                     global.battle_state = "player_input"; 
                 } else { // Assume enemy 
                     show_debug_message(" -> Next Actor is Enemy: " + string(currentActor));
                     global.battle_state = "enemy_turn"; 
                 }
            }
        }
    }
    break; // End "calculate_turn"

    // --- Your Original States ---
    case "player_input":
    case "skill_select":
    case "item_select":
         // In these states, wait for input (likely handled by obj_battle_menu).
         // Ensure the currentActor is still valid and not KO'd.
        if (instance_exists(currentActor)) {
             if (currentActor.data.hp <= 0) {
                 show_debug_message(" -> Actor " + string(currentActor) + " is KO'd during state " + global.battle_state + ". Skipping turn.");
                 global.battle_state = "action_complete"; // Skip turn
             }
             // Normal waiting for input otherwise
        } else if (global.battle_state == "player_input" || global.battle_state == "skill_select" || global.battle_state == "item_select") { 
             // Only recalculate if actor is missing during an expected player turn state
             show_debug_message(" -> Actor " + string(currentActor) + " invalid during input state " + global.battle_state + ". Recalculating turn.");
             currentActor = noone;
             global.battle_state = "calculate_turn";
        }
        break; // Let obj_battle_menu handle transitions out of these states

    case "TargetSelect": // <<< Use original string state
    {
         show_debug_message("Manager Step: In TargetSelect State");
         
          // --- Ensure valid actor ---
          if (!instance_exists(currentActor) || stored_action_data == undefined) {
             show_debug_message(" -> ERROR: Invalid state for Target Select (no actor or action). Returning to player input.");
              // Add back item if needed
              if (is_struct(stored_action_data) && variable_struct_exists(stored_action_data, "usable_in_battle") && script_exists(scr_AddInventoryItem)) {
                   if (variable_struct_exists(stored_action_data, "item_key")) scr_AddInventoryItem(stored_action_data.item_key, 1);
               }
             stored_action_data = undefined;
             selected_target_id = noone;
             if (instance_exists(currentActor)) global.battle_state = "player_input"; // Back to input for current actor
             else global.battle_state = "calculate_turn"; // Actor gone, find next turn
             break;
         }
         // Check if actor is KO'd
          else if (currentActor.data.hp <= 0) {
              show_debug_message(" -> Actor " + string(currentActor) + " is KO'd during TargetSelect. Skipping turn.");
              stored_action_data = undefined; selected_target_id = noone; // Clear action
              global.battle_state = "action_complete"; 
              break;
          }

         // Check if enemies list exists and has entries
         if (!variable_global_exists("battle_enemies") || !ds_exists(global.battle_enemies, ds_type_list) || ds_list_empty(global.battle_enemies)) {
             show_debug_message(" -> No enemies to target. Cancelling action.");
             // Add back item if needed
              if (is_struct(stored_action_data) && variable_struct_exists(stored_action_data, "usable_in_battle") && script_exists(scr_AddInventoryItem)) {
                  if (variable_struct_exists(stored_action_data, "item_key")) scr_AddInventoryItem(stored_action_data.item_key, 1);
              }
             stored_action_data = undefined;
             global.battle_state = "player_input"; // Go back to command selection for the *current* actor
             break;
         }
         var _enemy_count = ds_list_size(global.battle_enemies);

        // --- Input Handling (Keep your existing input checks) ---
         var P = 0;
         var _up = keyboard_check_pressed(vk_up) || gamepad_button_check_pressed(P, gp_padu);
         var _down = keyboard_check_pressed(vk_down) || gamepad_button_check_pressed(P, gp_padd);
         var _conf = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(P, gp_face1);
         var _cancel = keyboard_check_pressed(vk_escape)|| gamepad_button_check_pressed(P, gp_face2);

         if (_down) { global.battle_target = (global.battle_target + 1) % _enemy_count; } 
         else if (_up) { global.battle_target = (global.battle_target - 1 + _enemy_count) % _enemy_count; } 
         else if (_conf) {
             if (global.battle_target >= 0 && global.battle_target < _enemy_count) {
                 selected_target_id = global.battle_enemies[| global.battle_target];
                 if (instance_exists(selected_target_id) && selected_target_id.data.hp > 0) { // Check if target is alive
                     show_debug_message(" -> Target Confirmed (ID: " + string(selected_target_id) + "). State -> ExecutingAction.");
                     global.battle_state = "ExecutingAction"; // <<< Use original string state
                 } else {
                     show_debug_message(" -> Selected target is invalid or dead. Resetting selection.");
                     selected_target_id = noone; // Stay in TargetSelect
                 }
             } else {
                 show_debug_message(" -> Invalid target index. Resetting selection.");
                 selected_target_id = noone; global.battle_target = 0; // Stay in TargetSelect
             }
         } else if (_cancel) {
             show_debug_message(" -> Target selection Cancelled. Returning.");
              // Add item back if needed
             if (is_struct(stored_action_data) && variable_struct_exists(stored_action_data, "usable_in_battle") && script_exists(scr_AddInventoryItem)) { if (variable_struct_exists(stored_action_data, "item_key")) scr_AddInventoryItem(stored_action_data.item_key, 1); }
              // Determine previous menu state (skill/item/player_input) - Your logic here was good
             var _prev = "player_input";
             if (is_struct(stored_action_data)) {
                 if (variable_struct_exists(stored_action_data, "usable_in_battle")) { _prev="item_select"; } // Uses your original state names
                 else if (variable_struct_exists(stored_action_data, "cost")) { _prev="skill_select"; } // Uses your original state names
             }
             global.battle_state = _prev; // Go back to choosing the action type
             stored_action_data = undefined;
             selected_target_id = noone;
         }
    }
    break; // End TargetSelect

    case "ExecutingAction": // <<< Use original string state
    {
        show_debug_message("Manager Step: In ExecutingAction State for Actor: " + string(currentActor));

        var _action_performed = false; // This flag indicates if the action was *attempted* or skipped, not necessarily if it succeeded
        if (instance_exists(currentActor)) {
            // Check if actor is KO'd before attempting anything
             if (currentActor.data.hp <= 0) {
                  show_debug_message(" -> Actor " + string(currentActor) + " is KO'd during ExecutingAction. Skipping turn.");
                  _action_performed = true; // Treat KO as a completed (skipped) action
                  global.battle_state = "action_complete";
             } else {
                 // Status check is now handled in 'calculate_turn', so we assume if we reach here, the actor wasn't skipped by status.
                 var _pd = currentActor.data; // Player data
                 var _action_succeeded = false; // Use a different flag for script success
                 
                 // --- Trigger Action ---
                 if (stored_action_data == "Attack") { if (script_exists(scr_PerformAttack)) { _action_succeeded = scr_PerformAttack(currentActor, selected_target_id); } } 
                 else if (is_struct(stored_action_data) && variable_struct_exists(stored_action_data, "usable_in_battle")) { if (script_exists(scr_UseItem)) { _action_succeeded = scr_UseItem(currentActor, stored_action_data, selected_target_id); } } 
                 else if (is_struct(stored_action_data) && variable_struct_exists(stored_action_data, "effect")) { if (script_exists(scr_CastSkill)) { _action_succeeded = scr_CastSkill(currentActor, stored_action_data, selected_target_id); } } 
                 else if (stored_action_data == "Defend") { if (variable_struct_exists(_pd, "is_defending")) { _pd.is_defending = true; } _action_succeeded = true; } // Defend is instant
                 // Add other actions here
                 
                 _action_performed = true; // Mark action as attempted/handled
                 
                 // --- Transition ---
                 if (_action_succeeded) {
                      show_debug_message(" -> Action script returned success. Moving to action_complete.");
                      global.battle_state = "action_complete"; // New state name
                 } else {
                      show_debug_message(" -> Action script returned failure (e.g., not enough MP, invalid target). Returning to player_input.");
                      // Don't clear stored_action_data here, player might want to re-target or choose different action
                      global.battle_state = "player_input"; // Let player choose again
                 }
             } // end !KO check
        } else {
             show_debug_message(" -> ERROR: Current Actor disappeared during ExecutingAction. Recalculating turn.");
             currentActor = noone;
             stored_action_data = undefined;
             selected_target_id = noone;
             global.battle_state = "calculate_turn";
             _action_performed = true; // Handled this path
        }
        
        // If we didn't transition yet (e.g., error case above didn't hit), ensure we move on
        if (!_action_performed) {
             show_debug_message(" -> Fallback: Ensuring transition from ExecutingAction.");
             global.battle_state = "action_complete"; // Default to moving on
        }
    }
    break; // End ExecutingAction

    case "enemy_turn": // <<< Use original string state
    {
        show_debug_message("Manager Step: In enemy_turn State for Actor: " + string(currentActor));
        
        var _enemy_acted = false; // Flag to see if the enemy did something (or skipped/failed)
        if (instance_exists(currentActor)) {
             // Check if KO'd
             if (currentActor.data.hp <= 0) {
                 show_debug_message(" -> Enemy " + string(currentActor) + " is KO'd. Skipping turn.");
                 _enemy_acted = true; // Treat KO as completed turn
                 global.battle_state = "action_complete";
             } else {
                 // Status check is handled in 'calculate_turn'. Assume turn proceeds.
                 var _action_succeeded = false;
                 // --- Trigger Enemy AI / Action ---
                 if (script_exists(scr_EnemyAttackRandom)) { 
                     _action_succeeded = scr_EnemyAttackRandom(currentActor); 
                     show_debug_message("    -> scr_EnemyAttackRandom returned: " + string(_action_succeeded));
                 } else {
                     show_debug_message("    -> WARNING: scr_EnemyAttackRandom missing! Enemy skips turn.");
                     _action_succeeded = true; // Assume turn ends if AI script is missing
                 }
                 
                 _enemy_acted = true; // Mark turn as processed
                 
                 // --- Transition ---
                 // Assume AI script blocks or handles its own timing for now
                 show_debug_message(" -> Enemy action processed. Moving to action_complete.");
                 global.battle_state = "action_complete"; // Move on regardless of success/failure reported by AI script for now
             } // end !KO check
        } else {
             show_debug_message(" -> ERROR: Current Enemy Actor " + string(currentActor) + " invalid. Moving to action_complete.");
             _enemy_acted = true; // Treat as processed
             global.battle_state = "action_complete"; // Skip turn if enemy is gone/dead
        }
        
        // Fallback transition
         if (!_enemy_acted) {
             show_debug_message(" -> Fallback: Ensuring transition from enemy_turn.");
             global.battle_state = "action_complete"; 
        }
     }
     break; // End enemy_turn

    case "action_complete": // New state name
    {
        // The currentActor has finished their turn (or skipped it). Reset counter, clear flags, update statuses, check win/loss.
        show_debug_message("Manager Step: action_complete for Actor: " + string(currentActor));
        
        if (instance_exists(currentActor)) {
             // Reset Defend status if applicable
             if (variable_instance_exists(currentActor, "data") && is_struct(currentActor.data) && variable_struct_exists(currentActor.data, "is_defending")) {
                 if (currentActor.data.is_defending) {
                      show_debug_message(" -> Resetting Defend status for " + string(currentActor));
                      currentActor.data.is_defending = false;
                 }
             }
             
             // Reset the turn counter for the actor who just went
             if (script_exists(scr_ResetTurnCounter)) {
                 scr_ResetTurnCounter(currentActor, BASE_TICK_VALUE);
             } else {
                  show_debug_message("ERROR: scr_ResetTurnCounter script missing!");
             }
        } else {
            show_debug_message(" -> Actor " + string(currentActor) + " no longer exists during action_complete.");
        }

        // Clear transient action data for the turn
        stored_action_data = undefined;
        selected_target_id = noone;
        currentActor = noone; // No one is actively taking a turn now
        global.active_party_member_index = -1; // Reset highlighted player HUD

        // Update status effects (like poison damage, duration ticks) AFTER the action is resolved.
        if (script_exists(scr_UpdateStatusEffects)) {
             scr_UpdateStatusEffects(); // Call your status update logic
        }

        // Recalculate the turn order display for the UI
        if (script_exists(scr_CalculateTurnOrderDisplay)) {
             turnOrderDisplay = scr_CalculateTurnOrderDisplay(combatants_all, BASE_TICK_VALUE, TURN_ORDER_DISPLAY_COUNT);
        }

        // Immediately check win/loss conditions
        global.battle_state = "check_win_loss"; // <<< Use original string state
    }
    break; // End "action_complete"

    case "check_win_loss": // <<< Use original string state
    {
         show_debug_message("Manager Step: In check_win_loss State");
         
         // --- Check for and remove dead enemies, grant XP ---
         var xp_gained_this_check = 0;
         if (ds_exists(global.battle_enemies, ds_type_list)) {
             for (var i = ds_list_size(global.battle_enemies) - 1; i >= 0; i--) {
                 var e_id = global.battle_enemies[| i]; // Get the ID first
                 if (instance_exists(e_id)) {
                     // Check HP using the ID
                     if (variable_instance_exists(e_id, "data") && is_struct(e_id.data) && variable_struct_exists(e_id.data, "hp") && e_id.data.hp <= 0) {
                         var xp_val = variable_struct_exists(e_id.data,"xp_value")?e_id.data.xp_value : (variable_struct_exists(e_id.data,"xp")?e_id.data.xp : 0);
                         xp_gained_this_check += xp_val;
                         show_debug_message(" -> Enemy " + string(e_id) + " defeated. XP: " + string(xp_val));
                         ds_list_delete(global.battle_enemies, i); // Remove from global list
                         var combatant_index = ds_list_find_index(combatants_all, e_id); // Remove from speed queue list
                         if (combatant_index != -1) ds_list_delete(combatants_all, combatant_index);
                         instance_destroy(e_id); // Destroy instance
                     }
                 } else {
                     // Instance missing, remove from list
                     ds_list_delete(global.battle_enemies, i); 
                     var combatant_index = ds_list_find_index(combatants_all, e_id); // Use the ID 
                      if (combatant_index != -1) ds_list_delete(combatants_all, combatant_index);
                 }
             }
         }
         total_xp_from_battle += xp_gained_this_check;
         if (xp_gained_this_check > 0) show_debug_message(" -> Total XP this battle: " + string(total_xp_from_battle));

         // --- Check for and remove dead party members from active list ---
          if (ds_exists(global.battle_party, ds_type_list)) {
              for (var i = ds_list_size(global.battle_party) - 1; i >= 0; i--) {
                  var p_id = global.battle_party[| i]; // Get ID
                  if (instance_exists(p_id)) {
                      if (variable_instance_exists(p_id, "data") && is_struct(p_id.data) && variable_struct_exists(p_id.data, "hp") && p_id.data.hp <= 0) {
                           show_debug_message(" -> Party member " + string(p_id) + " is KO'd.");
                           var combatant_index = ds_list_find_index(combatants_all, p_id);
                           if (combatant_index != -1) {
                               ds_list_delete(combatants_all, combatant_index);
                                show_debug_message("   -> Removed from active combatants list.");
                           }
                      }
                  } else {
                      // Instance missing
                      ds_list_delete(global.battle_party, i); // Remove missing instance from party list
                      var combatant_index = ds_list_find_index(combatants_all, p_id); // Use ID
                      if (combatant_index != -1) ds_list_delete(combatants_all, combatant_index);
                  }
              }
         }

        // --- Determine Battle Outcome ---
         var any_party_alive = false;
         if (ds_exists(global.battle_party, ds_type_list)) {
             for(var i=0; i<ds_list_size(global.battle_party); i++){var p=global.battle_party[|i]; if(instance_exists(p) && variable_instance_exists(p,"data") && is_struct(p.data) && p.data.hp > 0){any_party_alive=true; break;}}
         }
         var any_enemies_alive = (ds_exists(global.battle_enemies, ds_type_list) && ds_list_size(global.battle_enemies) > 0);

         if (!any_enemies_alive && any_party_alive) {
             show_debug_message(" -> Condition: Victory!");
             global.battle_state = "victory"; // <<< Use original string state
             alarm[0] = 60; // Trigger victory sequence after a delay
         } else if (!any_party_alive) {
             show_debug_message(" -> Condition: Defeat!");
             global.battle_state = "defeat"; // <<< Use original string state
             alarm[0] = 60; // Trigger defeat sequence after a delay
         } else {
             show_debug_message(" -> Battle continues. Calculating next turn.");
             // Clamp/Reset target index
             if (ds_exists(global.battle_enemies, ds_type_list)) {
                 if (ds_list_empty(global.battle_enemies)) { global.battle_target = -1; } 
                 else { global.battle_target = max(0, min(global.battle_target, ds_list_size(global.battle_enemies) - 1)); }
             } else { global.battle_target = -1; }
             
             global.battle_state = "calculate_turn"; // Loop back to find the next turn
         }
    }
    break; // End check_win_loss

    // --- Final States (Handled by Alarm[0]) ---
    case "victory":           // <<< Use original string state
    case "defeat":            // <<< Use original string state
    case "return_to_field":   // <<< Use original string state (Assuming you had this)
        // Waiting for Alarm[0] to process these
        break; 

    default:
        if (get_timer() mod 60 == 0) { // Logged once per second
             show_debug_message("WARNING: obj_battle_manager in unknown state: " + string(global.battle_state));
             global.battle_state = "check_win_loss"; // Try to recover
        }
        break;
} // End Switch