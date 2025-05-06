/// @function scr_HaveItem(key, qty)
/// @returns true if you have at least `qty` of `key` in global.party_inventory.
function scr_HaveItem(_key, _qty) {
    if (!variable_global_exists("party_inventory") || !is_array(global.party_inventory)) return false;
    for (var i = 0; i < array_length(global.party_inventory); i++) {
        var e = global.party_inventory[i];
        if (is_struct(e) && e.item_key == _key && e.quantity >= _qty) {
            return true;
        }
    }
    return false;
}
