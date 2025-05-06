/// @function scr_AddCurrency(amount)
/// Increments global.party_currency by `amount` (must be ≥ 0).
function scr_AddCurrency(_amt) {
    if (!variable_global_exists("party_currency")) global.party_currency = 0;
    global.party_currency = max(0, global.party_currency + _amt);
}

/// @function scr_SpendCurrency(amount)
/// Deducts if enough; returns true on success.
function scr_SpendCurrency(_amt) {
    if (!variable_global_exists("party_currency")) global.party_currency = 0;
    if (global.party_currency < _amt) return false;
    global.party_currency -= _amt;
    return true;
}
