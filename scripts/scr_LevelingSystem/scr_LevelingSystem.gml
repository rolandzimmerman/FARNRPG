/// @function scr_GetXPForLevel(_level)
/// @description Calculates the total XP required to reach a given level.
/// @param {Real} _level The target level.
/// @returns {Real} Total XP needed for that level.
function scr_GetXPForLevel(_level) {
    if (_level <= 1) return 0;
    return floor(100 * power(_level - 1, 1.5));
}


/// @function scr_AddXPToCharacter(_char_key, _xp_gain)
/// @description Adds XP, handles level ups, updates persistent stats in map DIRECTLY.
/// @param {String} _char_key Character key.
/// @param {Real}   _xp_gain  XP gained.
/// @returns {Bool} True if level up occurred.
function scr_AddXPToCharacter(_char_key, _xp_gain) {
    show_debug_message("[AddXP] Adding " + string(_xp_gain) + " XP to character: " + _char_key);

    // 1) Validate map
    if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) {
        show_debug_message("  [AddXP] ERROR: party_current_stats map missing");
        return false;
    }

    // 2) Fetch struct DIRECTLY from map (SHOULD be a reference)
    var charStats = ds_map_find_value(global.party_current_stats, _char_key);
    if (!is_struct(charStats)) {
        show_debug_message("  [AddXP] ERROR: No struct for key: " + _char_key);
        return false;
    }
    
    // <<< Log state BEFORE modification >>>
    show_debug_message("  [AddXP] BEFORE Data for " + _char_key + ": Lvl=" + string(charStats.level) + " XP=" + string(charStats.xp) + "/" + string(charStats.xp_require));
    try { show_debug_message("    BEFORE Stats: " + json_encode(charStats));} catch(_e){}

    // 3) Fetch base data for defaults (only needed for skill learning maybe?)
    var base = scr_FetchCharacterInfo(_char_key);
    if (!is_struct(base)) { show_debug_message("  [AddXP] WARNING: scr_FetchCharacterInfo failed for: " + _char_key); }

    // 4) Ensure necessary fields exist (using defaults from BASE if missing in charStats)
    if (!variable_struct_exists(charStats, "level")) charStats.level = base.level ?? 1;
    if (!variable_struct_exists(charStats, "xp")) charStats.xp = base.xp ?? 0;
    if (!variable_struct_exists(charStats, "xp_require")) charStats.xp_require = base.xp_require ?? scr_GetXPForLevel(charStats.level + 1);
    if (!variable_struct_exists(charStats, "maxhp")) charStats.maxhp = base.maxhp ?? 1;
    if (!variable_struct_exists(charStats, "hp")) charStats.hp = charStats.maxhp; // Start HP at current max if missing
    if (!variable_struct_exists(charStats, "maxmp")) charStats.maxmp = base.maxmp ?? 0;
    if (!variable_struct_exists(charStats, "mp")) charStats.mp = charStats.maxmp; // Start MP at current max if missing
    if (!variable_struct_exists(charStats, "atk")) charStats.atk = base.atk ?? 1;
    if (!variable_struct_exists(charStats, "def")) charStats.def = base.def ?? 1;
    if (!variable_struct_exists(charStats, "matk")) charStats.matk = base.matk ?? 1;
    if (!variable_struct_exists(charStats, "mdef")) charStats.mdef = base.mdef ?? 1;
    if (!variable_struct_exists(charStats, "spd")) charStats.spd = base.spd ?? 1;
    if (!variable_struct_exists(charStats, "luk")) charStats.luk = base.luk ?? 1;
    if (!variable_struct_exists(charStats, "skills") || !is_array(charStats.skills)) { charStats.skills = []; }

    // 5) Add the XP
    charStats.xp += _xp_gain;
    show_debug_message("  [AddXP] After gain: XP=" + string(charStats.xp) + "/" + string(charStats.xp_require));

    // 6) Handle level-ups
    var leveled_up = false;
    while (variable_struct_exists(charStats,"xp_require") && charStats.xp_require > 0 && variable_struct_exists(charStats,"xp") && charStats.xp >= charStats.xp_require) {
        leveled_up = true;
        charStats.level++;
        var newLvl = charStats.level;
        show_debug_message("  >>> LEVEL UP! " + _char_key + " reached Level " + string(newLvl) + " <<<");

        // Stat increases (Modify DIRECTLY on charStats struct)
        charStats.maxhp += 5 + irandom(2);
        charStats.maxmp += 2 + irandom(1);
        charStats.atk++; charStats.def++; charStats.matk++; charStats.mdef++;
        charStats.spd += (irandom(3) == 0);
        charStats.luk += (irandom(4) == 0);

        // Restore HP/MP
        charStats.hp = charStats.maxhp; charStats.mp = charStats.maxmp;

        // Learn spells (Your existing logic seems okay)
        /* ... Check schedule, add skill to charStats.skills array ... */
        
        // Recompute XP requirement
        charStats.xp_require = scr_GetXPForLevel(newLvl + 1);
        show_debug_message("  [AddXP] New XP requirement: " + string(charStats.xp_require));
    }

    // <<< Log state AFTER modification >>>
    show_debug_message("  [AddXP] AFTER Data for " + _char_key + ": Lvl=" + string(charStats.level) + " XP=" + string(charStats.xp) + "/" + string(charStats.xp_require));
     try { show_debug_message("    AFTER Stats: " + json_encode(charStats));} catch(_e){}

    // 7) Replace back into map - REMOVED - Should not be necessary if charStats is a reference
    // ds_map_replace(global.party_current_stats, _char_key, charStats); // <<< REMOVED >>>

    return leveled_up;
}