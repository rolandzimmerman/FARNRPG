/// obj_battle_player :: Step Event
/// Handles player input processing AND combat animation state machine.

// --- One-Time Sprite Assignment --- 
// Runs after the manager assigns 'data' in its Create event
if (!variable_instance_exists(id, "sprite_assigned") || !sprite_assigned) { 
    if (variable_instance_exists(id, "data") && is_struct(data)) { 
        if (variable_struct_exists(data, "character_key")) {
            var _char_key = data.character_key;
            show_debug_message("Attempting sprite assignment for key: " + _char_key);
            var base_char_info = script_exists(scr_FetchCharacterInfo) ? scr_FetchCharacterInfo(_char_key) : undefined; 
            
            if (is_struct(base_char_info)) {
                // Assign Battle Sprite (Idle/Base)
                if (variable_struct_exists(base_char_info, "battle_sprite") && sprite_exists(base_char_info.battle_sprite)) {
                   sprite_index = base_char_info.battle_sprite; 
                   idle_sprite = sprite_index; 
                } else { 
                   show_debug_message(" -> Warning: No valid 'battle_sprite' in base data for " + _char_key); 
                   idle_sprite = sprite_index; // Use whatever sprite it started with
                }
                sprite_before_attack = idle_sprite; // Initialize with idle sprite
                
                // Assign Attack Sprite
                if (variable_struct_exists(base_char_info, "attack_sprite") && sprite_exists(base_char_info.attack_sprite)) {
                   attack_sprite_asset = base_char_info.attack_sprite; 
                } else { 
                   show_debug_message(" -> Warning: No valid 'attack_sprite' in base data for " + _char_key + ". Using idle sprite as fallback."); 
                   attack_sprite_asset = idle_sprite; // Fallback to idle sprite
                }
                 
                // Assign Default Attack FX Sprite (can be overridden by weapon/skill)
                if (variable_struct_exists(base_char_info, "attack_fx_sprite") && sprite_exists(base_char_info.attack_fx_sprite)) {
                    attack_fx_sprite = base_char_info.attack_fx_sprite; 
                } else { 
                    attack_fx_sprite = spr_pow; // Default if not specified
                    show_debug_message(" -> Warning: No 'attack_fx_sprite' in base data for " + _char_key + ". Defaulting to spr_pow."); 
                }
                 
                // Assign Default Attack FX Sound (can be overridden by weapon/skill)
                if (variable_struct_exists(base_char_info, "attack_sound") && audio_exists(base_char_info.attack_sound)) {
                     attack_fx_sound = base_char_info.attack_sound;
                } else { 
                     attack_fx_sound = snd_punch; // Default if not specified
                     show_debug_message(" -> Warning: No 'attack_sound' in base data for " + _char_key + ". Defaulting to snd_punch."); 
                }

            } else { 
                show_debug_message(" -> Warning: scr_FetchCharacterInfo did not return valid struct for " + _char_key + ". Using defaults."); 
                idle_sprite = sprite_index; 
                attack_sprite_asset = idle_sprite; 
                attack_fx_sprite = spr_pow; 
                attack_fx_sound = snd_punch;
            }
            
            image_index = 0;
            image_speed = 0; // Start idle
            sprite_assigned = true; 
            show_debug_message("Player " + string(id) + " Sprites Initialized -> Idle: " + sprite_get_name(idle_sprite) + " | Attack: " + sprite_get_name(attack_sprite_asset) + " | Default FX: " + sprite_get_name(attack_fx_sprite));

        } else { show_debug_message(" -> Warning: No 'character_key' in player data for sprite assignment."); }
    } else { /* Data not assigned yet, wait for next step */ }
} // End !sprite_assigned check


