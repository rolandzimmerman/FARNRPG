/// obj_item_menu_field :: Create Event

// --- State Initialization ---
active               = true;
calling_menu         = noone;
item_index           = 0;
target_party_index   = 0;
menu_state           = "item_select";
usable_items         = [];

// --- Debug ---
show_debug_message("obj_item_menu_field Create: Populating usable field items...");

// --- Populate usable_items from global.party_inventory ---
if (variable_global_exists("party_inventory")
 && is_array(global.party_inventory)
 && script_exists(scr_GetItemData)) {
    
    var inventory = global.party_inventory;
    var invSize   = array_length(inventory);
    show_debug_message(" -> Inventory size: " + string(invSize));
    
    for (var i = 0; i < invSize; i++) {
        var invEntry = inventory[i];
        
        // Validate entry
        if (!is_struct(invEntry)
         || !variable_struct_exists(invEntry, "item_key")
         || !variable_struct_exists(invEntry, "quantity")) {
            show_debug_message("    -> Skipping invalid entry at index " + string(i));
            continue;
        }
        
        var key      = invEntry.item_key;
        var qty      = invEntry.quantity;
        if (qty <= 0) continue;
        
        var data     = scr_GetItemData(key);
        if (is_struct(data) && (data.usable_in_field ?? false)) {
            // Add to usable list, including icon & FX
            array_push(usable_items, {
                item_key  : key,
                quantity  : qty,
                name      : data.name       ?? "???",
                sprite    : data.sprite_index ?? -1,
                fx_sprite : data.fx_sprite    ?? -1,
                fx_sound  : data.fx_sound     ?? -1
            });
            show_debug_message("    -> Added: " 
                + string(data.name) + " x" + string(qty));
        }
    }
    
} else {
    show_debug_message(" -> ERROR: party_inventory missing or scr_GetItemData unavailable.");
}

// --- Finalize starting index ---
if (array_length(usable_items) == 0) {
    item_index = -1;
} else {
    item_index = 0;
}
