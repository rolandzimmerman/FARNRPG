/// @function scr_GetItemBasePrice(_item_key)
/// @returns the base_price of the item, or -1 if not found
function scr_GetItemBasePrice(_key) {
    var data = scr_GetItemData(_key);
    return (is_struct(data) && variable_struct_exists(data, "base_price"))
         ? data.base_price
         : -1;
}