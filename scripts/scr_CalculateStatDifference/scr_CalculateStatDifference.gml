/// @function                scr_CalculateStatDifference(_item_key_current, _item_key_new)
/// @description             Calculates the stat difference between two items (or none).
/// @param {String/Id.Noone} _item_key_current   The key of the currently equipped item, or noone.
/// @param {String/Id.Noone} _item_key_new       The key of the potential new item, or noone.
/// @return {Struct}         A struct containing the differences {atk: val, def: val, ...}
function scr_CalculateStatDifference(_item_key_current, _item_key_new) {

    var _get_bonuses = function(_key) {
        var _bonuses = { atk:0, def:0, matk:0, mdef:0, spd:0, luk:0, hp_total:0, mp_total:0 };
        if (is_string(_key)) {
            var _item_data = scr_GetItemData(_key);
            if (is_struct(_item_data) && variable_struct_exists(_item_data, "bonuses") && is_struct(_item_data.bonuses)) {
                var _b_data = _item_data.bonuses;
                // Use nullish coalescing operator (??) for safety, defaults to 0 if stat doesn't exist
                _bonuses.atk      = _b_data.atk      ?? 0;
                _bonuses.def      = _b_data.def      ?? 0;
                _bonuses.matk     = _b_data.matk     ?? 0;
                _bonuses.mdef     = _b_data.mdef     ?? 0;
                _bonuses.spd      = _b_data.spd      ?? 0;
                _bonuses.luk      = _b_data.luk      ?? 0;
                _bonuses.hp_total = _b_data.hp_total ?? 0;
                _bonuses.mp_total = _b_data.mp_total ?? 0;
            }
        }
        return _bonuses;
    }

    var _current_bonuses = _get_bonuses(_item_key_current);
    var _new_bonuses = _get_bonuses(_item_key_new);

    var _diffs = {};
    _diffs.atk      = _new_bonuses.atk      - _current_bonuses.atk;
    _diffs.def      = _new_bonuses.def      - _current_bonuses.def;
    _diffs.matk     = _new_bonuses.matk     - _current_bonuses.matk;
    _diffs.mdef     = _new_bonuses.mdef     - _current_bonuses.mdef;
    _diffs.spd      = _new_bonuses.spd      - _current_bonuses.spd;
    _diffs.luk      = _new_bonuses.luk      - _current_bonuses.luk;
    _diffs.hp_total = _new_bonuses.hp_total - _current_bonuses.hp_total;
    _diffs.mp_total = _new_bonuses.mp_total - _current_bonuses.mp_total;

    return _diffs;
}