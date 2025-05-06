/// @function scr_HaveItem(item_key, qty)
/// @description Returns true if global.party_inventory has at least qty of item_key.
function scr_HaveItem(_item_key, _qty) {
    if (!variable_global_exists("party_inventory") || !is_array(global.party_inventory)) return false;
    var total = 0;
    for (var i = 0; i < array_length(global.party_inventory); i++) {
        var e = global.party_inventory[i];
        if (is_struct(e) && variable_struct_exists(e, "item_key") && e.item_key == _item_key) {
            total += (variable_struct_exists(e, "quantity") ? e.quantity : 0);
            if (total >= _qty) return true;
        }
    }
    return false;
}


