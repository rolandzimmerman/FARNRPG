/// obj_battle_enemy :: Step Event (Example Parent)
// Handles combat animation state machine.

// Update origin while idle
if (combat_state == "idle") {
     origin_x = x;
     origin_y = y;
}

// --- Combat Animation State Machine ---
switch (combat_state) {
    case "idle":
        // Wait for the battle manager to set state to "attack_start"
        break;

    case "attack_start": 
        show_debug_message(object_get_name(object_index) + " " + string(id) + ": State -> attack_start, Target: " + string(target_for_attack)); 
        origin_x = x; origin_y = y; 

        show_debug_message("ENEMY_STEP: " + string(id) + ": Log 2 - Triggering Screen Flash..."); 
        if (script_exists(scr_TriggerScreenFlash)) { scr_TriggerScreenFlash(15, 0.7); }

        // Calculate position near target
        show_debug_message("ENEMY_STEP: " + string(id) + ": Log 3 - Calculating position..."); 
        var _target_x = origin_x; var _target_y = origin_y; 
        if (instance_exists(target_for_attack)) { _target_x = target_for_attack.x; _target_y = target_for_attack.y; } else { show_debug_message(" -> WARN: Target invalid during position calc!") }
        var _offset_dist = 40; 
        var _dir_to_target = point_direction(x, y, _target_x, _target_y);
        var _move_to_x = _target_x - lengthdir_x(_offset_dist, _dir_to_target); 
        var _move_to_y = _target_y - lengthdir_y(_offset_dist, _dir_to_target); 
        show_debug_message("ENEMY_STEP: " + string(id) + ": Log 4 - Calculated MoveTo: (" + string(_move_to_x) + "," + string(_move_to_y) + ")"); 
        
        // Apply teleport
        show_debug_message("ENEMY_STEP: " + string(id) + ": Log 5 - Applying position..."); 
        x = _move_to_x; 
        y = _move_to_y; 
        show_debug_message("ENEMY_STEP: " + string(id) + ": Log 6 - Applied position successfully."); 

        // Play Sound
        show_debug_message("ENEMY_STEP: " + string(id) + ": Log 7 - Playing sound: " + string(attack_fx_sound)); 
        if (audio_exists(attack_fx_sound)) { audio_play_sound(attack_fx_sound, 10, false); } 
        else { show_debug_message(" -> Warning: Enemy attack sound missing: " + string(attack_fx_sound)); }

        // Apply Damage & Effects by calling the integrated enemy AI script
        show_debug_message("ENEMY_STEP: " + string(id) + ": Log 8 - Applying Damage/Effects via scr_EnemyAttackRandom..."); 
        var _action_succeeded = false; 
        // ======================= FIX IS HERE =======================
        // Call the script that contains the AI, target selection, and damage logic
        if (script_exists(scr_EnemyAttackRandom)) { 
             show_debug_message(" -> Calling scr_EnemyAttackRandom..."); // Log before calling
             // scr_EnemyAttackRandom handles everything including target selection and damage application
             _action_succeeded = scr_EnemyAttackRandom(id); // Pass self ID
             show_debug_message(" -> Called scr_EnemyAttackRandom. Result: " + string(_action_succeeded)); // Log after calling
        } else { 
            show_debug_message(" -> ERROR: scr_EnemyAttackRandom missing! Cannot perform enemy action."); 
             _action_succeeded = false; // Mark as failed if script missing
        }
        // ===========================================================
        show_debug_message("ENEMY_STEP: " + string(id) + ": Log 10 - Damage/Effect application attempt complete. Succeeded: " + string(_action_succeeded)); 
        
        // Create Visual Effect
        show_debug_message("ENEMY_STEP: " + string(id) + ": Log 11 - Creating Visual Effect..."); 
        if (_action_succeeded) { // Create FX even on miss (where script returns true)
             if (object_exists(obj_attack_visual) && instance_exists(target_for_attack)) { // Still need target_for_attack for FX position
                 var _fx_x = target_for_attack.x; var _fx_y = target_for_attack.y - 32; 
                 var _layer_id = layer_get_id("Instances"); 
                 if (_layer_id != -1) { 
                     show_debug_message("   -> Attempting instance_create_layer for obj_attack_visual..."); 
                     var fx = instance_create_layer(_fx_x, _fx_y, _layer_id, obj_attack_visual); 
                     if (instance_exists(fx)) {
                          show_debug_message("   -> obj_attack_visual Instance ID: " + string(fx)); 
                          if (sprite_exists(attack_fx_sprite)) { fx.sprite_index = attack_fx_sprite; } 
                          else { fx.sprite_index = spr_pow; } 
                          fx.owner_instance = id; 
                          attack_animation_finished = false; 
                          show_debug_message("   -> Created obj_attack_visual successfully on layer: Instances"); // Log 12
                     } else { show_debug_message("   -> ERROR: Failed to create obj_attack_visual!"); attack_animation_finished = true; }
                 } else { show_debug_message("   -> ERROR: Layer 'Instances' not found for obj_attack_visual!"); attack_animation_finished = true; }
             } else { show_debug_message("   -> Warning: obj_attack_visual missing or target invalid. Skipping visual."); attack_animation_finished = true; }
        } else { 
             show_debug_message(" -> Skipping visual effect creation because action failed before starting.");
             attack_animation_finished = true; 
        }

        show_debug_message("ENEMY_STEP: " + string(id) + ": Log 13 - Setting combat_state to attack_waiting."); 
        combat_state = "attack_waiting";
        break; // End attack_start

    case "attack_waiting":
        // show_debug_message("ENEMY_STEP: " + string(id) + ": State attack_waiting. Flag: " + string(attack_animation_finished)); // Spammy
        if (attack_animation_finished) {
             show_debug_message("ENEMY_STEP: " + string(id) + ": Animation finished flag detected. State -> attack_return");
            combat_state = "attack_return";
            attack_animation_finished = false; 
        }
        break;

    case "attack_return":
        show_debug_message("ENEMY_STEP: " + string(id) + ": State attack_return. Moving to origin."); // Log 14
        x = origin_x; y = origin_y;
        if (instance_exists(obj_battle_manager)) { 
             show_debug_message(" -> Signalling manager animation complete."); // Log 15
             obj_battle_manager.current_attack_animation_complete = true; 
        }
        target_for_attack = noone; 
        show_debug_message(" -> Setting state to idle."); // Log 16
        combat_state = "idle"; 
        break;
        
     case "dying": 
        image_alpha -= 0.05; 
        if (image_alpha <= 0) {
             show_debug_message(object_get_name(object_index) + " " + string(id) + ": Death animation complete. Destroying instance.");
             instance_destroy(); 
        }
        break;
     
} // End Combat State Machine Switch