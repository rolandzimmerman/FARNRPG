/// obj_battle_manager :: Step Event
// Manages the battle flow using a state machine based on the speed queue (using string states).

// Check for pause or critical failures
if (instance_exists(obj_pause_menu)) exit; 
if (!ds_exists(combatants_all, ds_type_list)) { 
    show_debug_message("CRITICAL ERROR: combatants_all list missing!");
    global.battle_state = "defeat"; // Or some error state
    exit; 
}
if (!variable_global_exists("battle_state")) { 
    show_debug_message("CRITICAL ERROR: global.battle_state missing!");
    global.battle_state = "defeat"; // Attempt recovery
    exit; 
}


switch (global.battle_state) {

    case "initializing":
         if (get_timer() > room_speed * 2) { // Safety timeout
             show_debug_message(" -> Forcing start calculation from initializing.");
             global.battle_state = "calculate_turn"; 
         }
         break;

    case "calculate_turn": 
    {
        show_debug_message("Manager Step: calculate_turn");
        // --- Cleanup dead/destroyed Instances_FX --- 
        for (var i = ds_list_size(combatants_all) - 1; i >= 0; i--) { 
             var _inst_clean = combatants_all[| i];
             if (!instance_exists(_inst_clean)) { 
                  ds_list_delete(combatants_all, i); 
                  show_debug_message(" -> Removed destroyed instance from combatants_all list.");
             }
             // Check for units that died but haven't processed death animation yet (e.g. from DOT)
             else if (variable_instance_exists(_inst_clean,"data") && is_struct(_inst_clean.data) && variable_struct_exists(_inst_clean.data,"hp") && _inst_clean.data.hp <= 0) {
                  if(variable_instance_exists(_inst_clean,"combat_state") && _inst_clean.combat_state != "dying" && _inst_clean.combat_state != "dead") {
                      show_debug_message(" -> Found unprocessed dead combatant " + string(_inst_clean) + " during turn calc. Removing from active list temporarily.");
                       ds_list_delete(combatants_all, i); 
                  } else if (!variable_instance_exists(_inst_clean,"combat_state")) {
                       // No combat state, assume dead units shouldn't act
                       ds_list_delete(combatants_all, i); 
                  }
             }
        }
        
        // --- Check for immediate win/loss conditions ---
        var _party_alive = false; var _enemies_alive = false;
        if (ds_exists(global.battle_party, ds_type_list)) { for(var i=0; i<ds_list_size(global.battle_party); i++){var p=global.battle_party[|i]; if(instance_exists(p) && variable_instance_exists(p,"data") && is_struct(p.data) && p.data.hp > 0){_party_alive=true; break;}}}
        if (ds_exists(global.battle_enemies, ds_type_list)) { for(var i=0; i<ds_list_size(global.battle_enemies); i++){var e=global.battle_enemies[|i]; if(instance_exists(e) && variable_instance_exists(e,"data") && is_struct(e.data) && e.data.hp > 0){_enemies_alive=true; break;}}}
        if (!_enemies_alive && _party_alive) { global.battle_state = "victory"; alarm[0] = 1; break; }
        if (!_party_alive) { global.battle_state = "defeat"; alarm[0] = 1; break; }
        if (!_enemies_alive && !_party_alive) { global.battle_state = "defeat"; alarm[0] = 1; break; } 

    // --- Determine next actor via speed queue ---
    var turn_result = script_exists(scr_SpeedQueue)
                    ? scr_SpeedQueue(combatants_all, BASE_TICK_VALUE)
                    : { actor: noone, time_advance: 0 };
    currentActor = turn_result.actor;

    if (currentActor == noone) {
        show_debug_message(" -> No valid actor found. Checking win/loss.");
        global.battle_state = "check_win_loss";
        break;
    }

    // --- Check for BIND (skip turn) ---
    var status_info = script_exists(scr_GetStatus)
                    ? scr_GetStatus(currentActor)
                    : undefined;
    if (is_struct(status_info) && status_info.effect == "bind") {
        show_debug_message(" -> Actor " + string(currentActor)
                         + " is bound and skips their turn.");
        global.battle_state = "action_complete";
        break;
    }

    // --- Normal flow: Player vs Enemy ---
    if (currentActor.object_index == obj_battle_player) {
        show_debug_message(" -> Next Actor is Player: " + string(currentActor));
        stored_action_data     = undefined;
        selected_target_id     = noone;

        var idx = ds_list_find_index(global.battle_party, currentActor);
        if (idx == -1) {
            show_debug_message("ERROR: Player actor not in party list. Skipping turn.");
            global.battle_state = "action_complete";
        } else {
            global.active_party_member_index = idx;
            show_debug_message(" -> active_party_member_index = " + string(idx));
            global.battle_state = "player_input";
            show_debug_message(" -> battle_state = player_input");
        }
    } else {
        show_debug_message(" -> Next Actor is Enemy: " + string(currentActor));
        global.battle_state = "enemy_turn";
        show_debug_message(" -> battle_state = enemy_turn");
    }
}
break;

    case "player_input": case "skill_select": case "item_select":
        // Wait for player input (handled by obj_battle_player Step)
        if (instance_exists(currentActor)) { 
            if(variable_instance_exists(currentActor,"data") && currentActor.data.hp <= 0) { 
                show_debug_message(" -> Player actor KO'd while in input state. Skipping turn.");
                global.battle_state = "action_complete"; 
            }
        } else if (global.battle_state == "player_input") { 
             show_debug_message(" -> Actor missing during player input state. Recalculating turn.");
             currentActor = noone; global.battle_state = "calculate_turn";
        }
        break; 

    case "TargetSelect": 
    {
         show_debug_message("Manager Step: In TargetSelect State"); 
         if (!instance_exists(currentActor) || stored_action_data == undefined) { show_debug_message("TargetSelect: Actor/Action invalid."); global.battle_state = "calculate_turn"; break; }
         if (variable_instance_exists(currentActor,"data") && currentActor.data.hp <= 0) { show_debug_message("TargetSelect: Actor KO'd."); global.battle_state = "action_complete"; break; }
         if (!variable_global_exists("battle_enemies") || !ds_exists(global.battle_enemies, ds_type_list) || ds_list_empty(global.battle_enemies)) { show_debug_message("TargetSelect: No enemies."); global.battle_state = "player_input"; break; }
         var _enemy_count = ds_list_size(global.battle_enemies);

         var P = 0; 
         var _up = keyboard_check_pressed(vk_up) || gamepad_button_check_pressed(P, gp_padu);
         var _down = keyboard_check_pressed(vk_down) || gamepad_button_check_pressed(P, gp_padd);
         var _conf = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(P, gp_face1);
         var _cancel = keyboard_check_pressed(vk_escape)|| gamepad_button_check_pressed(P, gp_face2);
           
         if (_up) {show_debug_message(" -> TargetSelect: Input UP detected."); global.battle_target = (global.battle_target - 1 + _enemy_count) % _enemy_count; show_debug_message(" -> New Target Index: " + string(global.battle_target)); } 
         else if (_down) {show_debug_message(" -> TargetSelect: Input DOWN detected."); global.battle_target = (global.battle_target + 1) % _enemy_count; show_debug_message(" -> New Target Index: " + string(global.battle_target)); } 
         else if (_conf) {
             show_debug_message(" -> TargetSelect: Input CONFIRM detected.");
             show_debug_message(" -> Processing CONFIRM input..."); 
             if (global.battle_target >= 0 && global.battle_target < _enemy_count) {
                 show_debug_message("    -> Target index " + string(global.battle_target) + " is valid.");
                 var potential_target_id = ds_list_find_value(global.battle_enemies, global.battle_target); 
                 if (potential_target_id != undefined && instance_exists(potential_target_id)) {
                     selected_target_id = potential_target_id; 
                     show_debug_message("    -> Potential Target Instance ID: " + string(selected_target_id));
                     if (variable_instance_exists(selected_target_id, "data") && selected_target_id.data.hp > 0) { 
                         show_debug_message("    -> Target instance valid and alive. Setting state to ExecutingAction.");
                         global.battle_state = "ExecutingAction"; 
                     } else { show_debug_message("    -> Selected target instance invalid or dead (HP: " + string(selected_target_id.data.hp) + "). Resetting selection."); selected_target_id = noone; }
                 } else { show_debug_message("    -> ERROR: Failed to get valid instance from enemies list. Resetting selection."); selected_target_id = noone; }
             } else { show_debug_message(" -> ERROR: Invalid target index. Resetting selection."); selected_target_id = noone; global.battle_target = 0; }
         } else if (_cancel) {
              show_debug_message(" -> TargetSelect: Input CANCEL detected.");
              if (is_struct(stored_action_data) && variable_struct_exists(stored_action_data, "usable_in_battle") && script_exists(scr_AddInventoryItem)) { if (variable_struct_exists(stored_action_data, "item_key")) scr_AddInventoryItem(stored_action_data.item_key, 1); }
              var _prev = "player_input";
              if (is_struct(stored_action_data)) { if (variable_struct_exists(stored_action_data,"usable_in_battle")) _prev="item_select"; else if (variable_struct_exists(stored_action_data,"cost")) _prev="skill_select"; }
              // <<< NEW: consume this B press so it doesn’t immediately trigger Defend >>>
              global.battle_ignore_b = true;
              global.battle_state = _prev; 
              stored_action_data = undefined; selected_target_id = noone;
         }
    }
    break; // End TargetSelect
    
    // --- <<< ADDED STATE: TargetSelectAlly >>> ---
    case "TargetSelectAlly":
    {
         show_debug_message("Manager Step: In TargetSelectAlly State"); 
         // Validation
         if (!instance_exists(currentActor) || stored_action_data == undefined) { show_debug_message("TargetSelectAlly: Actor/Action invalid."); global.battle_state = "calculate_turn"; break; }
         if (variable_instance_exists(currentActor,"data") && currentActor.data.hp <= 0) { show_debug_message("TargetSelectAlly: Actor KO'd."); global.battle_state = "action_complete"; break; }
         if (!ds_exists(global.battle_party, ds_type_list) || ds_list_empty(global.battle_party)) { show_debug_message("TargetSelectAlly: Party list invalid."); global.battle_state = "player_input"; break; } 
        
         var _party_count = ds_list_size(global.battle_party);
         if (!variable_global_exists("battle_ally_target")) global.battle_ally_target = global.active_party_member_index ?? 0; 
         global.battle_ally_target = clamp(global.battle_ally_target, 0, max(0, _party_count - 1));

         var P = 0; 
         var _up = keyboard_check_pressed(vk_up) || gamepad_button_check_pressed(P, gp_padu);
         var _down = keyboard_check_pressed(vk_down) || gamepad_button_check_pressed(P, gp_padd);
         var _left = keyboard_check_pressed(vk_left)   || gamepad_button_check_pressed(P, gp_padl);
         var _right= keyboard_check_pressed(vk_right)  || gamepad_button_check_pressed(P, gp_padr);
         var _conf = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(P, gp_face1);
         var _cancel = keyboard_check_pressed(vk_escape)|| gamepad_button_check_pressed(P, gp_face2); 

         // Handle Cursor Movement (Ally List)
          if (_left || _right) {
            var _current_target_index = global.battle_ally_target; 
            var _new_target_index = _current_target_index;
            var _dir = _left ? -1 : 1;
            var _attempts = 0; 
            repeat(_party_count) { 
                _new_target_index = (_current_target_index + (_dir * (_attempts + 1)) + _party_count) mod _party_count; 
                 var _check_inst = global.battle_party[| _new_target_index];
                 var _can_target_this_ally = instance_exists(_check_inst); 
                 // Add Validation based on Action Type (Skill or Item)
                 if (_can_target_this_ally && is_struct(stored_action_data)) {
                     var effect_type = stored_action_data.effect ?? "";
                     var target_data = variable_instance_get(_check_inst,"data");
                     var target_hp = variable_struct_get(target_data,"hp") ?? -1;
                     
                     if (effect_type == "heal_hp" && target_hp <= 0) { _can_target_this_ally = false; } // Can't heal dead
                     // else if (effect_type == "revive" && target_hp > 0) { _can_target_this_ally = false; } // Can only revive dead
                     // Add more checks as needed
                 } else if (!_can_target_this_ally) { /* Instance doesn't exist */ }
                 
                 if (_can_target_this_ally) break; // Found valid target
                 _attempts++;
                 if (_attempts >= _party_count) { _new_target_index = _current_target_index; break;} 
            }
            global.battle_ally_target = _new_target_index; 
            show_debug_message(" -> TargetSelectAlly: Moved cursor to party index " + string(global.battle_ally_target));
         }
         // Handle Confirmation
         else if (_conf) {
            show_debug_message(" -> TargetSelectAlly: Input CONFIRM detected.");
            if (global.battle_ally_target >= 0 && global.battle_ally_target < _party_count) {
                var potential_target_id = ds_list_find_value(global.battle_party, global.battle_ally_target); 
                // Re-validate target before confirming
                 var _can_target_this_ally = instance_exists(potential_target_id);
                 if (_can_target_this_ally && is_struct(stored_action_data)) {
                     var effect_type = stored_action_data.effect ?? "";
                     var target_data = variable_instance_get(potential_target_id,"data");
                     var target_hp = variable_struct_get(target_data,"hp") ?? -1;
                     if (effect_type == "heal_hp" && target_hp <= 0) { _can_target_this_ally = false;}
                     // Add more validation
                 } else if (!_can_target_this_ally) { /* Invalid */ }

                if (_can_target_this_ally) { 
                    selected_target_id = potential_target_id; 
                    show_debug_message("    -> Ally target confirmed: " + string(selected_target_id) + ". Setting state to ExecutingAction.");
                    global.battle_state = "ExecutingAction"; 
                } else { show_debug_message("    -> Selected ally is not a valid target for this action."); /* Fail sound? */ }
            } else { show_debug_message("    -> Invalid ally target index."); selected_target_id = noone; }
         } 
         // Handle Cancellation
         else if (_cancel) { 
            show_debug_message(" -> TargetSelectAlly: Input CANCEL detected.");
            // --- Determine previous state ---
            var previous_state = "player_input"; // Default back to main menu
            if (is_struct(stored_action_data)) {
                if (variable_struct_exists(stored_action_data, "usable_in_battle")) { previous_state = "item_select"; }
                else if (variable_struct_exists(stored_action_data, "effect")) { previous_state = "skill_select"; }
            }
            global.battle_state = previous_state; 
            // --- End determine previous state ---
            stored_action_data = undefined; 
            selected_target_id = noone;
            show_debug_message("    -> Reset state to " + previous_state);
         }
    }
    break; // End TargetSelectAlly
    // --- <<< END ADDED STATE >>> ---

    // --- <<< REVISED ExecutingAction State >>> ---
    case "ExecutingAction": 
        show_debug_message("Manager: State ExecutingAction -> Actor: " + string(currentActor));
        if (instance_exists(currentActor)) {
             if (!variable_instance_exists(currentActor,"data") || currentActor.data.hp <= 0) { 
                 show_debug_message(" -> Actor KO'd before action execution.");
                 global.battle_state = "action_complete"; break; 
             } 

            var _action_data = stored_action_data; // Attack string, Defend string, Skill struct, Item struct
            var _target = selected_target_id;    // Target instance or noone
            var next_actor_state = "idle";     // Default state if action has no animation
            var _action_succeeded = false;       // Did the effect get applied (not missed/resisted etc)?
            
            // --- 1. Apply Effect / Check Usability / Deduct Cost ---
            if (is_string(_action_data)) { // Basic Attack or Defend
                 if (_action_data == "Attack") {
                      show_debug_message(" -> Executing: Basic Attack");
                      if (script_exists(scr_PerformAttack)) {
                           _action_succeeded = scr_PerformAttack(currentActor, _target); // Script handles damage/miss/popup
                           if (_action_succeeded) next_actor_state = "attack_start"; // Trigger attack animation
                      } else { show_debug_message("ERROR: scr_PerformAttack missing!");}
                 } else if (_action_data == "Defend") {
                      show_debug_message(" -> Executing: Defend");
                      if (variable_instance_exists(currentActor,"data")) currentActor.data.is_defending = true; 
                      _action_succeeded = true; // Defend always 'succeeds'
                      next_actor_state = "idle"; // No special animation state for defend? Or add "defend_start"?
                      global.battle_state = "action_complete"; // Defend is instant, skip animation wait
                      break; 
                 }
            } else if (is_struct(_action_data)) { // Skill or Item
                 if (variable_struct_exists(_action_data, "usable_in_battle")) { // ITEM
                     show_debug_message(" -> Executing: Item Use");
                     if (script_exists(scr_UseItem)) {
                          // Target for items often determined within the script or based on item.target
                          _action_succeeded = scr_UseItem(currentActor, _action_data, _target); // Script handles effect/popup
                          if (_action_succeeded) next_actor_state = "item_start"; // Trigger item animation
                     } else { show_debug_message("ERROR: scr_UseItem missing!");}
                 } 
                 else if (variable_struct_exists(_action_data, "effect")) { // SKILL
                     show_debug_message(" -> Executing: Skill Cast");
                     if (script_exists(scr_CastSkill)) {
                          // Target already determined by TargetSelect/TargetSelectAlly or set to self
                          _action_succeeded = scr_CastSkill(currentActor, _action_data, _target); // Script handles cost/effect/popup
                          if (_action_succeeded) { // Only animate if cast was successful (cost paid etc.)
                               var anim_type = variable_struct_get(_action_data, "animation_type") ?? "magic";
                               if (anim_type == "physical") { next_actor_state = "attack_start"; } // Physical skills use attack anim
                               else { next_actor_state = "cast_start"; } // Magic skills use cast anim
                          }
                     } else { show_debug_message("ERROR: scr_CastSkill missing!");}
                 }
            } else { show_debug_message(" -> ERROR: Unknown action type in ExecutingAction!"); }

            // --- 2. Trigger Actor's Animation State (if applicable) ---
            if (next_actor_state != "idle") {
                 show_debug_message(" -> Telling actor " + string(currentActor) + " to start state '" + next_actor_state + "'");
                 currentActor.stored_action_for_anim = _action_data; // Pass action data for visual reference
                 currentActor.target_for_attack = _target;         // Pass target for visual reference/FX positioning
                 currentActor.combat_state = next_actor_state; 
                 
                 current_attack_animation_complete = false; // Reset flag
                 global.battle_state = "waiting_for_animation"; 
                 show_debug_message(" -> Manager state set to waiting_for_animation.");
            } else if (global.battle_state != "action_complete") { // If we didn't already skip (like for Defend)
                 show_debug_message(" -> Action has no animation or failed. Proceeding to action_complete.");
                 global.battle_state = "action_complete"; // Skip waiting if no animation needed or action failed pre-animation
            }

        } else { // Actor doesn't exist
             show_debug_message("ERROR: currentActor invalid in ExecutingAction state!");
             global.battle_state = "calculate_turn"; 
        }
        break; // End ExecutingAction
    // --- <<< END REVISED ExecutingAction State >>> ---

    case "enemy_turn": // Initiates Enemy Action Animation
         show_debug_message(">>> MANAGER STATE: enemy_turn <<<"); // Log Entry
         show_debug_message("Manager: State enemy_turn -> Setting up Attack Animation for Actor: " + string(currentActor)); 
         
         // Check Actor Validity
         if (!instance_exists(currentActor) || !variable_instance_exists(currentActor,"data")) { 
              show_debug_message(" -> ERROR: Invalid enemy actor instance or missing data struct! Skipping turn."); 
              currentActor = noone; global.battle_state = "action_complete"; break; 
         }
         if (!variable_struct_exists(currentActor.data,"hp") || currentActor.data.hp <= 0) { 
              show_debug_message(" -> Enemy already KO'd (HP:" + string(currentActor.data.hp ?? "??") + "). Skipping turn.");
              global.battle_state = "action_complete"; break; 
         }
         
         // Choose Target
         show_debug_message(" -> Selecting target..."); 
         var _target = noone; var living_players = [];
         if(ds_exists(global.battle_party, ds_type_list)){ 
             var party_size = ds_list_size(global.battle_party);
             for(var k=0; k<party_size; k++){ var p=global.battle_party[|k]; if(instance_exists(p) && variable_instance_exists(p,"data") && is_struct(p.data) && variable_struct_exists(p.data,"hp") && p.data.hp > 0) { array_push(living_players,p); }}
         }
         if (array_length(living_players) > 0) { 
              _target = living_players[irandom(array_length(living_players)-1)]; 
              show_debug_message("    -> Enemy chose target: " + string(_target)); 
         } else { 
              show_debug_message(" -> Enemy has no valid player targets! Ending turn."); 
              global.battle_state = "action_complete"; break; 
         }

         // Get FX Info
         show_debug_message(" -> Getting FX info..."); 
         var fx_info = { sprite: spr_pow, sound: snd_punch, element: "physical" }; 
         if (variable_instance_exists(currentActor,"data") && is_struct(currentActor.data)){ 
             fx_info.sprite = currentActor.data.attack_sprite ?? spr_pow;
             fx_info.sound = currentActor.data.attack_sound ?? snd_punch;
             fx_info.element = currentActor.data.attack_element ?? "physical";
             if (!sprite_exists(fx_info.sprite)) { show_debug_message("WARN: Enemy attack sprite missing!"); fx_info.sprite = spr_pow; }
             if (!audio_exists(fx_info.sound)) { show_debug_message("WARN: Enemy attack sound missing!"); fx_info.sound = snd_punch; }
             show_debug_message("    -> Enemy FX Info: Sprite=" + sprite_get_name(fx_info.sprite) + ", Sound=" + string(fx_info.sound) + ", Element=" + fx_info.element); 
         } else {
             show_debug_message("    -> ERROR: Could not get FX info, enemy data struct missing!");
             global.battle_state = "action_complete"; break;
         }
         
         // Tell actor to start attacking
         if (instance_exists(currentActor) && instance_exists(_target)) {
              show_debug_message(" -> Telling enemy actor " + string(currentActor) + " to start combat_state 'attack_start' targeting " + string(_target) + "."); 
              currentActor.target_for_attack = _target;
              currentActor.attack_fx_sprite = fx_info.sprite;
              currentActor.attack_fx_sound = fx_info.sound;
              currentActor.combat_state = "attack_start"; 
              
              show_debug_message(" -> Setting manager state to 'waiting_for_animation'."); 
              global.battle_state = "waiting_for_animation"; 
              current_attack_animation_complete = false;
              show_debug_message(" -> Manager state is now: " + global.battle_state); 
         } else {
              show_debug_message(" -> ERROR: Enemy attacker or target became invalid before triggering animation! Skipping turn."); 
              global.battle_state = "action_complete"; 
         }
         
         break; // End enemy_turn
         
    case "waiting_for_animation": 
         // show_debug_message("Manager State: waiting_for_animation (Actor: " + string(currentActor) +")"); // Spammy
         if (current_attack_animation_complete) {
             show_debug_message("Manager: Animation complete signal received from Actor " + string(currentActor) ); 
             current_attack_animation_complete = false; 
             global.battle_state = "action_complete"; 
         }
         break;

    case "action_complete": 
    {
        show_debug_message("Manager Step: action_complete for Actor: " + string(currentActor)); 
        if (instance_exists(currentActor)) {
             if (variable_instance_exists(currentActor,"data") && is_struct(currentActor.data) && variable_struct_exists(currentActor.data,"is_defending") && currentActor.data.is_defending) { currentActor.data.is_defending = false; show_debug_message(" -> Resetting Defend status."); }
             if (script_exists(scr_ResetTurnCounter)) { scr_ResetTurnCounter(currentActor, BASE_TICK_VALUE); } 
        } else { show_debug_message(" -> Actor " + string(currentActor) + " no longer exists during action_complete."); }
        
        stored_action_data = undefined; selected_target_id = noone; 
        global.active_party_member_index = -1; 


        show_debug_message(" -> Transitioning from action_complete to check_win_loss"); 
        global.battle_state = "check_win_loss"; 
    }
    break; // End "action_complete"
            
    case "check_win_loss": 
    {
         show_debug_message("Manager Step: In check_win_loss State");
         
         // --- Check/remove dead enemies & accumulate XP ---
         if (ds_exists(global.battle_enemies, ds_type_list)) {
             for (var i = ds_list_size(global.battle_enemies) - 1; i >= 0; i--) {
                 var e_id = global.battle_enemies[| i];
                 
                 if (instance_exists(e_id)) {
                     // If this enemy is dead...
                     if (variable_instance_exists(e_id, "data")
                      && is_struct(e_id.data)
                      && variable_struct_exists(e_id.data, "hp")
                      && e_id.data.hp <= 0) {
                         
                         // 1) Accumulate its XP once
                         if (!variable_instance_exists(e_id, "xp_counted")) {
                             total_xp_from_battle += e_id.data.xp;
                             e_id.xp_counted = true;
                             show_debug_message(
                               " -> Accumulated " + string(e_id.data.xp) 
                               + " XP from " + string(e_id) 
                               + ". Total XP: " + string(total_xp_from_battle)
                             );
                         }
                         
                         // 2) Trigger its death processing if it's not mid‐death animation
                         if (!variable_instance_exists(e_id, "combat_state")
                          || (variable_instance_exists(e_id, "combat_state")
                              && e_id.combat_state != "dying")) {
                             if (script_exists(scr_ProcessDeathIfNecessary)) {
                                 scr_ProcessDeathIfNecessary(e_id);
                             }
                         }
                     }
                 }
                 else {
                     // Instance gone: remove from lists
                     ds_list_delete(global.battle_enemies, i);
                     var ci = ds_list_find_index(combatants_all, e_id);
                     if (ci != -1) ds_list_delete(combatants_all, ci);
                     show_debug_message(
                       " -> Removed missing enemy instance " 
                       + string(e_id) 
                       + " from battle_enemies."
                     );
                 }
             }
         }

         // --- (Party cleanup unchanged) ---
         var any_party_alive = false;
         if (ds_exists(global.battle_party, ds_type_list)) {
             for (var i = ds_list_size(global.battle_party) - 1; i >= 0; i--) {
                 var p_id = global.battle_party[| i];
                 if (instance_exists(p_id)
                  && variable_instance_exists(p_id, "data")
                  && is_struct(p_id.data)
                  && p_id.data.hp > 0) {
                     any_party_alive = true;
                     break;
                 }
             }
         }

         var any_enemies_alive = (ds_exists(global.battle_enemies, ds_type_list)
                                 && ds_list_size(global.battle_enemies) > 0);

         // Reset currentActor before deciding outcome
         currentActor = noone;

         // --- Determine Battle Outcome ---
         if (!any_enemies_alive && any_party_alive) {
             show_debug_message(" -> Outcome: Victory! Setting alarm.");
             global.battle_state = "victory";
             alarm[0] = 60;
         } else if (!any_party_alive) {
             show_debug_message(" -> Outcome: Defeat! Setting alarm.");
             global.battle_state = "defeat";
             alarm[0] = 60;
         } else {
             show_debug_message(" -> Outcome: Battle Continues.");
             // Clamp target index safely
             if (!any_enemies_alive) {
                 global.battle_target = -1;
             } else {
                 global.battle_target = clamp(global.battle_target, 0, ds_list_size(global.battle_enemies) - 1);
             }
             global.battle_state = "calculate_turn";
         }
         show_debug_message(" -> Exiting check_win_loss. Next state: " + global.battle_state);
    }
    break;
} // End Switch

// --- Screen Flash Logic --- 
if (screen_flash_timer > 0) { 
    screen_flash_timer -= 1;
    var fade_in_duration = max(1, floor(screen_flash_duration * 0.2)); 
    if (screen_flash_timer > screen_flash_duration - fade_in_duration) {
         var progress = 1 - ((screen_flash_timer - (screen_flash_duration - fade_in_duration)) / max(1, fade_in_duration)); 
         screen_flash_alpha = lerp(0, screen_flash_peak_alpha, progress);
    } else {
         screen_flash_alpha = max(0, screen_flash_alpha - screen_flash_fade_speed); 
    }
    screen_flash_alpha = clamp(screen_flash_alpha, 0, screen_flash_peak_alpha); 
} else { 
    screen_flash_alpha = max(0, screen_flash_alpha - screen_flash_fade_speed * 2); 
}

show_debug_message("--- End of obj_battle_manager Step Event --- (State: " + global.battle_state + ")"); // <<< ADDED THIS LINE