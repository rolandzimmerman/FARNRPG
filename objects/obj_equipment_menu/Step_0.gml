/// obj_equipment_menu :: Step Event
/// ---------------------------------------------------------------------------
/// Handle navigation, party switching, opening item list, equipping, and closing.
/// Uses shared global inventory: global.party_inventory
/// Reads input directly using keyboard/gamepad functions.

// --- Ensure State Enum Exists (Usually defined in a script run at game start) ---
// enum EEquipMenuState { BrowseSlots, SelectingItem }
// If not defined elsewhere, uncomment the above line or put it in a global script.

// Only run when this menu is active overall
// Ensure 'menu_active' is initialized in the Create Event (menu_active = true;)
if (!variable_instance_exists(id,"menu_active") || !menu_active) return;

// --- Initialize Instance Variables if they don't exist (Good practice) ---
if (!variable_instance_exists(id, "menu_state"))                  menu_state = EEquipMenuState.BrowseSlots;
if (!variable_instance_exists(id, "party_index"))                 party_index = 0; // Index in global.party_members
if (!variable_instance_exists(id, "equipment_character_key"))     equipment_character_key = (variable_global_exists("party_members") && is_array(global.party_members) && array_length(global.party_members) > 0) ? global.party_members[0] : "hero"; // Default
if (!variable_instance_exists(id, "equipment_data"))              equipment_data = scr_GetPlayerData(equipment_character_key); // Initial fetch
if (!variable_instance_exists(id, "selected_slot"))               selected_slot = 0; // Index for equipment_slots array
if (!variable_instance_exists(id, "equipment_slots"))             equipment_slots = [ "weapon", "offhand", "armor", "helm", "accessory" ];
if (!variable_instance_exists(id, "item_submenu_choices"))        item_submenu_choices = [];
if (!variable_instance_exists(id, "item_submenu_selected_index")) item_submenu_selected_index = 0;
if (!variable_instance_exists(id, "item_submenu_scroll_top"))     item_submenu_scroll_top = 0;
if (!variable_instance_exists(id, "item_submenu_display_count"))  item_submenu_display_count = 5; // How many items to show in list
if (!variable_instance_exists(id, "item_submenu_stat_diffs"))     item_submenu_stat_diffs = {};
if (!variable_instance_exists(id, "calling_menu"))                calling_menu = noone; // ID of the menu that opened this one (e.g., pause menu)


// — INPUT READING (Directly) —————————————————————————————————————————————
// Modify device index (0) if supporting multiple gamepads
var device = 0;
var up      = keyboard_check_pressed(vk_up)    || gamepad_button_check_pressed(device, gp_padu);
var down    = keyboard_check_pressed(vk_down)  || gamepad_button_check_pressed(device, gp_padd);
// Use shoulder buttons for party switching to avoid conflict with D-pad/stick for list nav
var left    = keyboard_check_pressed(vk_left)  || gamepad_button_check_pressed(device, gp_shoulderl);
var right   = keyboard_check_pressed(vk_right) || gamepad_button_check_pressed(device, gp_shoulderr);
// Confirm action
var confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(device, gp_face1); // Typically A button
// Back/Cancel action
var back    = keyboard_check_pressed(vk_escape)|| gamepad_button_check_pressed(device, gp_face2); // Typically B button


