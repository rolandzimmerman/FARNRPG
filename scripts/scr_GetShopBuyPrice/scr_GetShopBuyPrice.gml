/// @function scr_GetShopBuyPrice(item_key, multiplier)
/// @returns floor(base_price * multiplier)
function scr_GetShopBuyPrice(_key, _mult) {
    var data = scr_GetItemData(_key);
    if (!is_struct(data)) return 0;
    var base = data.base_price ?? 0;
    return floor(base * _mult);
}