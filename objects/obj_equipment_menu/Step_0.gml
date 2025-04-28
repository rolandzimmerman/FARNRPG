/// obj_equipment_menu :: Step Event
/// Handles navigation, party switching, opening item list, equipping, and closing.

// Ensure State Enum Exists (assuming it's defined globally in a script now)
// enum EEquipMenuState { BrowseSlots, SelectingItem } 

// Only run when this menu is active overall
if (!variable_instance_exists(id,"menu_active") || !menu_active) return;

// --- Initialize Instance Variables if they somehow don't exist (Safety) ---
if (!variable_instance_exists(id, "menu_state"))                  menu_state = EEquipMenuState.BrowseSlots;
if (!variable_instance_exists(id, "equipment_slots"))             equipment_slots = [ "weapon", "offhand", "armor", "helm", "accessory" ];
if (!variable_instance_exists(id, "selected_slot"))               selected_slot = 0;
if (!variable_instance_exists(id, "party_index"))                 party_index = 0;
if (!variable_instance_exists(id, "equipment_character_key"))     equipment_character_key = (variable_global_exists("party_members") && is_array(global.party_members) && array_length(global.party_members)>0) ? global.party_members[0] : "hero";
if (!variable_instance_exists(id, "equipment_data") || !is_struct(equipment_data)) { equipment_data = scr_GetPlayerData(equipment_character_key); if (!is_struct(equipment_data)) { instance_destroy(); exit; } } 
if (!variable_instance_exists(id, "item_submenu_choices"))        item_submenu_choices = [];
if (!variable_instance_exists(id, "item_submenu_selected_index")) item_submenu_selected_index = 0;
if (!variable_instance_exists(id, "item_submenu_scroll_top"))     item_submenu_scroll_top = 0;
if (!variable_instance_exists(id, "item_submenu_display_count"))  item_submenu_display_count = 5;
if (!variable_instance_exists(id, "item_submenu_stat_diffs"))     item_submenu_stat_diffs = {};
if (!variable_instance_exists(id, "calling_menu"))                calling_menu = noone;


// — INPUT READING —————————————————————————————————————————————
var device = 0; // Or get current device
var up      = keyboard_check_pressed(vk_up)      || gamepad_button_check_pressed(device, gp_padu);
var down    = keyboard_check_pressed(vk_down)    || gamepad_button_check_pressed(device, gp_padd);
// Check individual inputs for party switching
var kb_left = keyboard_check_pressed(vk_left);    
var kb_right= keyboard_check_pressed(vk_right);   
var gp_left = gamepad_button_check_pressed(device, gp_shoulderl); // Left Shoulder/Bumper
var gp_right= gamepad_button_check_pressed(device, gp_shoulderr);// Right Shoulder/Bumper
// Combine them
var left    = kb_left || gp_left;   
var right   = kb_right || gp_right; 
var confirm = keyboard_check_pressed(vk_enter)   || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(device, gp_face1); // A or X (Playstation)
var back    = keyboard_check_pressed(vk_escape)  || gamepad_button_check_pressed(device, gp_face2); // B or Circle (Playstation)

