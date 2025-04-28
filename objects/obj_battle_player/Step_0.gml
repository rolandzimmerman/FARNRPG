/// obj_battle_player :: Step Event
// Handles player input processing AND combat animation state machine.

// --- HP Debug Log --- (Optional)
// if (variable_instance_exists(id, "data") && is_struct(data)) { show_debug_message("Player Step " + string(id) + ": Current HP = " + string(data.hp)); }

// --- One-Time Sprite Assignment --- 
if (!sprite_assigned && variable_instance_exists(id, "data") && is_struct(data)) { 
    if (variable_struct_exists(data, "character_key")) {
        var _char_key = data.character_key;
         show_debug_message("Attempting sprite assignment for key: " + _char_key);
         var base_char_info = script_exists(scr_FetchCharacterInfo) ? scr_FetchCharacterInfo(_char_key) : undefined; 
         if (is_struct(base_char_info)) {
             if (variable_struct_exists(base_char_info, "battle_sprite")) {
                var spr = base_char_info.battle_sprite;
                 if (sprite_exists(spr)) {
                    sprite_index = spr; image_index = 0; image_speed = 0.2; 
                    show_debug_message(" -> Assigned sprite: " + sprite_get_name(spr) + " to " + string(id)); 
                 } else { show_debug_message(" -> Warning: Battle sprite asset not found for index: " + string(spr)); }
             } else { show_debug_message(" -> Warning: No 'battle_sprite' field in data from scr_FetchCharacterInfo for " + _char_key); }
         } else { show_debug_message(" -> Warning: scr_FetchCharacterInfo did not return a struct for " + _char_key); }
    } else { show_debug_message(" -> Warning: No 'character_key' in player data for sprite assignment."); }
    sprite_assigned = true; 
}


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
        var X = keyboard_check_pressed(ord("X"))   || gamepad_button_check_pressed(P, gp_face3); // Skill?
        var Y = keyboard_check_pressed(ord("Y"))   || gamepad_button_check_pressed(P, gp_face4); // Item?
        var U = keyboard_check_pressed(vk_up)      || gamepad_button_check_pressed(P, gp_padu);   // Up
        var D = keyboard_check_pressed(vk_down)    || gamepad_button_check_pressed(P, gp_padd);   // Down

        // Process based on Manager's State
        switch (st) {
            case "player_input":
                var hasEnemies = ds_exists(global.battle_enemies, ds_type_list) && ds_list_size(global.battle_enemies) > 0;
                if (A && hasEnemies) { // Attack
                    if (!instance_exists(obj_battle_manager)) break; 
                    obj_battle_manager.stored_action_data = "Attack";
                    global.battle_target = 0; 
                    global.battle_state  = "TargetSelect"; 
                }
                else if (B) { // Defend
                     if (!instance_exists(obj_battle_manager)) break; 
                    obj_battle_manager.stored_action_data  = "Defend";
                    obj_battle_manager.selected_target_id  = noone; 
                    global.battle_state = "ExecutingAction"; 
                }
                else if (X) { // Skills
                    var skills = (variable_struct_exists(d, "skills") && is_array(d.skills)) ? d.skills : [];
                    if (array_length(skills) > 0) {
                        if (!variable_struct_exists(d, "skill_index")) d.skill_index = 0; 
                        d.skill_index = clamp(d.skill_index, 0, array_length(skills) - 1); 
                        global.battle_state = "skill_select"; 
                    } else { /* Play 'no skills' sound? */ }
                }
                else if (Y) { // Items
                    global.battle_usable_items = []; 
                    var inv = (variable_global_exists("party_inventory") && is_array(global.party_inventory)) ? global.party_inventory : [];
                    for (var i = 0; i < array_length(inv); i++) { 
                        var inv_entry = inv[i];
                        if (!is_struct(inv_entry) || !variable_struct_exists(inv_entry,"item_key") || !variable_struct_exists(inv_entry,"quantity") || inv_entry.quantity <= 0) continue;
                        var it_key = inv_entry.item_key;
                        var it_data = scr_GetItemData(it_key); 
                        if (is_struct(it_data) && (it_data.usable_in_battle ?? false) ) { 
                             array_push(global.battle_usable_items, { item_key: it_key, quantity: inv_entry.quantity, name: it_data.name ?? "???" }); 
                        }
                    }
                    if (array_length(global.battle_usable_items) > 0) {
                         if (!variable_struct_exists(d, "item_index")) d.item_index = 0; 
                         d.item_index = clamp(d.item_index, 0, array_length(global.battle_usable_items) - 1);
                         global.battle_state = "item_select"; 
                    } else { /* Play 'no items' sound? */ }
                }
                break; // End "player_input" case

            case "skill_select":
                 var skills = (variable_struct_exists(d, "skills") && is_array(d.skills)) ? d.skills : [];
                 var cnt = array_length(skills);
                 if (cnt > 0) {
                     // Navigation
                     if (U) d.skill_index = (d.skill_index - 1 + cnt) mod cnt;
                     if (D) d.skill_index = (d.skill_index + 1) mod cnt;
                     
                     // Confirm Selection
                     if (A) { 
                         var s = skills[d.skill_index];
                         var can_cast = false; // Default to false, prove usability

                         // Check if it's an Overdrive skill AND if player has enough OD
                         // <<< CORRECTED CHECK for s.overdrive >>>
                         if (variable_struct_exists(s, "overdrive") && s.overdrive == true) { 
                             if (variable_struct_exists(d, "overdrive") && variable_struct_exists(d, "overdrive_max")) {
                                 can_cast = (d.overdrive >= d.overdrive_max); 
                                 if (!can_cast) show_debug_message(" -> Cannot cast Overdrive skill: Not enough OD.");
                             } else { show_debug_message(" -> Cannot cast Overdrive skill: Player data missing OD variables."); }
                         } 
                         // Check MP cost for NON-Overdrive skills
                         else { 
                             var cost = s.cost ?? 0;
                             if (variable_struct_exists(d, "mp")) {
                                 can_cast = (d.mp >= cost);
                                 if (!can_cast) show_debug_message(" -> Cannot cast skill: Not enough MP (Have " + string(d.mp) + ", Need " + string(cost) + ").");
                             } else { show_debug_message(" -> Cannot cast skill: Player data missing MP variable."); }
                         }

                         // Proceed if usable
                         if (can_cast && instance_exists(obj_battle_manager)) {
                             obj_battle_manager.stored_action_data = s; // Store chosen skill struct
                             // MP/OD cost is deducted later by scr_CastSkill
                               
                             if (s.requires_target ?? true) { // Does skill need a target?
                                 global.battle_target = 0; // Reset enemy target index
                                 global.battle_state  = "TargetSelect"; // Go to target select
                             } else { // Skill targets self or has no target
                                 obj_battle_manager.selected_target_id = id; // Target is self
                                 global.battle_state  = "ExecutingAction"; // Go straight to execution/animation
                             }
                         } else if (!can_cast) { 
                              /* Play 'cannot use' sound? */ 
                              show_debug_message(" -> Failed usability check (MP/OD). Cannot cast.");
                         } 
                         // Implicit else: obj_battle_manager missing (shouldn't happen)
                         
                     } // End Confirm (A)
                 } // End if cnt > 0
                 
                 // Cancel/Back
                 if (B) global.battle_state = "player_input"; 
                 
                 break; // End "skill_select" case

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
                                        show_debug_message("ERROR: Failed to remove item " + item_info.item_key);
                                        break; // Stay in item menu if removal fails
                                   }
                              } else { show_debug_message("ERROR: scr_RemoveInventoryItem missing!"); break; }

                              obj_battle_manager.stored_action_data = item_data; 
                              
                              // Determine if target needed (simplified check)
                              var need_tgt = variable_struct_exists(item_data, "target") ? (item_data.target != "self" && item_data.target != "all_allies" && item_data.target != "all_enemies") : true;
                              if (need_tgt) {
                                  global.battle_target = 0; 
                                  global.battle_state  = "TargetSelect"; 
                              } else {
                                  obj_battle_manager.selected_target_id = id; 
                                  global.battle_state  = "ExecutingAction"; 
                              }
                          } // End if valid item_data
                      } // End Confirm (A)
                  } // End if c > 0
                  
                  // Cancel/Back
                  if (B) { global.battle_usable_items = []; global.battle_state = "player_input"; } 
                  
                  break; // End "item_select" case
                 
        } // End input state switch
    } // End if correct state for input
} // End if my turn 