// --- State Machine Logic ————————————————————————————————————————————————
switch (menu_state) {

    // #########################################################################
    // ## STATE: Browse EQUIPMENT SLOTS                                     ##
    // #########################################################################
    case EEquipMenuState.BrowseSlots:
        // — SLOT NAVIGATION (Using Up/Down) —————————————————————————————————
        var slot_count = array_length(equipment_slots);
        if (up) {
            selected_slot = (selected_slot - 1 + slot_count) mod slot_count;
            // audio_play_sound(snd_menu_cursor, 1, false); // Optional sound
        }
        if (down) {
             selected_slot = (selected_slot + 1) mod slot_count;
             // audio_play_sound(snd_menu_cursor, 1, false); // Optional sound
         }

        // — PARTY SWITCHING (Using Left/Right) —————————————————————————————
        var party_count = (variable_global_exists("party_members") && is_array(global.party_members)) ? array_length(global.party_members) : 0;
        var party_changed = false;
        if (left  && party_count > 1) {
            party_index = (party_index - 1 + party_count) mod party_count;
            party_changed = true;
        }
        if (right && party_count > 1) {
            party_index = (party_index + 1) mod party_count;
            party_changed = true;
        }

        // If party changed, update the character key and fetch their data
        if (party_changed) {
            equipment_character_key = global.party_members[party_index];
            equipment_data = scr_GetPlayerData(equipment_character_key); // Refresh base data
             // Safety check after fetching new data
             if (!is_struct(equipment_data)) {
                 show_debug_message("ERROR: scr_GetPlayerData failed for '" + string(equipment_character_key) + "' on party switch. Closing menu.");
                 instance_destroy();
                 exit;
             }
             // audio_play_sound(snd_party_switch, 1, false); // Optional sound
             selected_slot = 0; // Reset slot selection to top when changing character
        }

        // — OPEN ITEM SELECTION SUBMENU (Using Confirm) —————————————————————
        if (confirm) {
            var _slotname = equipment_slots[selected_slot]; // Get name of the selected slot

            // 1) Get reference to persistent character data (_pers)
            //    (Needed to find the currently equipped item for comparison)
            var _pers;
            if (equipment_character_key == "hero" && instance_exists(obj_player)) {
                _pers = obj_player;
            } else {
                 if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) {
                      show_debug_message("ERROR: global.party_current_stats missing. Cannot open item list.");
                      break; // Exit switch case for this frame
                 }
                _pers = ds_map_find_value(global.party_current_stats, equipment_character_key);
                  if (!is_struct(_pers)) {
                      show_debug_message("ERROR: Persistent data for '" + equipment_character_key + "' not found. Cannot open item list.");
                       break; // Exit switch case for this frame
                  }
            }

            // 2) Build list of valid equippable items from GLOBAL inventory
            item_submenu_choices = [ noone ]; // Always start with 'Unequip' option

            var _inv_list = []; // Inventory list to iterate
            if (variable_global_exists("party_inventory") && is_array(global.party_inventory)) {
                _inv_list = global.party_inventory;
            } else {
                 show_debug_message("ERROR: global.party_inventory is missing or not an array!");
                 // Continue with only "Unequip" option
            }

            // Iterate through the global inventory
            for (var i = 0; i < array_length(_inv_list); i++) {
                var entry = _inv_list[i];
                // Check inventory entry validity
                if (!is_struct(entry) || !variable_struct_exists(entry, "item_key") || !variable_struct_exists(entry, "quantity") || entry.quantity <= 0) {
                     continue; // Skip malformed or zero-quantity entries
                }

                var _item_key   = entry.item_key;
                var _item_data  = scr_GetItemData(_item_key); // Fetch item definition

                // Check if item is defined, is equipment, and matches the selected slot
                if (is_struct(_item_data)
                 && variable_struct_exists(_item_data, "type") && _item_data.type == "equipment"
                 && variable_struct_exists(_item_data, "equip_slot") && _item_data.equip_slot == _slotname)
                {
                    array_push(item_submenu_choices, _item_key); // Add item key to choices
                }
            }
            // show_debug_message("Item Choices for slot '" + _slotname + "': " + string(item_submenu_choices));

            // 3) Find index of the currently equipped item in the generated list
            var _current_equipped_key = noone;
            // Safely check _pers.equipment structure and the specific slot
            if (variable_struct_exists(_pers, "equipment") && is_struct(_pers.equipment)) {
                 if (variable_struct_exists(_pers.equipment, _slotname)) {
                     _current_equipped_key = variable_struct_get(_pers.equipment, _slotname);
                 }
            }

            // Find the index of the current item key within the choices array
            item_submenu_selected_index = 0; // Default to first item ('noone')
            for (var j = 0; j < array_length(item_submenu_choices); j++) {
                if (item_submenu_choices[j] == _current_equipped_key) {
                    item_submenu_selected_index = j; // Select the current item
                    break;
                }
            }

            // 4) Calculate initial stat differences for the highlighted item
            var _potential_key_on_open = item_submenu_choices[item_submenu_selected_index];
            item_submenu_stat_diffs = scr_CalculateStatDifference(_current_equipped_key, _potential_key_on_open);

            // 5) Reset scroll position and change state to item selection
            item_submenu_scroll_top = 0;
             // Adjust scroll if the initially selected item is off the visible list
             if (item_submenu_selected_index >= item_submenu_display_count) {
                  item_submenu_scroll_top = item_submenu_selected_index - item_submenu_display_count + 1;
             }

            menu_state = EEquipMenuState.SelectingItem; // Change state!
            // audio_play_sound(snd_menu_select, 1, false); // Optional sound
        }

        // — CLOSE MENU (Using Back) ——————————————————————————————————————————
        if (back) {
            // Check if this menu was opened by another menu (e.g., obj_pause_menu)
            if (instance_exists(calling_menu)) {
                 // Reactivate the calling menu
                 instance_activate_object(calling_menu);
                 // If the calling menu uses an 'active' flag, set it
                 if (variable_instance_exists(calling_menu, "active")) {
                      calling_menu.active = true;
                 }
                 instance_destroy(); // Destroy this equipment menu
            } else {
                 // If not called by another menu, assume we exit back to the game
                 if (instance_exists(obj_game_manager)) {
                     // Make sure game state is set correctly (might depend on your game manager)
                     if (variable_instance_exists(obj_game_manager, "game_state")) {
                         obj_game_manager.game_state = "playing"; // Set game state to playing
                     }
                 }
                 instance_activate_all(); // Reactivate all game objects that might have been deactivated
                 instance_destroy(); // Destroy this equipment menu
            }
            exit; // Exit Step event processing for this frame
        }
        break; // End case EEquipMenuState.BrowseSlots


    // #########################################################################
    // ## STATE: SELECTING AN ITEM FROM THE LIST                              ##
    // #########################################################################
    case EEquipMenuState.SelectingItem:
         var _item_count = array_length(item_submenu_choices);
         var _current_key_equipped = noone; // Placeholder for currently equipped item

         // Get the persistent data reference again (needed for current item + equipping action)
         var _pers_equip;
         if (equipment_character_key == "hero" && instance_exists(obj_player)) {
             _pers_equip = obj_player;
         } else {
              // Assuming checks in BrowseSlots ensured these exist if we got here
              if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) {
                   show_debug_message("CRITICAL ERROR: global.party_current_stats missing in SelectingItem state!");
                   menu_state = EEquipMenuState.BrowseSlots; // Force back
                   break;
              }
              _pers_equip = ds_map_find_value(global.party_current_stats, equipment_character_key);
              // Add a check here just in case state is entered incorrectly
              if (!is_struct(_pers_equip)){
                   show_debug_message("CRITICAL ERROR: _pers_equip invalid in SelectingItem state for " + string(equipment_character_key) + "!");
                   menu_state = EEquipMenuState.BrowseSlots; // Force back to safety
                   break;
              }
         }

         // Get the currently equipped item key for the selected slot (for stat comparison)
         var _slotname_current = equipment_slots[selected_slot];
         if (variable_struct_exists(_pers_equip, "equipment") && is_struct(_pers_equip.equipment)) {
              if (variable_struct_exists(_pers_equip.equipment, _slotname_current)) {
                   _current_key_equipped = variable_struct_get(_pers_equip.equipment, _slotname_current);
               }
         }


        // — ITEM LIST NAVIGATION & SCROLLING (Using Up/Down) ————————————————
        // Note: Left/Right are ignored in this state
        var _index_changed = false;
        if (up) {
            item_submenu_selected_index = (item_submenu_selected_index - 1 + _item_count) mod _item_count;
            _index_changed = true;
             // Scroll up logic: If selection moves above the visible top, adjust scroll
             if (item_submenu_selected_index < item_submenu_scroll_top) {
                 item_submenu_scroll_top = item_submenu_selected_index;
             }
             // Handle wrapping around from top to bottom
             else if (item_submenu_selected_index == _item_count - 1 && item_submenu_scroll_top > 0 && _item_count > item_submenu_display_count) {
                  item_submenu_scroll_top = max(0, _item_count - item_submenu_display_count); // Scroll to show the bottom
             }
             // audio_play_sound(snd_menu_cursor, 1, false); // Optional sound
        }
         if (down) {
            item_submenu_selected_index = (item_submenu_selected_index + 1) mod _item_count;
            _index_changed = true;
            // Scroll down logic: If selection moves below visible bottom, adjust scroll
            if (item_submenu_selected_index >= item_submenu_scroll_top + item_submenu_display_count) {
                 item_submenu_scroll_top = item_submenu_selected_index - item_submenu_display_count + 1;
             }
             // Handle wrapping around from bottom to top
             else if (item_submenu_selected_index == 0 && item_submenu_scroll_top > 0 && _item_count > item_submenu_display_count) {
                 item_submenu_scroll_top = 0; // Scroll to the top
             }
             // audio_play_sound(snd_menu_cursor, 1, false); // Optional sound
        }

        // Ensure scroll_top is always valid (can't be negative or scroll past the last possible full view)
        item_submenu_scroll_top = max(0, min(item_submenu_scroll_top, max(0, _item_count - item_submenu_display_count)));


         // If the selected index changed, recalculate the stat differences
         if (_index_changed) {
             var _potential_key_new = item_submenu_choices[item_submenu_selected_index];
             // Compare potential new item against the one currently equipped in the slot
             item_submenu_stat_diffs = scr_CalculateStatDifference(_current_key_equipped, _potential_key_new);
         }


        // — EQUIP SELECTED ITEM (Using Confirm) ——————————————————————————————
        if (confirm) {
            var _slot_to_change = equipment_slots[selected_slot]; // Slot name string
            var _new_item_key = item_submenu_choices[item_submenu_selected_index]; // Key or noone

            // 1) Ensure the persistent character data has an 'equipment' struct
             if (!variable_struct_exists(_pers_equip, "equipment") || !is_struct(_pers_equip.equipment)) {
                  show_debug_message("Note: Creating 'equipment' struct for character '" + equipment_character_key + "' before equipping.");
                  // Create the default empty equipment struct if missing
                  _pers_equip.equipment = { weapon:noone, offhand:noone, armor:noone, helm:noone, accessory:noone };
             }

            // 2) Update the equipment slot in the persistent data structure
            //    (This directly modifies obj_player or the struct in global.party_current_stats)
            variable_struct_set(_pers_equip.equipment, _slot_to_change, _new_item_key);
            show_debug_message("Equipped '" + string(_new_item_key) + "' into slot '" + _slot_to_change + "' for '" + equipment_character_key + "'");

            // 3) Refresh the local equipment_data cache to reflect the change for drawing next frame
            //    scr_GetPlayerData fetches base stats and the *updated* equipment reference
            equipment_data = scr_GetPlayerData(equipment_character_key);
             if (!is_struct(equipment_data)) {
                  // This is unlikely if _pers_equip was valid, but check anyway
                  show_debug_message("ERROR: scr_GetPlayerData failed after equipping. Menu state might be inconsistent.");
             }

            // 4) Return to Browse slots state
            menu_state = EEquipMenuState.BrowseSlots;
            item_submenu_choices = []; // Clear the temporary list
            item_submenu_stat_diffs = {}; // Clear the temporary diffs
            // audio_play_sound(snd_equip_item, 1, false); // Optional equip sound
        }

        // — CANCEL ITEM SELECTION (Using Back) ———————————————————————————————
        // Return to the main equipment slot view without making changes
        if (back) {
            menu_state = EEquipMenuState.BrowseSlots; // Go back to the previous state
            item_submenu_choices = []; // Clear the temporary list
            item_submenu_stat_diffs = {}; // Clear the temporary diffs
            // audio_play_sound(snd_menu_cancel, 1, false); // Optional cancel sound
        }
        break; // End case EEquipMenuState.SelectingItem

} // End Switch (menu_state)