// --- Player INPUT Handling (Only if it's my turn and in an input state) ---
if (variable_global_exists("active_party_member_index")
 && variable_global_exists("battle_state")
 && variable_instance_exists(id, "data") && is_struct(data)
 && variable_struct_exists(data, "party_slot_index") 
 && data.party_slot_index == global.active_party_member_index) // Is it my turn?
{
    var st = global.battle_state; // Get current manager state
    
    // Check if we are in a state where this player should process input
    if (st == "player_input" || st == "skill_select" || st == "item_select") {
        
        var d = data; // Shortcut to my data
        var P = 0; // Gamepad index
        // Read Inputs 
        var A = keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter) || gamepad_button_check_pressed(P, gp_face1); // Confirm
        var B = keyboard_check_pressed(vk_escape) || gamepad_button_check_pressed(P, gp_face2); // Cancel/Back
        var X = keyboard_check_pressed(ord("X"))   || gamepad_button_check_pressed(P, gp_face3); // Skill? (Maybe Xbox X / PS Square?)
        var Y = keyboard_check_pressed(ord("Y"))   || gamepad_button_check_pressed(P, gp_face4); // Item? (Maybe Xbox Y / PS Triangle?)
        var U = keyboard_check_pressed(vk_up)      || gamepad_button_check_pressed(P, gp_padu);   // Up
        var D = keyboard_check_pressed(vk_down)    || gamepad_button_check_pressed(P, gp_padd);   // Down
        // Left/Right inputs for party switching handled in equipment menu directly

        // Process based on Manager's State
        switch (st) {
            // ==================================================================
            case "player_input":
                var hasEnemies = ds_exists(global.battle_enemies, ds_type_list) && ds_list_size(global.battle_enemies) > 0;
                if (A && hasEnemies) { // Attack selected
                    if (!instance_exists(obj_battle_manager)) break; 
                    obj_battle_manager.stored_action_data = "Attack"; // Store action type
                    global.battle_target = 0; // Reset target cursor
                    global.battle_state  = "TargetSelect"; // Move to target selection
                    show_debug_message(" -> Action Selected: Attack -> TargetSelect");
                }
                else if (B) { // Defend selected
                     if (!instance_exists(obj_battle_manager)) break; 
                    obj_battle_manager.stored_action_data  = "Defend";
                    obj_battle_manager.selected_target_id  = noone; // Defend doesn't need a target
                    global.battle_state = "ExecutingAction"; // Go directly to execution
                    show_debug_message(" -> Action Selected: Defend -> ExecutingAction");
                }
                else if (X) { // Skills menu selected
                    var skills = (variable_struct_exists(d, "skills") && is_array(d.skills)) ? d.skills : [];
                    if (array_length(skills) > 0) {
                        if (!variable_struct_exists(d, "skill_index")) d.skill_index = 0; // Initialize index if needed
                        d.skill_index = clamp(d.skill_index, 0, max(0, array_length(skills) - 1)); // Ensure valid index
                        global.battle_state = "skill_select"; // Move to skill selection state
                         show_debug_message(" -> Action Selected: Skills -> skill_select");
                    } else { /* Play 'no skills' sound? */ show_debug_message(" -> Action Selected: Skills (No skills available)"); }
                }
                else if (Y) { // Items menu selected
                    global.battle_usable_items = []; // Reset usable item list
                    var inv = (variable_global_exists("party_inventory") && is_array(global.party_inventory)) ? global.party_inventory : [];
                    for (var i = 0; i < array_length(inv); i++) { 
                        var inv_entry = inv[i];
                        if (!is_struct(inv_entry) || !variable_struct_exists(inv_entry,"item_key") || !variable_struct_exists(inv_entry,"quantity") || inv_entry.quantity <= 0) continue;
                        var it_key = inv_entry.item_key;
                        var it_data = scr_GetItemData(it_key); // Assumes this script exists and returns item data
                        if (is_struct(it_data) && (it_data.usable_in_battle ?? false) ) { 
                             array_push(global.battle_usable_items, { item_key: it_key, quantity: inv_entry.quantity, name: it_data.name ?? "???" }); 
                        }
                    }
                    if (array_length(global.battle_usable_items) > 0) {
                         if (!variable_struct_exists(d, "item_index")) d.item_index = 0; // Initialize index if needed
                         d.item_index = clamp(d.item_index, 0, max(0, array_length(global.battle_usable_items) - 1)); // Ensure valid index
                         global.battle_state = "item_select"; // Move to item selection state
                         show_debug_message(" -> Action Selected: Items -> item_select");
                    } else { /* Play 'no items' sound? */ show_debug_message(" -> Action Selected: Items (No usable items available)"); }
                }
                break; // End "player_input" case
            // ==================================================================
            case "skill_select":
                 var skills = (variable_struct_exists(d, "skills") && is_array(d.skills)) ? d.skills : [];
                 var cnt = array_length(skills);
                 if (cnt > 0) {
                     // Navigation
                     if (U) d.skill_index = (d.skill_index - 1 + cnt) mod cnt;
                     if (D) d.skill_index = (d.skill_index + 1) mod cnt;
                     
                     // Confirm Selection
                     if (A) { 
                         var s = skills[d.skill_index]; // Get selected skill struct
                         var can_cast = false; // Default to false

                         // Check usability (MP or Overdrive)
                         if (variable_struct_exists(s, "overdrive") && s.overdrive == true) { 
                             if (variable_struct_exists(d, "overdrive") && variable_struct_exists(d, "overdrive_max")) {
                                 can_cast = (d.overdrive >= d.overdrive_max); 
                                 if (!can_cast) show_debug_message(" -> Cannot cast Overdrive skill: Not enough OD.");
                             } else { show_debug_message(" -> Cannot cast Overdrive skill: Player data missing OD variables."); }
                         } else { // Normal MP Skill
                             var cost = s.cost ?? 0;
                             if (variable_struct_exists(d, "mp")) {
                                 can_cast = (d.mp >= cost);
                                 if (!can_cast) show_debug_message(" -> Cannot cast skill: Not enough MP (Have " + string(d.mp) + ", Need " + string(cost) + ").");
                             } else { show_debug_message(" -> Cannot cast skill: Player data missing MP variable."); }
                         }

                         // Proceed if usable
                         if (can_cast && instance_exists(obj_battle_manager)) {
                             obj_battle_manager.stored_action_data = s; // Store chosen skill struct
                             // Cost deduction happens in scr_CastSkill now
                               
                             if (s.requires_target ?? true) { // Does skill need a target?
                                 global.battle_target = 0; 
                                 global.battle_state  = "TargetSelect"; 
                                 show_debug_message(" -> Skill Selected: " + (s.name ?? "???") + " -> TargetSelect");
                             } else { // Skill targets self or has no target
                                 obj_battle_manager.selected_target_id = id; 
                                 global.battle_state  = "ExecutingAction"; 
                                 show_debug_message(" -> Skill Selected: " + (s.name ?? "???") + " -> ExecutingAction");
                             }
                         } else if (!can_cast) { 
                              /* Play 'cannot use' sound? */ 
                              show_debug_message(" -> Failed usability check. Cannot cast.");
                         } 
                         
                     } // End Confirm (A)
                 } // End if cnt > 0
                 
                 // Cancel/Back
                 if (B) { global.battle_state = "player_input"; show_debug_message(" -> Cancelled Skill Select -> player_input"); }
                 
                 break; // End "skill_select" case
            // ==================================================================
            case "item_select":
                  var items = global.battle_usable_items ?? [];
                  var c = array_length(items);
                  if (c > 0) {
                      // Navigation
                      if (U) d.item_index = (d.item_index - 1 + c) mod c;
                      if (D) d.item_index = (d.item_index + 1) mod c;
                      
                      // Confirm Selection
                      if (A && instance_exists(obj_battle_manager)) { 
                          var item_info = items[d.item_index]; 
                          var item_data = scr_GetItemData(item_info.item_key); 
                          
                          if (is_struct(item_data)) {
                              // Consume item from inventory NOW
                              if (script_exists(scr_RemoveInventoryItem)) {
                                   if (!scr_RemoveInventoryItem(item_info.item_key, 1)) { 
                                        show_debug_message("ERROR: Failed to remove item " + item_info.item_key + " from inventory!");
                                        break; 
                                   }
                              } else { show_debug_message("ERROR: scr_RemoveInventoryItem missing!"); break; }

                              obj_battle_manager.stored_action_data = item_data; // Store item definition struct
                              
                              // Determine if target needed 
                              var need_tgt = true; // Assume needs target unless specified otherwise
                              if (variable_struct_exists(item_data,"target")) {
                                   if (item_data.target == "self" || item_data.target == "all_allies" || item_data.target == "all_enemies") {
                                       need_tgt = false;
                                   }
                              }
                               
                              if (need_tgt) {
                                  global.battle_target = 0; 
                                  global.battle_state  = "TargetSelect"; 
                                  show_debug_message(" -> Item Selected: " + (item_data.name ?? "???") + " -> TargetSelect");
                              } else {
                                  obj_battle_manager.selected_target_id = id; // Default target to self if not needed
                                  global.battle_state  = "ExecutingAction"; 
                                  show_debug_message(" -> Item Selected: " + (item_data.name ?? "???") + " -> ExecutingAction");
                              }
                          } else { show_debug_message("ERROR: Invalid item data for key: " + item_info.item_key); }
                      } // End Confirm (A)
                  } // End if c > 0
                  
                  // Cancel/Back
                  if (B) { global.battle_usable_items = []; global.battle_state = "player_input"; show_debug_message(" -> Cancelled Item Select -> player_input");} 
                  
                  break; // End "item_select" case
            // ==================================================================
        } // End input state switch
    } // End if correct state for input
} // End if my turn 


