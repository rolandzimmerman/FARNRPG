/// @function scr_AddInventoryItem(item_key, quantity_to_add)
/// @description Finds an item in global.party_inventory and increases its quantity, or adds a new entry.
/// @param {String} item_key            The key of the item to add (e.g., "potion").
/// @param {Real}   quantity_to_add   The amount to increase the quantity by (typically 1).
/// @return {Bool}  Returns true if the item was added/quantity increased, false otherwise.
function scr_AddInventoryItem(_item_key, _qty_add) {

    if (!variable_global_exists("party_inventory") || !is_array(global.party_inventory)) {
        show_debug_message("ERROR [scr_AddInventoryItem]: global.party_inventory does not exist or not an array!");
        return false;
    }
     if (!is_string(_item_key) || !is_real(_qty_add) || _qty_add <= 0) {
         show_debug_message("ERROR [scr_AddInventoryItem]: Invalid arguments provided (key: " + string(_item_key) + ", qty: " + string(_qty_add) + ")");
        return false;
    }

    var _found = false;
    // Try to find existing stack
    for (var i = 0; i < array_length(global.party_inventory); i++) {
        var _entry = global.party_inventory[i];
        if (is_struct(_entry) && variable_struct_exists(_entry, "item_key") && _entry.item_key == _item_key) {
             if (variable_struct_exists(_entry, "quantity")) {
                 show_debug_message("[scr_AddInventoryItem] Found existing stack for " + _item_key + ". Adding " + string(_qty_add));
                 _entry.quantity += _qty_add;
                 _found = true;
                  show_debug_message(" -> New Quantity: " + string(_entry.quantity));
                 break; // Found and updated stack
             }
        }
    }

    // If not found, add a new entry
    if (!_found) {
         show_debug_message("[scr_AddInventoryItem] No existing stack for " + _item_key + ". Adding new entry.");
         var _new_entry = {
             item_key: _item_key,
             quantity: _qty_add
         };
         array_push(global.party_inventory, _new_entry);
         _found = true; // Item was added
    }

    return _found;
}