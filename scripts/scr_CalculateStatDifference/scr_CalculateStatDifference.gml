/// @function               scr_CalculateStatDifference(_item_key_current, _item_key_new)
/// @description            Calculates the stat difference between two items (or none).
/// @param {String/Id.Noone} _item_key_current    The key of the currently equipped item, or noone/invalid key.
/// @param {String/Id.Noone} _item_key_new        The key of the potential new item, or noone/invalid key.
/// @return {Struct}        A struct containing the differences {atk: val, def: val, ...}
function scr_CalculateStatDifference(_item_key_current, _item_key_new) {

    // Helper function to safely get bonuses, returning 0 for missing stats
    var _get_bonuses = function(_key) {
        // Start with a struct containing all potential bonus keys, initialized to 0
        var _bonuses = { atk:0, def:0, matk:0, mdef:0, spd:0, luk:0, hp_total:0, mp_total:0 }; 
        
        // Check if we have a valid item key string to look up
        if (is_string(_key) && _key != "" && _key != string(noone) && _key != "-4") {
            // Attempt to get the item's data
            var _item_data = scr_GetItemData(_key); // Assume scr_GetItemData exists and returns struct or undefined
            
            // Check if we got valid item data and if it has a valid 'bonuses' struct inside
            if (is_struct(_item_data) && variable_struct_exists(_item_data, "bonuses") && is_struct(_item_data.bonuses)) {
                var _b_data = _item_data.bonuses; // Reference to the item's specific bonuses struct
                
                // --- MODIFICATION: Use variable_struct_get for Safe Access ---
                // variable_struct_get returns 'undefined' if a key is missing.
                // The '?? 0' operator handles 'undefined' by defaulting to 0.
                _bonuses.atk      = variable_struct_get(_b_data, "atk")      ?? 0;
                _bonuses.def      = variable_struct_get(_b_data, "def")      ?? 0; // This line caused the previous crash
                _bonuses.matk     = variable_struct_get(_b_data, "matk")     ?? 0;
                _bonuses.mdef     = variable_struct_get(_b_data, "mdef")     ?? 0;
                _bonuses.spd      = variable_struct_get(_b_data, "spd")      ?? 0;
                _bonuses.luk      = variable_struct_get(_b_data, "luk")      ?? 0;
                _bonuses.hp_total = variable_struct_get(_b_data, "hp_total") ?? 0;
                _bonuses.mp_total = variable_struct_get(_b_data, "mp_total") ?? 0;
                // --- END MODIFICATION ---

            } // else: Item exists but has no valid 'bonuses' struct, _bonuses remains all zeros
        } // else: _key was invalid (like noone or -4), _bonuses remains all zeros
        
        // Return the struct containing either the item's bonuses or all zeros
        return _bonuses;
    }

    // Get the safe bonus structs for both items being compared
    var _current_bonuses = _get_bonuses(_item_key_current);
    var _new_bonuses     = _get_bonuses(_item_key_new);

    // Calculate differences between the new item and the current item
    var _diffs = {};
    _diffs.atk      = _new_bonuses.atk      - _current_bonuses.atk;
    _diffs.def      = _new_bonuses.def      - _current_bonuses.def;
    _diffs.matk     = _new_bonuses.matk     - _current_bonuses.matk;
    _diffs.mdef     = _new_bonuses.mdef     - _current_bonuses.mdef;
    _diffs.spd      = _new_bonuses.spd      - _current_bonuses.spd;
    _diffs.luk      = _new_bonuses.luk      - _current_bonuses.luk;
    _diffs.hp_total = _new_bonuses.hp_total - _current_bonuses.hp_total;
    _diffs.mp_total = _new_bonuses.mp_total - _current_bonuses.mp_total;

    // Return the struct containing the calculated differences
    return _diffs;
}