// --- Combat Animation State Machine (Runs always) ---
if (combat_state == "idle") { origin_x = x; origin_y = y; }

switch (combat_state) {
    case "idle":
        if (sprite_index != idle_sprite) { sprite_index = idle_sprite; image_index = 0; }
        if (image_speed != 0) image_speed = 0; 
        break;

    case "attack_start": 
        show_debug_message(object_get_name(object_index) + " " + string(id) + ": State -> attack_start, Target: " + string(target_for_attack));
        origin_x = x; origin_y = y; 
        
        // --- Sprite Change ---
        sprite_before_attack = idle_sprite; 
        if (sprite_exists(attack_sprite_asset)) { sprite_index = attack_sprite_asset; } 
        else { sprite_index = idle_sprite; } 
        image_index = 0; 
        image_speed = attack_anim_speed; // Use the adjustable speed
        show_debug_message(" -> Switched player sprite to attack: " + sprite_get_name(sprite_index) + " | Speed: " + string(image_speed));
        // --- End Sprite Change ---
        
        if (script_exists(scr_TriggerScreenFlash)) { scr_TriggerScreenFlash(15, 0.7); }

        // Calculate target position 
        var _target_x = origin_x; var _target_y = origin_y; 
        if (instance_exists(target_for_attack)) { _target_x = target_for_attack.x; _target_y = target_for_attack.y; }
        var _offset_dist = 192; var _dir_to_target = point_direction(x, y, _target_x, _target_y);
        var _move_to_x = _target_x - lengthdir_x(_offset_dist, _dir_to_target);
        var _move_to_y = _target_y - lengthdir_y(_offset_dist, _dir_to_target);
        
        // --- Teleport ---
        x = _move_to_x; y = _move_to_y; 
        show_debug_message(" -> Teleported to attack position"); 
        
        // --- Determine Attack Sound/FX Sprite ---
        var current_fx_sprite = attack_fx_sprite; 
        var current_fx_sound  = attack_fx_sound;  
        if (stored_action_for_anim == "Attack") { 
             if (script_exists(scr_GetWeaponAttackFX)) {
                 var weapon_fx = scr_GetWeaponAttackFX(id); 
                 if (sprite_exists(weapon_fx.sprite)) current_fx_sprite = weapon_fx.sprite;
                 if (audio_exists(weapon_fx.sound)) current_fx_sound = weapon_fx.sound;
             }
        } else if (is_struct(stored_action_for_anim)) { 
             if (variable_struct_exists(stored_action_for_anim, "fx_sprite") && sprite_exists(stored_action_for_anim.fx_sprite)) { current_fx_sprite = stored_action_for_anim.fx_sprite; }
             if (variable_struct_exists(stored_action_for_anim, "fx_sound") && audio_exists(stored_action_for_anim.fx_sound)) { current_fx_sound = stored_action_for_anim.fx_sound; }
        }
        show_debug_message(" -> Determined FX Sprite: " + sprite_get_name(current_fx_sprite) + " | Sound: " + string(current_fx_sound));

        // Play Sound
        if (audio_exists(current_fx_sound)) { audio_play_sound(current_fx_sound, 10, false); } 
        else { show_debug_message("Warning: Determined attack sound missing: " + string(current_fx_sound)); }

        // Apply Damage/Effect 
        var _action_succeeded = false; 
        if (stored_action_for_anim == "Attack") { if (script_exists(scr_PerformAttack)) _action_succeeded = scr_PerformAttack(id, target_for_attack); } 
        else if (is_struct(stored_action_for_anim)) {
             if (variable_struct_exists(stored_action_for_anim,"usable_in_battle")) { if (script_exists(scr_UseItem)) _action_succeeded = scr_UseItem(id, stored_action_for_anim, target_for_attack); } 
             else if (variable_struct_exists(stored_action_for_anim,"effect")) { if (script_exists(scr_CastSkill)) _action_succeeded = scr_CastSkill(id, stored_action_for_anim, target_for_attack); }
        }
        show_debug_message("    -> Action success flag: " + string(_action_succeeded));
        
        // --- Create Visual Effect ---
        if (_action_succeeded) { 
             if (object_exists(obj_attack_visual) && instance_exists(target_for_attack)) {
                 var _fx_x = target_for_attack.x; var _fx_y = target_for_attack.y - 32; 
                 var _layer_id = layer_get_id("Instances"); 
                 if (_layer_id != -1) { 
                     var fx = instance_create_layer(_fx_x, _fx_y, _layer_id, obj_attack_visual); 
                     if (instance_exists(fx)) {
                          // --- Set FX Sprite and Speed ---
                          fx.sprite_index = current_fx_sprite; 
                          fx.image_speed = attack_anim_speed;  // <<< Use player's attack anim speed for the FX
                          // --- End Set FX ---
                          fx.owner_instance = id; 
                          attack_animation_finished = false; 
                          show_debug_message(" -> Created obj_attack_visual with sprite: " + sprite_get_name(fx.sprite_index) + " | Speed: " + string(fx.image_speed)); 
                     } else { show_debug_message("ERROR: Failed to create obj_attack_visual!"); attack_animation_finished = true; } 
                 } else { show_debug_message("ERROR: Layer 'Instances' not found for obj_attack_visual!"); attack_animation_finished = true; } 
             } else { show_debug_message("Warning: obj_attack_visual missing or target invalid. Skipping visual."); attack_animation_finished = true; } 
        } else { attack_animation_finished = true; }

        combat_state = "attack_waiting"; 
        show_debug_message(" -> Set state to attack_waiting");
        break; 

    case "attack_waiting":
        if (attack_animation_finished) {
             show_debug_message(object_get_name(object_index) + " " + string(id) + ": Visual FX finished. State -> attack_return");
            combat_state = "attack_return"; 
            attack_animation_finished = false; 
        }
        break;

    case "attack_return":
        show_debug_message(object_get_name(object_index) + " " + string(id) + ": State -> attack_return");
        x = origin_x; y = origin_y; // Teleport Back
        
        // --- Restore Sprite ---
        if (sprite_exists(sprite_before_attack)) { sprite_index = sprite_before_attack; } 
        else { sprite_index = idle_sprite; } 
        image_index = 0; 
        image_speed = 0; // Stop animation
        show_debug_message(" -> Restored sprite to: " + sprite_get_name(sprite_index));
        
        // --- Signal Manager & Reset ---
        if (instance_exists(obj_battle_manager)) { obj_battle_manager.current_attack_animation_complete = true; }
        target_for_attack = noone; stored_action_for_anim = undefined; 
        combat_state = "idle"; 
        show_debug_message(" -> Returned to origin. State -> idle.");
        break; 
        
    case "dying": 
         image_alpha -= 0.05; 
         if (image_alpha <= 0) { 
              show_debug_message(object_get_name(object_index) + " " + string(id) + ": Player KO animation complete.");
              visible = false; 
              combat_state = "dead"; 
         }
         break;
        
     case "dead":
          visible = false; 
          image_speed = 0; 
          break;
        
} // End Switch