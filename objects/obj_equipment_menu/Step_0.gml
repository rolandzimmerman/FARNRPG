/// obj_equipment_menu :: Step Event
/// ---------------------------------------------------------------------------
/// Handle navigation, party switching, opening item list, equipping, and closing.
/// Assumes persistent data is ALWAYS in global.party_current_stats map.

// --- Ensure State Enum Exists ---
// enum EEquipMenuState { BrowseSlots, SelectingItem }

// Only run when this menu is active overall
if (!variable_instance_exists(id,"menu_active") || !menu_active) return;

// --- Initialize Instance Variables if they somehow don't exist ---
// ... (Initialization checks remain the same) ...
if (!variable_instance_exists(id, "menu_state"))                  menu_state = EEquipMenuState.BrowseSlots;
// ... etc ...

// — INPUT READING (Directly) —————————————————————————————————————————————
// ... (Input reading remains the same) ...
var device = 0;
var up      = keyboard_check_pressed(vk_up)    || gamepad_button_check_pressed(device, gp_padu);
var down    = keyboard_check_pressed(vk_down)  || gamepad_button_check_pressed(device, gp_padd);
var left    = keyboard_check_pressed(vk_left)  || gamepad_button_check_pressed(device, gp_shoulderl);
var right   = keyboard_check_pressed(vk_right) || gamepad_button_check_pressed(device, gp_shoulderr);
var confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(device, gp_face1);
var back    = keyboard_check_pressed(vk_escape)|| gamepad_button_check_pressed(device, gp_face2);

