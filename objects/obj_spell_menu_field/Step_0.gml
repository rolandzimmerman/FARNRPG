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
        var party_list_keys = variable_global_exists("party_members") ? global.party_members : [];
        var party_count = array_length(party_list_keys);
        
        if (party_count > 0) {
             // Navigation (Left/Right)
             if (left) { character_index = (character_index - 1 + party_count) mod party_count; }
             if (right) { character_index = (character_index + 1) mod party_count; }
             
             // Confirmation
             if (confirm) {
                  selected_caster_key = party_list_keys[character_index];
                  show_debug_message("Spell Menu Field: Confirmed caster '" + selected_caster_key + "'");
                  
                  // --- <<< ADDED Detailed Logging for Spell List Population >>> ---
                  usable_spells = []; 
                  spell_index = 0;    
                  
                  show_debug_message("  -> Attempting to populate usable spells...");
                  if (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) { // Check map exists
                       show_debug_message("    -> global.party_current_stats map exists.");
                       if (ds_map_exists(global.party_current_stats, selected_caster_key)) { // Check key exists
                           show_debug_message("    -> Found key '" + selected_caster_key + "' in map.");
                           var caster_data = ds_map_find_value(global.party_current_stats, selected_caster_key); // Get data
                           
                           if (is_struct(caster_data)) { // Check if data is a struct
                               show_debug_message("    -> Retrieved caster_data is a struct.");
                               if (variable_struct_exists(caster_data, "skills")) { // Check if struct has 'skills'
                                   show_debug_message("    -> 'skills' key exists in caster_data.");
                                   if (is_array(caster_data.skills)) { // Check if 'skills' is an array
                                       var all_skills = caster_data.skills;
                                       var all_skills_len = array_length(all_skills);
                                       show_debug_message("    -> 'skills' is an array. Length: " + string(all_skills_len)); // <<< CHECK THIS LENGTH
                                       
                                       // Loop through the character's skills array
                                       for (var i = 0; i < all_skills_len; i++) {
                                            var skill_struct = all_skills[i];
                                            if (!is_struct(skill_struct)) {
                                                 show_debug_message("      -> Item at index " + string(i) + " is not a struct. Skipping.");
                                                 continue;
                                            }
                                            
                                            var skill_name = variable_struct_get(skill_struct, "name") ?? "???";
                                            // Check for the usable_in_field flag SAFELY
                                            var field_usable = variable_struct_get(skill_struct, "usable_in_field") ?? false;
                                            show_debug_message("      -> Checking skill[" + string(i) + "]: '" + skill_name + "'. usable_in_field = " + string(field_usable)); // <<< CHECK THIS VALUE FOR HEAL
                                            
                                            if (field_usable == true) { // Explicitly check for true
                                                array_push(usable_spells, skill_struct); 
                                                show_debug_message("          -> Added to usable_spells list.");
                                            }
                                       }
                                   } else { show_debug_message("    -> ERROR: 'skills' field is NOT an array!"); }
                               } else { show_debug_message("    -> ERROR: 'skills' key missing from caster_data struct!"); }
                           } else { show_debug_message("    -> ERROR: Data retrieved for key is NOT a struct!"); }
                       } else { show_debug_message("    -> ERROR: Key '" + selected_caster_key + "' NOT FOUND in global.party_current_stats map!"); }
                  } else { show_debug_message("    -> ERROR: global.party_current_stats map DOES NOT EXIST or is invalid!"); }
                  
                  // Final check on populated list
                  if (array_length(usable_spells) == 0) {
                       show_debug_message("  -> FINAL: No field-usable spells found for " + selected_caster_key + ".");
                       spell_index = -1; 
                  } else {
                       spell_index = 0; 
                       show_debug_message("  -> FINAL: Populated usable_spells list. Count: " + string(array_length(usable_spells)));
                  }
                  // --- <<< END LOGGING >>> ---
                  
                  menu_state = "spell_select"; // Move to next state
                  show_debug_message(" -> Transitioning to spell_select state.");
             }
        } 
         
        // Handle Back/Cancel - Return to Pause Menu
        if (back) {
            // (Your existing cancel logic to return to pause menu - uses instance_activate_all)
            show_debug_message("Spell Menu Field Char Select: Back pressed. Returning to calling menu.");
            if (instance_exists(calling_menu)) { instance_activate_all(); if(variable_instance_exists(calling_menu, "active")) { calling_menu.active = true; } } 
            else { if(instance_exists(obj_game_manager)) obj_game_manager.game_state = "playing"; instance_activate_all(); }
            instance_destroy(); exit; 
        }
        break; // End character_select state
        
    case "spell_select":
        // (Existing navigation and placeholder confirm logic)
        var spell_count = array_length(usable_spells);
        if (spell_count > 0) { 
            if (up) { spell_index = (spell_index - 1 + spell_count) mod spell_count; }
            if (down) { spell_index = (spell_index + 1) mod spell_count; }
            if (confirm) { show_debug_message("Spell Menu Field: Confirmed spell selection (Index: " + string(spell_index) + "). Functionality WIP."); }
        } else { if (confirm) { /* Fail sound? */ } }
        if (back) { menu_state = "character_select"; usable_spells = []; spell_index = 0; selected_caster_key = ""; }
        break; // End spell_select state
        
    case "target_select_ally":
         // (Existing placeholder logic)
         if (back) { menu_state = "spell_select"; }
         break; // End target_select_ally state
}