/// @function scr_GetPlayerData(_char_key)
/// @description Creates a struct containing current battle stats for a given character key,
///              prioritizing persistent stats over base stats.
/// @param {String} _char_key The key of the character (e.g., "hero", "claude")
function scr_GetPlayerData(_char_key) {

    // 1. Get Base Character Definition (for defaults and skill list)
    var _base_data = scr_FetchCharacterInfo(_char_key);
    if (is_undefined(_base_data)) {
        show_debug_message("ERROR [scr_GetPlayerData]: Cannot find base data for character key: " + _char_key);
        // Return minimal default data to prevent crashes
        return {
             character_key: _char_key, name: "???",
             hp: 1, maxhp: 1, mp: 1, maxmp: 1, atk: 1, def: 1,
             matk: 1, mdef: 1, spd: 1, luk: 1, level: 1, xp: 0, xp_require: 100,
             skills: [], skill_index: 0, item_index: 0, is_defending: false, status: "none"
        };
    }

    // 2. Determine the source of persistent stats
    var _persistent_stats_source = undefined;
    var _is_hero = (_char_key == "hero");

    if (_is_hero && instance_exists(obj_player)) {
        _persistent_stats_source = obj_player;
        show_debug_message("  [GetPlayerData] Getting persistent stats for 'hero' from obj_player.");
    } else {
        if (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) {
            var _saved_stats = ds_map_find_value(global.party_current_stats, _char_key);
            if (is_struct(_saved_stats)) {
                _persistent_stats_source = _saved_stats; // Found saved stats
                show_debug_message("  [GetPlayerData] Getting persistent stats for '" + _char_key + "' from global map.");
            } else {
                // No saved stats for this char yet, initialize in global map using base stats
                show_debug_message("  [GetPlayerData] No current stats found for '" + _char_key + "'. Initializing in global map.");
                var _xp_req_lvl_2 = (script_exists(scr_GetXPForLevel)) ? scr_GetXPForLevel(2) : 100;
                var _new_stats_entry = {
                    hp: _base_data.hp_total, hp_total: _base_data.hp_total,
                    mp: _base_data.mp_total, mp_total: _base_data.mp_total,
                    level: 1, xp: 0, xp_require: _xp_req_lvl_2,
                    atk: _base_data.atk, def: _base_data.def, matk: _base_data.matk,
                    mdef: _base_data.mdef, spd: _base_data.spd, luk: _base_data.luk
                };
                ds_map_add(global.party_current_stats, _char_key, _new_stats_entry);
                _persistent_stats_source = _new_stats_entry; // Use the newly created entry
            }
        } else {
            show_debug_message("  [GetPlayerData] WARNING: global.party_current_stats map missing! Using base stats only.");
             _persistent_stats_source = _base_data; // Fallback - likely inaccurate after first battle
        }
    }

    // 3. Construct the Battle Data Struct, prioritizing persistent source
    var _battle_data = {};
    _battle_data.character_key = _char_key;
    _battle_data.name = _base_data.name; // Name always comes from base

    // --- FIX: Prioritize ALL persistent stats over base stats ---
    // Read values from the determined source (_persistent_stats_source) if it exists and is a struct
    if (!is_undefined(_persistent_stats_source) && is_struct(_persistent_stats_source)) {
        _battle_data.hp = variable_struct_exists(_persistent_stats_source, "hp") ? _persistent_stats_source.hp : _base_data.hp_total;
        _battle_data.maxhp = variable_struct_exists(_persistent_stats_source, "hp_total") ? _persistent_stats_source.hp_total : _base_data.hp_total;
        _battle_data.mp = variable_struct_exists(_persistent_stats_source, "mp") ? _persistent_stats_source.mp : _base_data.mp_total;
        _battle_data.maxmp = variable_struct_exists(_persistent_stats_source, "mp_total") ? _persistent_stats_source.mp_total : _base_data.mp_total;
        _battle_data.atk = variable_struct_exists(_persistent_stats_source, "atk") ? _persistent_stats_source.atk : _base_data.atk;
        _battle_data.def = variable_struct_exists(_persistent_stats_source, "def") ? _persistent_stats_source.def : _base_data.def;
        _battle_data.matk = variable_struct_exists(_persistent_stats_source, "matk") ? _persistent_stats_source.matk : _base_data.matk;
        _battle_data.mdef = variable_struct_exists(_persistent_stats_source, "mdef") ? _persistent_stats_source.mdef : _base_data.mdef;
        _battle_data.spd = variable_struct_exists(_persistent_stats_source, "spd") ? _persistent_stats_source.spd : _base_data.spd;
        _battle_data.luk = variable_struct_exists(_persistent_stats_source, "luk") ? _persistent_stats_source.luk : _base_data.luk;
        _battle_data.level = variable_struct_exists(_persistent_stats_source, "level") ? _persistent_stats_source.level : 1;
        _battle_data.xp = variable_struct_exists(_persistent_stats_source, "xp") ? _persistent_stats_source.xp : 0;
        // Calculate required XP based on the loaded level
        var _req_xp = (script_exists(scr_GetXPForLevel)) ? scr_GetXPForLevel(_battle_data.level + 1) : 100;
        _battle_data.xp_require = variable_struct_exists(_persistent_stats_source, "xp_require") ? _persistent_stats_source.xp_require : _req_xp;
    } else {
        // Fallback if persistent source is invalid (should only happen if setup is wrong)
        _battle_data.hp = _base_data.hp_total; _battle_data.maxhp = _base_data.hp_total;
        _battle_data.mp = _base_data.mp_total; _battle_data.maxmp = _base_data.mp_total;
        _battle_data.atk = _base_data.atk; _battle_data.def = _base_data.def;
        _battle_data.matk = _base_data.matk; _battle_data.mdef = _base_data.mdef;
        _battle_data.spd = _base_data.spd; _battle_data.luk = _base_data.luk;
        _battle_data.level = 1; _battle_data.xp = 0;
        _battle_data.xp_require = (script_exists(scr_GetXPForLevel)) ? scr_GetXPForLevel(2) : 100;
    }
    // --- END FIX ---

    // Battle-specific state
    _battle_data.skills = _base_data.skills; // Base skills known
    _battle_data.skill_index = 0;
    _battle_data.item_index = 0;
    _battle_data.is_defending = false;
    _battle_data.status = "none";

    show_debug_message("  [GetPlayerData] Created battle data for " + _char_key + ": HP " + string(_battle_data.hp) + "/" + string(_battle_data.maxhp) + " | Level " + string(_battle_data.level) + " | XP " + string(_battle_data.xp) + "/" + string(_battle_data.xp_require));

    return _battle_data;
}
