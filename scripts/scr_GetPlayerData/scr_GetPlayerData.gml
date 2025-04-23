/// @function scr_GetPlayerData(_char_key)
/// @description Creates a struct containing current battle stats for a given character key.
function scr_GetPlayerData(_char_key) {

    var _base_data = scr_FetchCharacterInfo(_char_key);
    if (is_undefined(_base_data)) { return { /* Default minimal data */ }; }

    // --- Get Current Persistent Stats ---
    var _current_hp = _base_data.hp_total;
    var _current_mp = _base_data.mp_total;
    var _current_level = 1;
    var _current_xp = 0;

    if (_char_key == "hero" && instance_exists(obj_player)) {
        // Get from obj_player
        if (variable_instance_exists(obj_player, "hp")) _current_hp = obj_player.hp;
        if (variable_instance_exists(obj_player, "mp")) _current_mp = obj_player.mp;
        if (variable_instance_exists(obj_player, "level")) _current_level = obj_player.level;
        if (variable_instance_exists(obj_player, "xp")) _current_xp = obj_player.xp;
    } else {
        // --- Get from global map for other characters ---
        if (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) {
            var _saved_stats = ds_map_find_value(global.party_current_stats, _char_key);
            if (is_struct(_saved_stats)) {
                // Found saved stats, use them if they exist
                if (variable_struct_exists(_saved_stats, "hp")) _current_hp = _saved_stats.hp;
                if (variable_struct_exists(_saved_stats, "mp")) _current_mp = _saved_stats.mp;
                if (variable_struct_exists(_saved_stats, "level")) _current_level = _saved_stats.level;
                if (variable_struct_exists(_saved_stats, "xp")) _current_xp = _saved_stats.xp;
                show_debug_message("  Loaded current stats for " + _char_key + " from global map.");
            } else {
                // No saved stats for this char yet, initialize in global map using base stats
                show_debug_message("  No current stats found for " + _char_key + ". Initializing in global map.");
                var _new_stats_entry = {
                    hp: _base_data.hp_total,
                    mp: _base_data.mp_total,
                    level: 1, // Assuming they join at level 1
                    xp: 0
                    // Add other persistent stats if needed
                };
                ds_map_add(global.party_current_stats, _char_key, _new_stats_entry);
            }
        } else { show_debug_message("  WARNING: global.party_current_stats map missing!"); }
        // --- End Get from global map ---
    }

    // --- Construct Battle Data Struct ---
    return {
        character_key: _char_key, name: _base_data.name,
        hp: _current_hp, maxhp: _base_data.hp_total, mp: _current_mp, maxmp: _base_data.mp_total,
        atk: _base_data.atk, def: _base_data.def, matk: _base_data.matk, mdef: _base_data.mdef,
        spd: _base_data.spd, luk: _base_data.luk, level: _current_level, xp: _current_xp,
        skills: _base_data.skills, skill_index: 0, item_index: 0, is_defending: false, status: "none"
    };
}