/// obj_battle_enemy :: Step Event (Example Parent)
// Handles combat animation state machine.

// Update origin AND original scale while idle
if (combat_state == "idle") {
    origin_x = x;
    origin_y = y;
    // <<< MODIFICATION: Store original scale reliably >>>
    // Check if variable exists first time, otherwise just update
    if (!variable_instance_exists(id,"original_scale")) { 
         original_scale = image_xscale; 
    } else {
         original_scale = image_xscale; 
    }
    // Also ensure scale IS original if we enter idle state
    if (image_xscale != original_scale) {
        image_xscale = original_scale;
        image_yscale = original_scale; // Assuming uniform scale
    }
    // <<< END MODIFICATION >>>
}

// --- Combat Animation State Machine ---
switch (combat_state) {
    case "idle":
        // Wait for the battle manager to set state to "attack_start"
        // Ensure animation stopped
         if (image_speed != 0) image_speed = 0; 
        break;

    case "attack_start": 
        show_debug_message(object_get_name(object_index) + " " + string(id) + ": State -> attack_start, Target: " + string(target_for_attack)); 
        origin_x = x; origin_y = y; 
        // Store original scale again just in case it wasn't set in idle (e.g., first frame)
        if (!variable_instance_exists(id,"original_scale")) original_scale = image_xscale; 

        // (Optional: Trigger screen flash)
        // if (script_exists(scr_TriggerScreenFlash)) { scr_TriggerScreenFlash(15, 0.7); }

        // Calculate position near target
        var _target_x = origin_x; var _target_y = origin_y; 
        var target_exists = instance_exists(target_for_attack); 
        if (target_exists) { _target_x = target_for_attack.x; _target_y = target_for_attack.y; } 
        var _offset_dist = 192; 
        var _dir_to_target = point_direction(x, y, _target_x, _target_y);
        var _move_to_x = _target_x - lengthdir_x(_offset_dist, _dir_to_target); 
        var _move_to_y = _target_y - lengthdir_y(_offset_dist, _dir_to_target); 
        
        // <<< MODIFICATION: Match Target Scale Safely >>>
        if (target_exists) {
             // Read target scale safely, default to 1 if variables missing
             var _target_scale_x = variable_instance_get(target_for_attack, "image_xscale") ?? 1; 
             var _target_scale_y = variable_instance_get(target_for_attack, "image_yscale") ?? 1; 
             image_xscale = _target_scale_x;
             image_yscale = _target_scale_y;
             show_debug_message("    -> Matched enemy scale to target scale: " + string(image_xscale));
        }
        // <<< END MODIFICATION >>>

        // Apply teleport
        x = _move_to_x; 
        y = _move_to_y; 
        
        // Play Sound (Use sound determined by manager/AI)
         var _sound_to_play = variable_instance_get(id,"current_attack_fx_sound") ?? snd_punch; // Get sound set by manager
        if (audio_exists(_sound_to_play)) { audio_play_sound(_sound_to_play, 10, false); } 
        else { show_debug_message(" -> Warning: Enemy attack sound missing: " + string(_sound_to_play)); }

        // Apply Damage & Effects (using AI script)
        var _action_succeeded = false; 
        if (script_exists(scr_EnemyAttackRandom)) { 
             // Assuming scr_EnemyAttackRandom USES the target already set in this instance (target_for_attack)
             _action_succeeded = scr_EnemyAttackRandom(id); 
        } else { _action_succeeded = false; }
        
        // Create Visual Effect
        if (_action_succeeded && instance_exists(target_for_attack)) { 
             if (object_exists(obj_attack_visual)) {
                var _fx_x = target_for_attack.x; var _fx_y = target_for_attack.y - 32; 
                // --- Create FX back on "Instances" Layer ---
                var _layer_id = layer_get_id("Instances"); 

                if (_layer_id != -1) { 
                    var fx = instance_create_layer(_fx_x, _fx_y, _layer_id, obj_attack_visual); 
                    if (instance_exists(fx)) {
                         var _sprite_to_use = variable_instance_get(id,"current_attack_fx_sprite") ?? spr_pow; 
                         if (sprite_exists(_sprite_to_use)) { fx.sprite_index = _sprite_to_use; } 
                         else { fx.sprite_index = spr_pow; } 
                         
                         // --- <<< MODIFICATION: Set FX Depth relative to TARGET >>> ---
                         // This ensures the effect draws over the instance being hit
                         fx.depth = target_for_attack.depth - 1; 
                         fx.image_speed = 1; // Ensure FX animates
                         show_debug_message("    -> Set FX ("+string(fx)+") depth: " + string(fx.depth) + " (Target depth was: " + string(target_for_attack.depth) + ")");
                         // --- <<< END MODIFICATION >>> ---

                         fx.owner_instance = id; 
                         attack_animation_finished = false; 
                    } else { attack_animation_finished = true; }
                } else { attack_animation_finished = true; show_debug_message("ERROR: Could not find Instances layer for FX!");}
             } else { attack_animation_finished = true; }
        } else { attack_animation_finished = true; }

        combat_state = "attack_waiting";
        break; 

    case "attack_waiting":
        if (attack_animation_finished) { combat_state = "attack_return"; attack_animation_finished = false; }
        break;

    case "attack_return":
        show_debug_message("ENEMY_STEP: " + string(id) + ": State attack_return."); 
        x = origin_x; y = origin_y; // Teleport back
        var _scale_to_restore = variable_instance_get(id, "original_scale") ?? 1.0; // Restore scale
        image_xscale = _scale_to_restore; image_yscale = _scale_to_restore; 
        show_debug_message(" -> Restored enemy scale to: " + string(image_xscale));
        if (instance_exists(obj_battle_manager)) { obj_battle_manager.current_attack_animation_complete = true; }
        target_for_attack = noone; 
        combat_state = "idle"; 
        break;
        
     case "dying": 
        image_alpha -= 0.05; 
        if (image_alpha <= 0) { instance_destroy(); }
        break;
        
      case "dead":
           break; 
           
} // End Switch