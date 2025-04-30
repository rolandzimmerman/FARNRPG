/// @description Initialize Field Item Menu state and populate usable items

active = true;          // Is this menu currently active?
calling_menu = noone;   // Which menu instance opened this one (set by caller)?

item_index = 0;         // Index for the item list
target_party_index = 0; // Index for the party target list (used later)
menu_state = "item_select"; // Initial state: selecting item

usable_items = [];      // Array to hold structs of usable field items { item_key, quantity, name }

show_debug_message("obj_item_menu_field Create: Populating usable field items...");

// --- Populate usable_items list ---
if (variable_global_exists("party_inventory") && is_array(global.party_inventory) && script_exists(scr_GetItemData)) {
    var _inventory = global.party_inventory;
    var _inv_size = array_length(_inventory);
    show_debug_message(" -> Checking inventory size: " + string(_inv_size));

    for (var i = 0; i < _inv_size; i++) { 
        var _inv_entry = _inventory[i];
        
        // Validate inventory entry format
        if (!is_struct(_inv_entry) || !variable_struct_exists(_inv_entry, "item_key") || !variable_struct_exists(_inv_entry, "quantity")) {
             show_debug_message("    -> Skipping invalid inventory entry at index: " + string(i));
             continue; 
        }
        
        var _item_key = _inv_entry.item_key;
        var _quantity = _inv_entry.quantity;

        // Skip items with zero quantity
        if (_quantity <= 0) continue; 

        // Get detailed item data
        var _item_data = scr_GetItemData(_item_key); 

        // Check if item data is valid and usable in the field
        if (is_struct(_item_data) && (variable_struct_get(_item_data, "usable_in_field") ?? false) ) { 
            // Add relevant info to our list
             array_push(usable_items, { 
                 item_key: _item_key, 
                 quantity: _quantity, 
                 name: variable_struct_get(_item_data, "name") ?? "???" // Get name safely
             }); 
             show_debug_message("    -> Added usable field item: " + string(variable_struct_get(_item_data, "name") ?? _item_key) + " x" + string(_quantity));
        }
    }
    show_debug_message(" -> Finished populating. Usable items count: " + string(array_length(usable_items)));
} else {
     show_debug_message(" -> ERROR: Cannot populate items. Inventory missing or scr_GetItemData missing.");
}

// Ensure index is valid even if list is empty
if (array_length(usable_items) == 0) {
     item_index = -1; // Indicate no selectable item
} else {
     item_index = 0; // Start selection at the first item
}