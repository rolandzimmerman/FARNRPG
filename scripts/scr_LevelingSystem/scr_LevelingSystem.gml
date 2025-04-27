/// @function scr_GetXPForLevel(_level)
/// @description Calculates the total XP required to reach a given level.
/// @param {Real} _level The target level.
/// @returns {Real} Total XP needed for that level.
function scr_GetXPForLevel(_level) {
    if (_level <= 1) return 0;
    return floor(100 * power(_level - 1, 1.5));
}


/// @function scr_AddXPToCharacter(_char_key, _xp_gain)
/// @description Adds XP, handles level ups, updates persistent stats in map. Status is NOT handled here.
/// @param {String} _char_key Character key.
/// @param {Real} _xp_gain XP gained.
/// @returns {Bool} True if level up occurred.
function scr_AddXPToCharacter(_char_key, _xp_gain) {
    show_debug_message("[AddXP] Adding " + string(_xp_gain) + " XP to character: " + _char_key);
    if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) { return false; }
    var _persistent_stats = ds_map_find_value(global.party_current_stats, _char_key);
    if (!is_struct(_persistent_stats)) { return false; }
    var _base_data = scr_FetchCharacterInfo(_char_key);
    if (!is_struct(_base_data)) { return false; }
    // Ensure necessary fields exist
    if (!variable_struct_exists(_persistent_stats, "level")) _persistent_stats.level = 1;
    if (!variable_struct_exists(_persistent_stats, "xp")) _persistent_stats.xp = 0;
    if (!variable_struct_exists(_persistent_stats, "xp_require")) _persistent_stats.xp_require = scr_GetXPForLevel(_persistent_stats.level + 1);
    if (!variable_struct_exists(_persistent_stats, "hp_total")) _persistent_stats.hp_total = _base_data.hp_total ?? 1;
    if (!variable_struct_exists(_persistent_stats, "mp_total")) _persistent_stats.mp_total = _base_data.mp_total ?? 0;
    if (!variable_struct_exists(_persistent_stats, "atk"))    _persistent_stats.atk = _base_data.atk ?? 1;
    if (!variable_struct_exists(_persistent_stats, "def"))    _persistent_stats.def = _base_data.def ?? 1;
    if (!variable_struct_exists(_persistent_stats, "matk"))   _persistent_stats.matk = _base_data.matk ?? 1;
    if (!variable_struct_exists(_persistent_stats, "mdef"))   _persistent_stats.mdef = _base_data.mdef ?? 1;
    if (!variable_struct_exists(_persistent_stats, "spd"))    _persistent_stats.spd = _base_data.spd ?? 1;
    if (!variable_struct_exists(_persistent_stats, "luk"))    _persistent_stats.luk = _base_data.luk ?? 1;
    if (!variable_struct_exists(_persistent_stats, "hp"))     _persistent_stats.hp = _persistent_stats.hp_total;
    if (!variable_struct_exists(_persistent_stats, "mp"))     _persistent_stats.mp = _persistent_stats.mp_total;
    if (!variable_struct_exists(_persistent_stats, "skills") || !is_array(_persistent_stats.skills)) { _persistent_stats.skills = []; }

    // Add XP
    _persistent_stats.xp += _xp_gain;
    show_debug_message("  [AddXP] " + _char_key + " XP after gain: " + string(_persistent_stats.xp) + " / " + string(_persistent_stats.xp_require));

    // Check for Level Up
    var leveled_up_this_time = false;
    while (_persistent_stats.xp_require > 0 && _persistent_stats.xp >= _persistent_stats.xp_require) {
        leveled_up_this_time = true;
        _persistent_stats.level++; var _leveled_up_to = _persistent_stats.level;
        show_debug_message("  >>> LEVEL UP! " + _char_key + " reached Level " + string(_leveled_up_to) + " <<<");
        // Apply Stat Increases...
        var hp_increase = 5 + irandom(2); var mp_increase = 2 + irandom(1); var atk_increase=1; var def_increase=1; var matk_increase=1; var mdef_increase=1; var spd_increase=(irandom(3)==0)?1:0; var luk_increase=(irandom(4)==0)?1:0;
        _persistent_stats.hp_total += hp_increase; _persistent_stats.mp_total += mp_increase; _persistent_stats.atk += atk_increase; _persistent_stats.def += def_increase; _persistent_stats.matk += matk_increase; _persistent_stats.mdef += mdef_increase; _persistent_stats.spd += spd_increase; _persistent_stats.luk += luk_increase;
        // Restore HP/MP...
        _persistent_stats.hp = _persistent_stats.hp_total; _persistent_stats.mp = _persistent_stats.mp_total;
        // Learn New Spells...
        if (variable_global_exists("spell_db") && /* check map */ ds_map_exists(global.spell_db.learning_schedule, _char_key)) { var _sched = ds_map_find_value(global.spell_db.learning_schedule, _char_key); if(ds_exists(_sched, ds_type_map)) { var _lvl_str=string(_leveled_up_to); if(ds_map_exists(_sched, _lvl_str)){ var _key=ds_map_find_value(_sched, _lvl_str); if(variable_struct_exists(global.spell_db, _key)){ var _spell=global.spell_db[$ _key]; var _known=false; for(var j=0;j<array_length(_persistent_stats.skills);j++){if(is_struct(_persistent_stats.skills[j]) && _persistent_stats.skills[j].name == _spell.name){_known=true;break;}} if(!_known){array_push(_persistent_stats.skills, struct_copy(_spell)); show_debug_message("    >>> " + _char_key + " learned '" + _spell.name + "'! <<<");} } } } }
        // Calculate Next XP Req...
        _persistent_stats.xp_require = scr_GetXPForLevel(_leveled_up_to + 1);
        show_debug_message("  [AddXP] New XP Requirement: " + string(_persistent_stats.xp_require));
    } // End while loop
    show_debug_message("  [AddXP] Finished. Final Level: " + string(_persistent_stats.level) + ", XP: " + string(_persistent_stats.xp) + "/" + string(_persistent_stats.xp_require));
    return leveled_up_this_time;
}