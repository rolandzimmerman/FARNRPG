/// @function scr_GetShopSellPrice(item_key, multiplier)
/// @returns floor(base_price * multiplier)
function scr_GetShopSellPrice(_key, _mult) {
    var data = scr_GetItemData(_key);
    if (!is_struct(data)) return 0;
    var base = data.base_price ?? 0;
    return floor(base * _mult);
}