/// @function scr_HaveItem(_item_key, _qty_needed)
/// @description Returns true if the party has at least _qty_needed of _item_key in global.party_inventory.
function scr_HaveItem(_item_key, _qty_needed) {
    if (!variable_global_exists("party_inventory") || !is_array(global.party_inventory)) return false;
    for (var i = 0; i < array_length(global.party_inventory); i++) {
        var ent = global.party_inventory[i];
        if (is_struct(ent) && ent.item_key == _item_key && ent.quantity >= _qty_needed) {
            return true;
        }
    }
    return false;
}