/// obj_equipment_menu :: Step Event
/// ---------------------------------------------------------------------------
/// Handle navigation, party switching, opening item list, equipping, and closing.

// Only run when this menu is active overall
if (!menu_active) return;

// — INPUT ———————————————————————————————————————————————————————————
var up      = keyboard_check_pressed(vk_up)    || gamepad_button_check_pressed(0, gp_padu);
var down    = keyboard_check_pressed(vk_down)  || gamepad_button_check_pressed(0, gp_padd);
var left    = keyboard_check_pressed(vk_left)  || gamepad_button_check_pressed(0, gp_shoulderl); // Use shoulder for party swap
var right   = keyboard_check_pressed(vk_right) || gamepad_button_check_pressed(0, gp_shoulderr); // Use shoulder for party swap
var confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(0, gp_face1); // A button
var back    = keyboard_check_pressed(vk_escape)|| gamepad_button_check_pressed(0, gp_face2); // B button

// --- State Machine Logic ---
switch (menu_state) {

    // == STATE: Browse EQUIPMENT SLOTS ==
    case EEquipMenuState.BrowseSlots:
        // — SLOT NAVIGATION —————————————————————————————————————————————————
        var slot_count = array_length(equipment_slots);
        if (down) selected_slot = (selected_slot + 1) mod slot_count;
        if (up)   selected_slot = (selected_slot - 1 + slot_count) mod slot_count;

        // — PARTY SWITCHING ———————————————————————————————————————————————
        var party_count = array_length(global.party_members);
        var party_changed = false;
        if (left  && party_count > 1) {
            party_index = (party_index - 1 + party_count) mod party_count;
            party_changed = true;
        }
        if (right && party_count > 1) {
            party_index = (party_index + 1) mod party_count;
            party_changed = true;
        }
        if (party_changed) {
            equipment_character_key = global.party_members[party_index];
            equipment_data = scr_GetPlayerData(equipment_character_key); // Refresh base data for the new character
            // Add safety check for equipment_data validity again
             if (!is_struct(equipment_data)) {
                 show_debug_message("ERROR: scr_GetPlayerData returned invalid data for '" + string(equipment_character_key) + "' on party switch. Closing menu.");
                 instance_destroy(); // Or handle error differently
                 exit;
             }
        }

        // — OPEN ITEM SELECTION SUBMENU —————————————————————————————————————
        if (confirm) {
            var _slotname = equipment_slots[selected_slot];

            // 1) Get persistent‐stats struct for this character
            var _pers;
            if (equipment_character_key == "hero" && instance_exists(obj_player)) {
                _pers = obj_player;
            } else {
                // Make sure the global map exists
                 if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) {
                     show_debug_message("ERROR: global.party_current_stats missing or invalid type in Equipment Menu Step.");
                     // Handle this error - maybe close the menu or create the map?
                     // For now, let's assume it exists or was created by scr_GetPlayerData
                     // If scr_GetPlayerData ensures it exists, this check might be redundant here.
                     global.party_current_stats = ds_map_create(); // Safety creation
                 }
                _pers = ds_map_find_value(global.party_current_stats, equipment_character_key);
                 // Need to handle the case where _pers is NOT a struct (e.g., character not initialized yet)
                 if (!is_struct(_pers)) {
                      show_debug_message("ERROR: Persistent data for '" + equipment_character_key + "' not found or not a struct. Cannot open item list.");
                      // Maybe play an error sound
                      break; // Don't proceed with opening the list
                 }
            }

            // 2) Build list of valid gear from inventory
            item_submenu_choices = [ noone ]; // Start with 'Unequip' option
            var _inv_list = [];
            // Check persistent struct *first*, then fallback to player obj if needed (though _pers should handle this)
             if (variable_struct_exists(_pers, "inventory") && is_array(_pers.inventory)) {
                 _inv_list = _pers.inventory;
             } else if (equipment_character_key == "hero" && instance_exists(obj_player) && variable_instance_exists(obj_player, "inventory") && is_array(obj_player.inventory)) {
                 // Fallback specifically for hero/player object if not found via _pers map
                 _inv_list = obj_player.inventory;
                 show_debug_message("Note: Using obj_player.inventory directly for hero's item list.");
             } else {
                  show_debug_message("WARNING: No inventory found for '" + equipment_character_key + "'. Item list will only contain 'Unequip'.");
             }


            for (var i = 0; i < array_length(_inv_list); i++) {
                var entry = _inv_list[i];
                // Ensure entry is a struct and has item_key
                if (!is_struct(entry) || !variable_struct_exists(entry, "item_key")) continue;

                var key   = entry.item_key;
                var data  = scr_GetItemData(key); // Assumes scr_GetItemData handles invalid keys gracefully

                // Check if item data is valid and is equippable in the selected slot
                if (is_struct(data)
                 && variable_struct_exists(data, "type") && data.type == "equipment" // Make sure it's equipment
                 && variable_struct_exists(data, "equip_slot")
                 && data.equip_slot == _slotname)
                {
                    array_push(item_submenu_choices, key);
                }
            }

            // 3) Find currently equipped item's index in the new list
            var _current_key = noone;
            // Ensure equipment struct/map exists before accessing
            if (variable_struct_exists(equipment_data, "equipment") && is_struct(equipment_data.equipment)) {
                 if (variable_struct_exists(equipment_data.equipment, _slotname)) {
                     _current_key = variable_struct_get(equipment_data.equipment, _slotname);
                 }
            // Optional: Add check for old ds_map format if still possible
            //} else if (variable_struct_exists(equipment_data, "equipment") && ds_exists(equipment_data.equipment, ds_type_map)) {
            //    if (ds_map_exists(equipment_data.equipment, _slotname)) {
            //       _current_key = ds_map_find_value(equipment_data.equipment, _slotname);
            //    }
            }

            item_submenu_selected_index = 0; // Default to first item (usually 'noone')
            for (var j = 0; j < array_length(item_submenu_choices); j++) {
                if (item_submenu_choices[j] == _current_key) {
                    item_submenu_selected_index = j;
                    break;
                }
            }

            // 4) Calculate initial stat diffs for the highlighted item
            var _potential_key = item_submenu_choices[item_submenu_selected_index];
            item_submenu_stat_diffs = scr_CalculateStatDifference(_current_key, _potential_key);

            // 5) Reset scroll and change state
            item_submenu_scroll_top = 0;
            // Adjust scroll if starting selection is off-screen
            if (item_submenu_selected_index >= item_submenu_display_count) {
                 item_submenu_scroll_top = item_submenu_selected_index - item_submenu_display_count + 1;
            }

            menu_state = EEquipMenuState.SelectingItem;
            // Play confirm sound (optional)
            // audio_play_sound(snd_menu_select, 1, false);
        }

        // — CLOSE & RESUME GAME / RETURN TO PAUSE MENU ————————————————————————
        if (back) {
            // Check if we were called by another menu (like obj_pause_menu)
            if (instance_exists(calling_menu)) {
                 // Reactivate the calling menu and destroy this one
                 instance_activate_object(calling_menu);
                 if (variable_instance_exists(calling_menu, "active")) {
                      calling_menu.active = true; // Assuming the calling menu uses an 'active' flag
                 }
                 instance_destroy();
            } else {
                 // If not called by another menu, assume we exit back to game
                 if (instance_exists(obj_game_manager)) {
                     obj_game_manager.game_state = "playing";
                 }
                 instance_activate_all(); // Reactivate game objects
                 // If the pause menu STILL exists somehow (shouldn't if we weren't called by it), destroy it.
                 // This is a safety net.
                 with (obj_pause_menu) { instance_destroy(); }
                 instance_destroy(); // Destroy self (equipment menu)
            }
            exit; // Exit Step event
        }
        break; // End BrowseSlots state


    // == STATE: SELECTING AN ITEM FROM THE LIST ==
    case EEquipMenuState.SelectingItem:
         var _item_count = array_length(item_submenu_choices);

        // — ITEM LIST NAVIGATION —————————————————————————————————————————————
        var _index_changed = false;
         if (down) {
            item_submenu_selected_index = (item_submenu_selected_index + 1) mod _item_count;
            _index_changed = true;
            // Scroll down logic
            if (item_submenu_selected_index < item_submenu_scroll_top) { // Wrapped around to top
                 item_submenu_scroll_top = item_submenu_selected_index;
             } else if (item_submenu_selected_index >= item_submenu_scroll_top + item_submenu_display_count) {
                 item_submenu_scroll_top = item_submenu_selected_index - item_submenu_display_count + 1;
             }
         }
        if (up) {
            item_submenu_selected_index = (item_submenu_selected_index - 1 + _item_count) mod _item_count;
             _index_changed = true;
             // Scroll up logic
             if (item_submenu_selected_index >= item_submenu_scroll_top + item_submenu_display_count) { // Wrapped around to bottom
                 item_submenu_scroll_top = item_submenu_selected_index - item_submenu_display_count + 1;
             } else if (item_submenu_selected_index < item_submenu_scroll_top) {
                 item_submenu_scroll_top = item_submenu_selected_index;
             }
        }

        // Ensure scroll_top doesn't go invalid if list is small
         item_submenu_scroll_top = max(0, min(item_submenu_scroll_top, _item_count - item_submenu_display_count));


         // Recalculate stat differences if selection changed
         if (_index_changed) {
             var _slotname_current = equipment_slots[selected_slot];
             var _current_key_equipped = noone;
             // Get the actually equipped item key again for comparison
             if (variable_struct_exists(equipment_data, "equipment") && is_struct(equipment_data.equipment)) {
                 if (variable_struct_exists(equipment_data.equipment, _slotname_current)) {
                     _current_key_equipped = variable_struct_get(equipment_data.equipment, _slotname_current);
                 }
             }
             var _potential_key_new = item_submenu_choices[item_submenu_selected_index];
             item_submenu_stat_diffs = scr_CalculateStatDifference(_current_key_equipped, _potential_key_new);
             // Play cursor sound (optional)
             // audio_play_sound(snd_menu_cursor, 1, false);
         }


        // — EQUIP SELECTED ITEM ———————————————————————————————————————————————
        if (confirm) {
            var _slot_to_change = equipment_slots[selected_slot];
            var _new_item_key = item_submenu_choices[item_submenu_selected_index];

            // 1) Get persistent‐stats struct for this character
            var _pers_equip;
            if (equipment_character_key == "hero" && instance_exists(obj_player)) {
                _pers_equip = obj_player;
            } else {
                 // Ensure global map exists
                 if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) {
                      show_debug_message("ERROR: global.party_current_stats missing. Cannot equip item.");
                      // Play error sound, return to Browse
                      menu_state = EEquipMenuState.BrowseSlots;
                      break;
                 }
                _pers_equip = ds_map_find_value(global.party_current_stats, equipment_character_key);
                 // Ensure the character data exists in the map
                  if (!is_struct(_pers_equip)) {
                      show_debug_message("ERROR: Persistent data for '" + equipment_character_key + "' not found. Cannot equip item.");
                       menu_state = EEquipMenuState.BrowseSlots;
                       break;
                  }
            }

             // 2) Ensure the persistent struct has an 'equipment' struct
             if (!variable_struct_exists(_pers_equip, "equipment") || !is_struct(_pers_equip.equipment)) {
                  show_debug_message("Note: Creating 'equipment' struct for character '" + equipment_character_key + "'.");
                  _pers_equip.equipment = {
                       weapon: noone, offhand: noone, armor: noone, helm: noone, accessory: noone
                   };
             }


            // 3) Update the persistent equipment data
            // Note: This directly modifies obj_player.equipment or the struct in global.party_current_stats
            variable_struct_set(_pers_equip.equipment, _slot_to_change, _new_item_key);
            show_debug_message("Equipped '" + string(_new_item_key) + "' into slot '" + _slot_to_change + "' for '" + equipment_character_key + "'");

            // 4) Refresh the local equipment_data struct to reflect the change for drawing *next frame*
            // scr_GetPlayerData fetches the base stats and the *updated* equipment reference
            equipment_data = scr_GetPlayerData(equipment_character_key);
             if (!is_struct(equipment_data)) {
                  show_debug_message("ERROR: scr_GetPlayerData failed after equipping. Menu state might be inconsistent.");
                  // Decide how to handle - maybe force close? For now, just log.
             }


            // 5) Return to Browse slots state
            menu_state = EEquipMenuState.BrowseSlots;
            item_submenu_choices = []; // Clear the list
            item_submenu_stat_diffs = {}; // Clear diffs
            // Play equip sound (optional)
            // audio_play_sound(snd_equip_item, 1, false);

        }

        // — CANCEL ITEM SELECTION (Return to Slot Browse) ————————————————————
        if (back) {
            menu_state = EEquipMenuState.BrowseSlots;
            item_submenu_choices = []; // Clear the list
            item_submenu_stat_diffs = {}; // Clear diffs
            // Play cancel sound (optional)
            // audio_play_sound(snd_menu_cancel, 1, false);
        }
        break; // End SelectingItem state

} // End Switch