// --- State Machine Logic ————————————————————————————————————————————————
switch (menu_state) {

    // #########################################################################
    // ## STATE: Browse EQUIPMENT SLOTS                                       ##
    // #########################################################################
    case EEquipMenuState.BrowseSlots:
        
        // <<< ADDED RAW INPUT LOGGING >>>
        // Check if ANY relevant input is pressed this step
        if (up || down || left || right || confirm || back) {
            show_debug_message("BrowseSlots Raw Input -> KB L/R: " + string(kb_left) + "/" + string(kb_right) + 
                               " | GP L/R: " + string(gp_left) + "/" + string(gp_right) + 
                               " | Combined L/R: " + string(left) + "/" + string(right) +
                               " | Confirm: " + string(confirm) + " | Back: " + string(back) );
        }
        // <<< END LOGGING >>>

        // --- Slot Navigation ---
        var slot_count = array_length(equipment_slots);
        if (up)   { selected_slot = (selected_slot - 1 + slot_count) mod slot_count; /* Play Sound? */ }
        if (down) { selected_slot = (selected_slot + 1) mod slot_count; /* Play Sound? */ }

        // --- Party Switching ---
        var party_count = (variable_global_exists("party_members") && is_array(global.party_members)) ? array_length(global.party_members) : 0;
        var party_changed = false;
        
        if (left  && party_count > 1) { party_index = (party_index - 1 + party_count) mod party_count; party_changed = true; }
        if (right && party_count > 1) { party_index = (party_index + 1) mod party_count; party_changed = true; }
        
        if (party_changed) { 
            equipment_character_key = global.party_members[party_index];
            show_debug_message(" -> Party Switch Attempt: Index=" + string(party_index) + ", Key=" + equipment_character_key); 
            equipment_data = scr_GetPlayerData(equipment_character_key); 
            if (!is_struct(equipment_data)) { 
                 show_debug_message("ERROR: scr_GetPlayerData failed during party switch!");
                 // Revert index change
                 party_index = (party_index - ((left) ? -1 : 1) + party_count) mod party_count; 
                 equipment_character_key = global.party_members[party_index]; 
                 equipment_data = scr_GetPlayerData(equipment_character_key); 
                 break; 
            }
            selected_slot = 0; 
            show_debug_message(" -> Party Switch SUCCESS. Displaying data for: " + equipment_character_key + " (Class: " + string(variable_struct_get(equipment_data, "class") ?? "N/A") + ")"); 
        }

        // --- Open Item Selection Submenu ---
        if (confirm) { 
             show_debug_message(" -> Confirm pressed on slot: " + equipment_slots[selected_slot]);
             var _slotname = equipment_slots[selected_slot];
             var _pers; 
             var _character_class = variable_struct_get(equipment_data, "class") ?? "Unknown"; 

             if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) { show_debug_message("ERROR: global.party_current_stats missing!"); break; }
             _pers = ds_map_find_value(global.party_current_stats, equipment_character_key);
             if (!is_struct(_pers)){ show_debug_message("ERROR: Persistent data struct missing for " + equipment_character_key); break; }

             // Build item list from global inventory
             item_submenu_choices = [ noone ]; 
             var _inv_list = (variable_global_exists("party_inventory") && is_array(global.party_inventory)) ? global.party_inventory : [];
             if (array_length(_inv_list) == 0 && !variable_global_exists("party_inventory")) show_debug_message("ERROR: global.party_inventory missing!");

             show_debug_message(" -> Building item list for slot: " + _slotname + " | Char Class: " + _character_class);
             for (var i = 0; i < array_length(_inv_list); i++) { 
                var entry = _inv_list[i];
                if (!is_struct(entry) || !variable_struct_exists(entry, "item_key") || !variable_struct_exists(entry, "quantity") || entry.quantity <= 0) { continue; }
                var _item_key = entry.item_key; 
                var _item_data = scr_GetItemData(_item_key); 
                
                // Check if item is equippable in this slot by this class
                var can_equip = false;
                if (is_struct(_item_data)) {
                    if (variable_struct_exists(_item_data, "type") && variable_struct_exists(_item_data, "equip_slot")) {
                         if (_item_data.type == "equipment" && _item_data.equip_slot == _slotname) {
                             if (variable_struct_exists(_item_data, "allowed_classes") && is_array(_item_data.allowed_classes)) {
                                 var _allowed_list = _item_data.allowed_classes;
                                 if (array_length(_allowed_list) == 0) { can_equip = true; } 
                                 else { for (var j = 0; j < array_length(_allowed_list); j++) { if (_allowed_list[j] == _character_class) { can_equip = true; break; } } }
                             } else { can_equip = true; } 
                         }
                    }
                }

                if (can_equip) { array_push(item_submenu_choices, _item_key); }
             } 
             show_debug_message("    -> Built item list: " + string(item_submenu_choices));

             // Find index of currently equipped item
             var _current_equipped_key = noone;
             if (variable_struct_exists(_pers, "equipment") && is_struct(_pers.equipment)) {
                 var _equip_struct_sel = _pers.equipment;
                 if (variable_struct_exists(_equip_struct_sel, _slotname)) { _current_equipped_key = variable_struct_get(_equip_struct_sel, _slotname); }
             }
             item_submenu_selected_index = 0; 
             for (var j = 0; j < array_length(item_submenu_choices); j++) { if (item_submenu_choices[j] == _current_equipped_key) { item_submenu_selected_index = j; break; } }
             show_debug_message("    -> Current item key: " + string(_current_equipped_key) + ", Selected Index: " + string(item_submenu_selected_index));

             // Calculate diffs, set scroll, change state
             var _potential_key_on_open = item_submenu_choices[item_submenu_selected_index];
              if (script_exists(scr_CalculateStatDifference)) { item_submenu_stat_diffs = scr_CalculateStatDifference(_current_equipped_key, _potential_key_on_open); } 
              else { show_debug_message("Warning: scr_CalculateStatDifference script missing!"); item_submenu_stat_diffs = {}; }
             item_submenu_scroll_top = 0;
             if (item_submenu_selected_index >= item_submenu_display_count) { item_submenu_scroll_top = item_submenu_selected_index - item_submenu_display_count + 1; }
             menu_state = EEquipMenuState.SelectingItem; 
             show_debug_message("    -> Changed state to SelectingItem");
        } // End if(confirm)

        // --- Close / Return to Pause Menu ---
        if (back) { 
             show_debug_message(" -> Closing Equipment Menu.");
             if (instance_exists(calling_menu)) { 
                 instance_activate_object(calling_menu); 
                 if (variable_instance_exists(calling_menu, "active")) { calling_menu.active = true; } 
             }
             instance_destroy(); 
             exit;
        }
        break; // End case EEquipMenuState.BrowseSlots


    // #########################################################################
    // ## STATE: SELECTING AN ITEM FROM THE LIST                              ##
    // #########################################################################
    case EEquipMenuState.SelectingItem:
         var _item_count = array_length(item_submenu_choices);
         var _pers_equip; 

         // Get persistent struct ref 
         if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) { show_debug_message("CRITICAL ERROR: global.party_current_stats missing!"); menu_state = EEquipMenuState.BrowseSlots; break; }
         _pers_equip = ds_map_find_value(global.party_current_stats, equipment_character_key);
         if (!is_struct(_pers_equip)){ show_debug_message("CRITICAL ERROR: _pers_equip invalid struct!"); menu_state = EEquipMenuState.BrowseSlots; break; }

         // Get currently equipped key for comparison
         var _slotname_current = equipment_slots[selected_slot];
         var _current_key_equipped = noone;
         if (variable_struct_exists(_pers_equip, "equipment") && is_struct(_pers_equip.equipment)) {
             var _equip_struct_sel = _pers_equip.equipment;
             if (variable_struct_exists(_equip_struct_sel, _slotname_current)) { _current_key_equipped = variable_struct_get(_equip_struct_sel, _slotname_current); }
         }

         // --- Item List Navigation & Scrolling ---
         var _index_changed = false;
         if (up) { item_submenu_selected_index = (item_submenu_selected_index - 1 + _item_count) mod _item_count; _index_changed = true; if (item_submenu_selected_index < item_submenu_scroll_top) { item_submenu_scroll_top = item_submenu_selected_index; } else if (item_submenu_selected_index == _item_count - 1 && item_submenu_scroll_top > 0 && _item_count > item_submenu_display_count) { item_submenu_scroll_top = max(0, _item_count - item_submenu_display_count); } }
         if (down) { item_submenu_selected_index = (item_submenu_selected_index + 1) mod _item_count; _index_changed = true; if (item_submenu_selected_index >= item_submenu_scroll_top + item_submenu_display_count) { item_submenu_scroll_top = item_submenu_selected_index - item_submenu_display_count + 1; } else if (item_submenu_selected_index == 0 && item_submenu_scroll_top > 0 && _item_count > item_submenu_display_count) { item_submenu_scroll_top = 0; } }
         item_submenu_scroll_top = max(0, min(item_submenu_scroll_top, max(0, _item_count - item_submenu_display_count)));

         if (_index_changed && script_exists(scr_CalculateStatDifference)) { // Recalculate diffs
              var _potential_key_new = item_submenu_choices[item_submenu_selected_index];
              item_submenu_stat_diffs = scr_CalculateStatDifference(_current_key_equipped, _potential_key_new);
         }

         // --- Equip Selected Item ---
         if (confirm) {
             var _slot_to_change = equipment_slots[selected_slot];
             var _new_item_key = item_submenu_choices[item_submenu_selected_index]; 
             var _equip_struct_to_mod; 

             show_debug_message(" -> Attempting to equip '" + string(_new_item_key) + "' in slot '" + _slot_to_change + "' for " + equipment_character_key);

             if (!variable_struct_exists(_pers_equip, "equipment") || !is_struct(_pers_equip.equipment)) {
                  show_debug_message("Note: Creating 'equipment' struct on map entry for '" + equipment_character_key + "' before equipping.");
                  _pers_equip.equipment = { weapon:noone, offhand:noone, armor:noone, helm:noone, accessory:noone };
             }
             _equip_struct_to_mod = _pers_equip.equipment; 

             if (variable_struct_exists(_equip_struct_to_mod, _slot_to_change)) { 
                 variable_struct_set(_equip_struct_to_mod, _slot_to_change, _new_item_key);
                 show_debug_message("    -> Set " + _slot_to_change + " = " + string(_new_item_key) + " in persistent data.");
                 
                 // Debug log 
                 show_debug_message("--- Post-Equip Check ---");
                 if (ds_map_exists(global.party_current_stats, equipment_character_key)) { show_debug_message("Persistent Equipment Struct (Map) Now: " + string(global.party_current_stats[? equipment_character_key].equipment)); } 
                 else { show_debug_message("Persistent Data Missing from map!"); }
                 
                 // Refresh local cache to update display immediately
                 equipment_data = scr_GetPlayerData(equipment_character_key); 
                 if (!is_struct(equipment_data)) { show_debug_message("ERROR: scr_GetPlayerData failed after equipping."); }
                 
                 menu_state = EEquipMenuState.BrowseSlots; 
                 item_submenu_choices = []; item_submenu_stat_diffs = {};
             } else {
                  show_debug_message("ERROR: Invalid slot name '" + _slot_to_change + "' in equipment struct!");
                  menu_state = EEquipMenuState.BrowseSlots; item_submenu_choices = []; item_submenu_stat_diffs = {};
             }
         }

         // --- Cancel Item Selection ---
         if (back) {
              menu_state = EEquipMenuState.BrowseSlots; item_submenu_choices = []; item_submenu_stat_diffs = {};
              /* Play Sound? */
         }
         break; // End case EEquipMenuState.SelectingItem

} // End Switch