// --- Combat Animation State Machine (Runs always) ---
if (combat_state == "idle") { origin_x = x; origin_y = y; }

switch (combat_state) {
    case "idle":
        break;

    case "attack_start": 
        show_debug_message(object_get_name(object_index) + " " + string(id) + ": State -> attack_start, Target: " + string(target_for_attack));
        origin_x = x; origin_y = y; 
        if (script_exists(scr_TriggerScreenFlash)) { scr_TriggerScreenFlash(15, 0.7); }
        // Calculate position near target
        var _target_x = origin_x; var _target_y = origin_y; 
        if (instance_exists(target_for_attack)) { _target_x = target_for_attack.x; _target_y = target_for_attack.y; }
        var _offset_dist = 40; var _dir_to_target = point_direction(x, y, _target_x, _target_y);
        var _move_to_x = _target_x - lengthdir_x(_offset_dist, _dir_to_target);
        var _move_to_y = _target_y - lengthdir_y(_offset_dist, _dir_to_target);
        show_debug_message(" -> Attacker Pos: (" + string(x) + "," + string(y) + ")");
        show_debug_message(" -> Target Exists. Target Pos: (" + string(_target_x) + "," + string(_target_y) + ")");
        show_debug_message(" -> Calculated Direction: " + string(_dir_to_target)); 
        show_debug_message(" -> Calculated MoveTo: (" + string(_move_to_x) + "," + string(_move_to_y) + ")"); 
        show_debug_message(" -> Attempting to set x/y..."); 
        x = _move_to_x; y = _move_to_y; 
        show_debug_message(" -> Set x/y successfully to: (" + string(x) + "," + string(y) + ")"); 
        if (audio_exists(attack_fx_sound)) { audio_play_sound(attack_fx_sound, 10, false); } 
        else { show_debug_message("Warning: Attack sound missing: " + string(attack_fx_sound)); }

        // Apply Damage/Effect based on stored action
        var _action_succeeded = false; 
        if (stored_action_for_anim == "Attack") {
             if (script_exists(scr_PerformAttack)) _action_succeeded = scr_PerformAttack(id, target_for_attack); 
        } else if (is_struct(stored_action_for_anim)) {
             if (variable_struct_exists(stored_action_for_anim,"usable_in_battle")) { // Item
                  // We assume scr_UseItem applies effects and returns true/false
                  if (script_exists(scr_UseItem)) _action_succeeded = scr_UseItem(id, stored_action_for_anim, target_for_attack); 
             } else if (variable_struct_exists(stored_action_for_anim,"effect")) { // Skill
                  // scr_CastSkill applies effects/damage and returns true if successful/miss, false if failed (no MP etc)
                  if (script_exists(scr_CastSkill)) _action_succeeded = scr_CastSkill(id, stored_action_for_anim, target_for_attack); 
             }
        }
        
        // Create Visual Effect
        // Show FX if action processing returned true (meaning it hit, missed, healed, applied status etc.)
        if (_action_succeeded) { 
             if (object_exists(obj_attack_visual) && instance_exists(target_for_attack)) {
                 var _fx_x = target_for_attack.x; var _fx_y = target_for_attack.y - 32; 
                 var _layer_id = layer_get_id("Instances"); 
                 if (_layer_id != -1) { 
                     var fx = instance_create_layer(_fx_x, _fx_y, _layer_id, obj_attack_visual); 
                     if (instance_exists(fx)) {
                          // Determine FX sprite based on action? Or just use attack_fx_sprite for all?
                          // For now, using attack_fx_sprite which was set based on weapon/defaults
                          if (sprite_exists(attack_fx_sprite)) { fx.sprite_index = attack_fx_sprite; } 
                          else { fx.sprite_index = spr_pow; } 
                          fx.owner_instance = id; 
                          attack_animation_finished = false; 
                          show_debug_message(" -> Created obj_attack_visual on layer: Instances"); 
                     } else { show_debug_message("ERROR: Failed to create obj_attack_visual!"); attack_animation_finished = true; }
                 } else { show_debug_message("ERROR: Layer 'Instances' not found for obj_attack_visual!"); attack_animation_finished = true; }
             } else { show_debug_message("Warning: obj_attack_visual missing or target invalid. Skipping visual."); attack_animation_finished = true; }
        } else {
             // Action failed entirely (e.g., no MP, invalid target before call) - skip visual/waiting immediately
             show_debug_message(" -> Skipping visual effect creation because action failed validation.");
             attack_animation_finished = true; 
        }

        combat_state = "attack_waiting";
        break; // End attack_start

    case "attack_waiting":
        if (attack_animation_finished) {
             show_debug_message(object_get_name(object_index) + " " + string(id) + ": State -> attack_return");
            combat_state = "attack_return";
            attack_animation_finished = false; 
        }
        break;

    case "attack_return":
        x = origin_x; y = origin_y;
        if (instance_exists(obj_battle_manager)) { obj_battle_manager.current_attack_animation_complete = true; }
        target_for_attack = noone; 
        stored_action_for_anim = undefined; 
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
          visible = false; break;
        
} // End Combat State Machine Switch