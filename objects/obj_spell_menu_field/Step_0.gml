/// @description Handle navigation and actions for field spell menu

if (!active) return; 

// --- Input ---
var device = 0;
var left    = keyboard_check_pressed(vk_left)  || gamepad_button_check_pressed(device, gp_padl);
var right   = keyboard_check_pressed(vk_right) || gamepad_button_check_pressed(device, gp_padr);
var up      = keyboard_check_pressed(vk_up)    || gamepad_button_check_pressed(device, gp_padu);
var down    = keyboard_check_pressed(vk_down)  || gamepad_button_check_pressed(device, gp_padd);
var confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(device, gp_face1);
var back    = keyboard_check_pressed(vk_escape)|| gamepad_button_check_pressed(device, gp_face2);

// --- State Machine ---
switch (menu_state) {
    case "character_select":
        // (This is your working character selection logic from before)
        var party_list_keys = variable_global_exists("party_members") ? global.party_members : [];
        var party_count = array_length(party_list_keys);
        if (party_count > 0) {
             if (left) { character_index = (character_index - 1 + party_count) mod party_count; /* Sound? */ }
             if (right) { character_index = (character_index + 1) mod party_count; /* Sound? */ }
             if (confirm) { 
                  selected_caster_key = party_list_keys[character_index];
                  show_debug_message("Spell Menu Field: Confirmed caster '" + selected_caster_key + "'");
                  // Populate usable spells 
                  usable_spells = []; spell_index = 0;    
                  if (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) { 
                       if (ds_map_exists(global.party_current_stats, selected_caster_key)) { 
                           var caster_data = ds_map_find_value(global.party_current_stats, selected_caster_key); 
                           if (is_struct(caster_data) && variable_struct_exists(caster_data, "skills") && is_array(caster_data.skills)) { 
                               var all_skills = caster_data.skills;
                               for (var i = 0; i < array_length(all_skills); i++) {
                                    var skill_struct = all_skills[i];
                                    if (is_struct(skill_struct) && (variable_struct_get(skill_struct, "usable_in_field") ?? false)) {
                                        array_push(usable_spells, skill_struct); 
                                    }
                               }
                           } 
                       } 
                  } 
                  if (array_length(usable_spells) == 0) { spell_index = -1; show_debug_message("  -> FINAL: No field-usable spells found."); } 
                  else { spell_index = 0; show_debug_message("  -> FINAL: Populated usable_spells list. Count: " + string(array_length(usable_spells))); }
                  menu_state = "spell_select"; 
                  show_debug_message(" -> Transitioning to spell_select state.");
             }
        } 
        // Cancel logic
        if (back) { if (instance_exists(calling_menu)) { instance_activate_all(); if(variable_instance_exists(calling_menu, "active")) { calling_menu.active = true; } } else { /* Unpause */ } instance_destroy(); exit; }
        break; 
        
    case "spell_select":
        var spell_count = array_length(usable_spells);
        if (spell_count > 0) { 
            // Navigation
            if (up) { spell_index = (spell_index - 1 + spell_count) mod spell_count; /* Sound? */ }
            if (down) { spell_index = (spell_index + 1) mod spell_count; /* Sound? */ }
            
            // --- <<< ADDED Spell Confirmation Logic >>> ---
            if (confirm && spell_index != -1) { 
                var selected_spell = usable_spells[spell_index];
                show_debug_message("Spell Menu Field: Confirmed spell '" + (selected_spell.name ?? "???") + "'");

                // Check MP Cost 
                var cost = selected_spell.cost ?? 0;
                var caster_data = ds_map_find_value(global.party_current_stats, selected_caster_key); 
                var current_mp = variable_struct_get(caster_data, "mp") ?? 0;
                
                if (current_mp >= cost) { 
                    show_debug_message("  -> MP Check OK (Have " + string(current_mp) + ", Need " + string(cost) + ")");
                    var targetType = variable_struct_get(selected_spell, "target_type") ?? "enemy"; 
                    
                    if (targetType == "ally" || targetType == "self") {
                         target_party_index = (targetType == "self") ? character_index : 0; 
                         menu_state = "target_select_ally"; 
                         show_debug_message("  -> Transitioning to target_select_ally state.");
                    } 
                    else if (targetType == "all_allies") {
                         show_debug_message("  -> Applying '" + selected_spell.name + "' to all allies... (Effect application WIP)");
                         // Placeholder: Needs call to updated scr_CastSkillField in loop + MP deduction
                         menu_state = "spell_select"; // Stay here for now
                    } 
                    else { show_debug_message("  -> Cannot use this spell target type ('" + targetType + "') outside battle."); /* Fail Sound? */ }
                } else { show_debug_message("  -> MP Check FAILED (Have " + string(current_mp) + ", Need " + string(cost) + ")"); /* Fail Sound? */ }
            } // End Confirm
            // --- <<< END ADDED Logic >>> ---

        } else { if (confirm) { /* Fail sound? */ } }

        // Handle Back/Cancel - Return to Character Select
        if (back) {
             show_debug_message("Spell Menu Field Spell Select: Back pressed. Returning to character select.");
             menu_state = "character_select";
             usable_spells = []; spell_index = 0; selected_caster_key = "";
             // audio_play_sound(snd_cancel, 0, false);
        }
        break; // End spell_select state
        
    // --- <<< ADDED Target Selection Logic >>> ---
    case "target_select_ally":
         var party_list_keys = global.party_members ?? [];
         var party_count = array_length(party_list_keys);
         if (party_count == 0) { menu_state = "spell_select"; break; } // Go back if no party
         target_party_index = clamp(target_party_index, 0, max(0, party_count - 1)); 

         // Navigation (Using Up/Down)
         if (up) { target_party_index = (target_party_index - 1 + party_count) mod party_count; /* Add skip invalid target logic? */ /* Play Sound? */ }
         if (down) { target_party_index = (target_party_index + 1) mod party_count; /* Add skip invalid target logic? */ /* Play Sound? */ }
         
         // Confirmation - Attempt to Cast Spell
         if (confirm) {
             var target_key = party_list_keys[target_party_index];
             // Ensure spell_index is valid (check against usable_spells array)
             if (spell_index < 0 || spell_index >= array_length(usable_spells)) {
                  show_debug_message("ERROR: Invalid spell_index in target_select_ally confirm!");
                  menu_state = "spell_select"; break; // Go back if error
             }
             var selected_spell = usable_spells[spell_index]; 
             var caster_data = ds_map_find_value(global.party_current_stats, selected_caster_key); 
             var target_data_struct = ds_map_find_value(global.party_current_stats, target_key); 
             
             show_debug_message("Spell Menu Field Target: Confirmed target key '" + target_key + "' for spell '" + (selected_spell.name ?? "???") + "'");
             
             var can_use_on_target = true; 
             // Validate Target based on persistent data
             if (!is_struct(target_data_struct)) { can_use_on_target = false; show_debug_message("   -> ERROR: Target persistent data invalid."); } 
             else {
                 var target_hp = variable_struct_get(target_data_struct, "hp") ?? 0;
                 if (selected_spell.effect == "heal_hp" && target_hp <= 0) { can_use_on_target = false; show_debug_message("   -> Cannot use Heal on KO'd target."); }
                 // Add other checks (Revive, etc.)
             }

             // Attempt to Cast Spell using scr_CastSkillField if Target Valid
             if (can_use_on_target && script_exists(scr_CastSkillField)) {
                 show_debug_message("   -> Attempting to call scr_CastSkillField (CasterKey=" + selected_caster_key + ", TargetKey=" + target_key + ")");
                 var cast_success = scr_CastSkillField(selected_caster_key, selected_spell, target_key); 
                 show_debug_message("   -> scr_CastSkillField returned: " + string(cast_success));
                 
                 if (cast_success) { 
                    // --- <<< ADDED: Play Heal Sound >>> ---
                     // Check if the successfully cast spell was a healing spell
                     if (selected_spell.effect == "heal_hp") { 
                          if (audio_exists(snd_sfx_heal)) { // Make sure sound exists
                              audio_play_sound(snd_sfx_heal, 10, false); 
                              show_debug_message("   -> Played heal sound (snd_sfx_heal).");
                          } else { show_debug_message("   -> WARNING: snd_sfx_heal asset missing!"); }
                     } 
                     // Add else if for other spell sounds here based on selected_spell.effect if needed
                     // --- <<< END ADDED SOUND >>> ---
                     // Deduct MP from persistent data upon success
                     var cost = selected_spell.cost ?? 0;
                     if (is_struct(caster_data)) { 
                          caster_data.mp = max(0, caster_data.mp - cost); 
                          ds_map_replace(global.party_current_stats, selected_caster_key, caster_data); // Save change back to map
                          show_debug_message("   -> Deducted MP. Caster MP now: " + string(caster_data.mp));
                          // Play success sound?
                     } else { show_debug_message("   -> ERROR: Could not find caster data to deduct MP!"); }
                 } else { show_debug_message("   -> Spell use failed (check logs from scr_CastSkillField)."); /* Play fail sound? */ }
             } else if (!can_use_on_target) { /* Fail message already shown, play fail sound? */ }
             else { show_debug_message("   -> ERROR: scr_CastSkillField script missing!"); }

             // Return to spell selection after attempt
             menu_state = "spell_select";
             show_debug_message("   -> Returning to spell_select state.");
             
         } // End Confirm
         
         // Handle Cancellation
         if (back) {
              show_debug_message("Spell Menu Field Target: Back pressed. Returning to spell select.");
              menu_state = "spell_select";
              // audio_play_sound(snd_cancel, 0, false);
         }
         break; // End target_select_ally state
     // --- <<< END ADDED Logic >>> ---
}