// --- State Machine Logic ————————————————————————————————————————————————
switch (menu_state) {

    // #########################################################################
    // ## STATE: Browse EQUIPMENT SLOTS                                     ##
    // #########################################################################
    case EEquipMenuState.BrowseSlots:
        // --- Slot Navigation ---
        var slot_count = array_length(equipment_slots);
        if (up)   { selected_slot = (selected_slot - 1 + slot_count) mod slot_count; }
        if (down) { selected_slot = (selected_slot + 1) mod slot_count; }

        // --- Party Switching ---
        var party_count = (variable_global_exists("party_members") && is_array(global.party_members)) ? array_length(global.party_members) : 0;
        var party_changed = false;
        if (left  && party_count > 1) { party_index = (party_index - 1 + party_count) mod party_count; party_changed = true; }
        if (right && party_count > 1) { party_index = (party_index + 1) mod party_count; party_changed = true; }
        if (party_changed) {
            equipment_character_key = global.party_members[party_index];
            equipment_data = scr_GetPlayerData(equipment_character_key); // Refreshes equipment_data including .class
            if (!is_struct(equipment_data)) { instance_destroy(); exit; }
            selected_slot = 0;
        }

        // --- Open Item Selection Submenu ---
        if (confirm) {
             var _slotname = equipment_slots[selected_slot];
             var _pers; // This will be the struct ref from the map
             var _character_class = "(Unknown)";

             // Get persistent struct ref (_pers) from map
             if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) {
                  show_debug_message("ERROR: global.party_current_stats missing!");
                  break;
             }
             _pers = ds_map_find_value(global.party_current_stats, equipment_character_key);
             if (!is_struct(_pers)) {
                  show_debug_message("ERROR: Persistent data struct missing for " + equipment_character_key);
                  break; // Cannot proceed without persistent data
             }

             // Get character class (should be available from equipment_data)
             if (is_struct(equipment_data) && variable_struct_exists(equipment_data, "class")) {
                 _character_class = equipment_data.class;
             } else {
                  show_debug_message("WARNING: Cannot find class in equipment_data for " + equipment_character_key);
                  // Try getting from _pers if it exists there? Or base data?
                  if (variable_struct_exists(_pers, "class")) _character_class = _pers.class; // Check _pers as fallback
                  else { // Final fallback to base data
                       var _base = scr_FetchCharacterInfo(equipment_character_key);
                       if (is_struct(_base) && variable_struct_exists(_base,"class")) _character_class = _base.class;
                  }
             }

             // Build item list from global inventory with class check
             item_submenu_choices = [ noone ];
             var _inv_list = (variable_global_exists("party_inventory") && is_array(global.party_inventory)) ? global.party_inventory : [];
             if (array_length(_inv_list) == 0 && !variable_global_exists("party_inventory")) show_debug_message("ERROR: global.party_inventory missing!");

             for (var i = 0; i < array_length(_inv_list); i++) { /* ... Filtering logic (remains the same) ... */
                 var entry = _inv_list[i];
                 if (!is_struct(entry) || !variable_struct_exists(entry, "item_key") || !variable_struct_exists(entry, "quantity") || entry.quantity <= 0) { continue; }
                 var _item_key = entry.item_key; var _item_data = scr_GetItemData(_item_key);
                 var can_equip = false;
                 if (is_struct(_item_data) && variable_struct_exists(_item_data, "type") && _item_data.type == "equipment" && variable_struct_exists(_item_data, "equip_slot") && _item_data.equip_slot == _slotname) {
                    if (variable_struct_exists(_item_data, "allowed_classes") && is_array(_item_data.allowed_classes)) {
                         var _allowed_list = _item_data.allowed_classes;
                         if (array_length(_allowed_list) == 0) { can_equip = true; }
                         else { if (is_real(array_contains)) { if (array_contains(_allowed_list, _character_class)) { can_equip = true; } } else { for (var j = 0; j < array_length(_allowed_list); j++) { if (_allowed_list[j] == _character_class) { can_equip = true; break; } } } }
                    } else { can_equip = true; }
                 }
                 if (can_equip) { array_push(item_submenu_choices, _item_key); }
             }

             // Find index of current item
             var _current_equipped_key = noone;
             // Get equipment struct directly from _pers (which is the map struct)
             if (variable_struct_exists(_pers, "equipment") && is_struct(_pers.equipment)) {
                 var _equip_struct = _pers.equipment;
                 if (variable_struct_exists(_equip_struct, _slotname)) {
                     _current_equipped_key = variable_struct_get(_equip_struct, _slotname);
                 }
             }

             item_submenu_selected_index = 0;
             for (var j = 0; j < array_length(item_submenu_choices); j++) { if (item_submenu_choices[j] == _current_equipped_key) { item_submenu_selected_index = j; break; } }

             // Calculate diffs, set scroll, change state
             var _potential_key_on_open = item_submenu_choices[item_submenu_selected_index];
             item_submenu_stat_diffs = scr_CalculateStatDifference(_current_equipped_key, _potential_key_on_open);
             item_submenu_scroll_top = 0;
             if (item_submenu_selected_index >= item_submenu_display_count) { item_submenu_scroll_top = item_submenu_selected_index - item_submenu_display_count + 1; }
             menu_state = EEquipMenuState.SelectingItem;
        }

        // --- Close / Return to Pause Menu ---
        if (back) { /* ... Close logic (remains the same) ... */
             if (instance_exists(calling_menu)) { instance_activate_object(calling_menu); if (variable_instance_exists(calling_menu, "active")) { calling_menu.active = true; } instance_destroy(); }
             else { instance_destroy(); }
             exit;
        }
        break; // End case EEquipMenuState.BrowseSlots


    // #########################################################################
    // ## STATE: SELECTING AN ITEM FROM THE LIST                              ##
    // #########################################################################
    case EEquipMenuState.SelectingItem:
         var _item_count = array_length(item_submenu_choices);
         var _current_key_equipped = noone;
         var _pers_equip; // This will be the struct reference from the map

         // --- Get persistent struct ref (_pers_equip) ALWAYS from map ---
         if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) {
              show_debug_message("CRITICAL ERROR: global.party_current_stats missing in SelectingItem state!");
              menu_state = EEquipMenuState.BrowseSlots; break;
         }
         _pers_equip = ds_map_find_value(global.party_current_stats, equipment_character_key);
         if (!is_struct(_pers_equip)){
              show_debug_message("CRITICAL ERROR: _pers_equip invalid struct in SelectingItem state for " + string(equipment_character_key) + "!");
              menu_state = EEquipMenuState.BrowseSlots; break;
         }

         // Get the currently equipped item key (from the map struct's equipment)
         var _slotname_current = equipment_slots[selected_slot];
         if (variable_struct_exists(_pers_equip, "equipment") && is_struct(_pers_equip.equipment)) {
             var _equip_struct_sel = _pers_equip.equipment;
             if (variable_struct_exists(_equip_struct_sel, _slotname_current)) {
                  _current_key_equipped = variable_struct_get(_equip_struct_sel, _slotname_current);
             }
         }

        // --- Item List Navigation & Scrolling ---
        var _index_changed = false;
        if (up) { /* ... navigation & scroll ... */ item_submenu_selected_index = (item_submenu_selected_index - 1 + _item_count) mod _item_count; _index_changed = true; if (item_submenu_selected_index < item_submenu_scroll_top) { item_submenu_scroll_top = item_submenu_selected_index; } else if (item_submenu_selected_index == _item_count - 1 && item_submenu_scroll_top > 0 && _item_count > item_submenu_display_count) { item_submenu_scroll_top = max(0, _item_count - item_submenu_display_count); } }
        if (down) { /* ... navigation & scroll ... */ item_submenu_selected_index = (item_submenu_selected_index + 1) mod _item_count; _index_changed = true; if (item_submenu_selected_index >= item_submenu_scroll_top + item_submenu_display_count) { item_submenu_scroll_top = item_submenu_selected_index - item_submenu_display_count + 1; } else if (item_submenu_selected_index == 0 && item_submenu_scroll_top > 0 && _item_count > item_submenu_display_count) { item_submenu_scroll_top = 0; } }
        item_submenu_scroll_top = max(0, min(item_submenu_scroll_top, max(0, _item_count - item_submenu_display_count)));

        if (_index_changed) { // Recalculate diffs
             var _potential_key_new = item_submenu_choices[item_submenu_selected_index];
             item_submenu_stat_diffs = scr_CalculateStatDifference(_current_key_equipped, _potential_key_new);
        }

        // --- Equip Selected Item ---
        if (confirm) {
            var _slot_to_change = equipment_slots[selected_slot];
            var _new_item_key = item_submenu_choices[item_submenu_selected_index];
            var _equip_struct_to_mod; // Reference to the equipment struct

            // Check if equipment struct exists on _pers_equip (which is the map struct)
            if (!variable_struct_exists(_pers_equip, "equipment") || !is_struct(_pers_equip.equipment)) {
                 show_debug_message("Note: Creating 'equipment' struct on map entry for '" + equipment_character_key + "' before equipping.");
                 var _new_equip_struct = { weapon:noone, offhand:noone, armor:noone, helm:noone, accessory:noone };
                 // Set the struct directly on the map struct
                 _pers_equip.equipment = _new_equip_struct;
                 _equip_struct_to_mod = _new_equip_struct;
            } else {
                 _equip_struct_to_mod = _pers_equip.equipment; // Get reference
            }

            // Modify the equipment struct (this modifies the struct within the map)
            if (is_struct(_equip_struct_to_mod)) {
                 variable_struct_set(_equip_struct_to_mod, _slot_to_change, _new_item_key);

                 // Debug log to check the map data AFTER modification
                 show_debug_message("--- Post-Equip Check ---");
                 show_debug_message("Target Slot: " + _slot_to_change + ", New Key: " + string(_new_item_key));
                 if (ds_map_exists(global.party_current_stats, equipment_character_key)) {
                     show_debug_message("Persistent Equipment Struct (Map) Now: " + string(global.party_current_stats[? equipment_character_key].equipment));
                 } else { show_debug_message("Persistent Data Missing from map!"); }
                 // --- End Debug Log ---

                 equipment_data = scr_GetPlayerData(equipment_character_key); // Refresh local cache
                 if (!is_struct(equipment_data)) { show_debug_message("ERROR: scr_GetPlayerData failed after equipping."); }
                 menu_state = EEquipMenuState.BrowseSlots; item_submenu_choices = []; item_submenu_stat_diffs = {};
            } else {
                 show_debug_message("ERROR: Failed to get valid equipment struct reference for modification!");
                 menu_state = EEquipMenuState.BrowseSlots; item_submenu_choices = []; item_submenu_stat_diffs = {};
            }
        }

        // --- Cancel Item Selection ---
        if (back) {
            menu_state = EEquipMenuState.BrowseSlots; item_submenu_choices = []; item_submenu_stat_diffs = {};
        }
        break; // End case EEquipMenuState.SelectingItem

} // End Switch (menu_state)