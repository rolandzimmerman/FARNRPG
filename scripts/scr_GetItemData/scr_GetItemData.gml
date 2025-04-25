/// @function scr_GetItemData(_key)
/// @description Returns the item struct for `_key`, or `undefined`.
function scr_GetItemData(_key) {
    if (!variable_global_exists("item_database") 
        || !ds_exists(global.item_database, ds_type_map)) {
        return undefined;
    }
    var data = ds_map_find_value(global.item_database, _key);
    return is_struct(data) ? data : undefined;
}
