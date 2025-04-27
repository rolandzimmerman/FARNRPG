/// @function scr_RemoveInventoryItem(item_key, quantity_to_remove)
/// @description Finds an item in global.party_inventory and decreases its quantity. Removes if quantity reaches zero or less.
/// @param {String} item_key              The key of the item to remove (e.g., "potion").
/// @param {Real}   quantity_to_remove    The amount to decrease the quantity by (typically 1).
/// @return {Bool}  Returns true if the item was found and quantity decreased/removed, false otherwise.
function scr_RemoveInventoryItem(_item_key, _qty_remove) {

    if (!variable_global_exists("party_inventory") || !is_array(global.party_inventory)) {
        show_debug_message("ERROR [scr_RemoveInventoryItem]: global.party_inventory does not exist or not an array!");
        return false;
    }
    if (!is_string(_item_key) || !is_real(_qty_remove) || _qty_remove <= 0) {
         show_debug_message("ERROR [scr_RemoveInventoryItem]: Invalid arguments provided (key: " + string(_item_key) + ", qty: " + string(_qty_remove) + ")");
        return false;
    }

    var _found = false;
    // Iterate backwards when deleting to avoid skipping elements
    for (var i = array_length(global.party_inventory) - 1; i >= 0; i--) {
        var _entry = global.party_inventory[i];

        // Check if entry is valid and matches the key
        if (is_struct(_entry) && variable_struct_exists(_entry, "item_key") && _entry.item_key == _item_key) {
             if (variable_struct_exists(_entry, "quantity")) {
                 show_debug_message("[scr_RemoveInventoryItem] Found " + _item_key + ". Current Qty: " + string(_entry.quantity) + ". Removing: " + string(_qty_remove));
                 _entry.quantity -= _qty_remove; // Decrease quantity
                 _found = true;

                 // If quantity drops to 0 or below, remove the entry from the array
                 if (_entry.quantity <= 0) {
                     show_debug_message(" -> Quantity reached zero. Removing item entry from inventory.");
                     array_delete(global.party_inventory, i, 1);
                 } else {
                      show_debug_message(" -> New Quantity: " + string(_entry.quantity));
                 }
                 // Assuming item keys are unique in the inventory list for now
                 // If multiple stacks were possible, we might not 'break' here.
                 break;
             }
        }
    }

    if (!_found) {
         show_debug_message("WARNING [scr_RemoveInventoryItem]: Item key '" + _item_key + "' not found in inventory to remove.");
    }

    return _found;
}