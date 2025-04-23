/// @function scr_GetPlayerData(_char_key)
/// @description Creates a struct containing current battle stats for a given character key,
///              prioritizing persistent stats over base stats.
/// @param {String} _char_key The key of the character (e.g., "hero", "claude")
function scr_GetPlayerData(_char_key) {

    // 1. Get Base Character Definition
    var _base_data = scr_FetchCharacterInfo(_char_key);
    if (is_undefined(_base_data)) {
        // Return minimal default data
        return { /* ... */ };
    }

    // 2. Determine the source of persistent stats
    var _persistent_stats_source = undefined;
    var _is_hero = (_char_key == "hero");

    if (_is_hero && instance_exists(obj_player)) {
        _persistent_stats_source = obj_player;
        show_debug_message("  [GetPlayerData] Getting persistent stats for 'hero' from obj_player (ID: " + string(obj_player.id) + ")");
        // --- LOGGING: Log the values being read from obj_player ---
        show_debug_message("    -> Reading obj_player - HP: " + string(obj_player.hp) + ", Level: " + string(obj_player.level) + ", XP: " + string(obj_player.xp) + "/" + string(obj_player.xp_require));
        // --- END LOGGING ---
    } else {
        if (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) {
            var _saved_stats = ds_map_find_value(global.party_current_stats, _char_key);
            if (is_struct(_saved_stats)) {
                _persistent_stats_source = _saved_stats;
                show_debug_message("  [GetPlayerData] Getting persistent stats for '" + _char_key + "' from global map.");
            } else {
                // Initialize in global map
                show_debug_message("  [GetPlayerData] No current stats found for '" + _char_key + "'. Initializing in global map.");
                var _xp_req_lvl_2 = (script_exists(scr_GetXPForLevel)) ? scr_GetXPForLevel(2) : 100;
                var _new_stats_entry = { hp: _base_data.hp_total, hp_total: _base_data.hp_total, mp: _base_data.mp_total, mp_total: _base_data.mp_total, level: 1, xp: 0, xp_require: _xp_req_lvl_2, atk: _base_data.atk, def: _base_data.def, matk: _base_data.matk, mdef: _base_data.mdef, spd: _base_data.spd, luk: _base_data.luk };
                ds_map_add(global.party_current_stats, _char_key, _new_stats_entry);
                _persistent_stats_source = _new_stats_entry;
            }
        } else {
             _persistent_stats_source = _base_data; // Fallback
        }
    }

    // 3. Construct the Battle Data Struct
    var _battle_data = {};
    _battle_data.character_key = _char_key;
    _battle_data.name = _base_data.name;

    if (!is_undefined(_persistent_stats_source) && (is_struct(_persistent_stats_source) || instance_exists(_persistent_stats_source))) {
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
        var _req_xp = (script_exists(scr_GetXPForLevel)) ? scr_GetXPForLevel(_battle_data.level + 1) : 100;
        _battle_data.xp_require = variable_struct_exists(_persistent_stats_source, "xp_require") ? _persistent_stats_source.xp_require : _req_xp;
    } else {
        // Fallback
        _battle_data.hp = _base_data.hp_total; _battle_data.maxhp = _base_data.hp_total;
        _battle_data.mp = _base_data.mp_total; _battle_data.maxmp = _base_data.mp_total;
        _battle_data.atk = _base_data.atk; _battle_data.def = _base_data.def;
        _battle_data.matk = _base_data.matk; _battle_data.mdef = _base_data.mdef;
        _battle_data.spd = _base_data.spd; _battle_data.luk = _base_data.luk;
        _battle_data.level = 1; _battle_data.xp = 0;
        _battle_data.xp_require = (script_exists(scr_GetXPForLevel)) ? scr_GetXPForLevel(2) : 100;
    }

    // Battle-specific state
    _battle_data.skills = _base_data.skills;
    _battle_data.skill_index = 0; _battle_data.item_index = 0;
    _battle_data.is_defending = false; _battle_data.status = "none";

    show_debug_message("  [GetPlayerData] Created battle data for " + _char_key + ": HP " + string(_battle_data.hp) + "/" + string(_battle_data.maxhp) + " | Level " + string(_battle_data.level) + " | XP " + string(_battle_data.xp) + "/" + string(_battle_data.xp_require));

    return _battle_data;
}