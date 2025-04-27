/// @function scr_GetXPForLevel(_level)
/// @description Calculates the total XP required to reach a given level.
/// @param {Real} _level The target level.
/// @returns {Real} Total XP needed for that level.
function scr_GetXPForLevel(_level) {
    if (_level <= 1) return 0;
    return floor(100 * power(_level - 1, 1.5));
}


/// @function scr_AddXPToCharacter(_char_key, _xp_gain)
/// @description Adds XP, handles level ups, updates persistent stats in map.
/// @param {String} _char_key Character key.
/// @param {Real}   _xp_gain  XP gained.
/// @returns {Bool} True if level up occurred.
function scr_AddXPToCharacter(_char_key, _xp_gain) {
    show_debug_message("[AddXP] Adding " + string(_xp_gain) + " XP to character: " + _char_key);

    // 1) Validate map
    if (!variable_global_exists("party_current_stats")
     || !ds_exists(global.party_current_stats, ds_type_map)) {
        show_debug_message("  [AddXP] ERROR: party_current_stats map missing");
        return false;
    }

    // 2) Fetch & validate struct directly from map
    var charStats = ds_map_find_value(global.party_current_stats, _char_key);
    if (!is_struct(charStats)) {
        show_debug_message("  [AddXP] ERROR: No struct for key: " + _char_key);
        return false;
    }

    // 3) Fetch base data for defaults
    var base = scr_FetchCharacterInfo(_char_key);
    if (!is_struct(base)) {
        show_debug_message("  [AddXP] ERROR: scr_FetchCharacterInfo failed for: " + _char_key);
        return false;
    }

    // 4) Ensure necessary fields exist
    if (!variable_struct_exists(charStats, "level"))      charStats.level      = 1;
    if (!variable_struct_exists(charStats, "xp"))         charStats.xp         = 0;
    if (!variable_struct_exists(charStats, "xp_require")) charStats.xp_require = scr_GetXPForLevel(charStats.level + 1);

    // Use maxhp/maxmp instead of hp_total/mp_total
    if (!variable_struct_exists(charStats, "maxhp")) charStats.maxhp = base.hp_total  ?? 1;
    if (!variable_struct_exists(charStats, "hp"))    charStats.hp    = charStats.maxhp;
    if (!variable_struct_exists(charStats, "maxmp")) charStats.maxmp = base.mp_total ?? 0;
    if (!variable_struct_exists(charStats, "mp"))    charStats.mp    = charStats.maxmp;

    // Other stats
    if (!variable_struct_exists(charStats, "atk"))  charStats.atk  = base.atk  ?? 1;
    if (!variable_struct_exists(charStats, "def"))  charStats.def  = base.def  ?? 1;
    if (!variable_struct_exists(charStats, "matk")) charStats.matk = base.matk ?? 1;
    if (!variable_struct_exists(charStats, "mdef")) charStats.mdef = base.mdef ?? 1;
    if (!variable_struct_exists(charStats, "spd"))  charStats.spd  = base.spd  ?? 1;
    if (!variable_struct_exists(charStats, "luk"))  charStats.luk  = base.luk  ?? 1;

    if (!variable_struct_exists(charStats, "skills") || !is_array(charStats.skills)) {
        charStats.skills = [];
    }

    // 5) Add the XP
    charStats.xp += _xp_gain;
    show_debug_message("  [AddXP] After gain: XP=" + string(charStats.xp) + "/" + string(charStats.xp_require));

    // 6) Handle level‐ups
    var leveled_up = false;
    while (charStats.xp_require > 0 && charStats.xp >= charStats.xp_require) {
        leveled_up = true;
        charStats.level++;
        var newLvl = charStats.level;
        show_debug_message("  >>> LEVEL UP! " + _char_key + " reached Level " + string(newLvl) + " <<<");

        // Stat increases
        charStats.maxhp += 5 + irandom(2);
        charStats.maxmp += 2 + irandom(1);
        charStats.atk++;
        charStats.def++;
        charStats.matk++;
        charStats.mdef++;
        charStats.spd += (irandom(3) == 0);
        charStats.luk += (irandom(4) == 0);

        // Restore HP/MP
        charStats.hp = charStats.maxhp;
        charStats.mp = charStats.maxmp;

        // Learn spells
        if (variable_global_exists("spell_db")
         && ds_exists(global.spell_db.learning_schedule, ds_type_map)
         && ds_map_exists(global.spell_db.learning_schedule, _char_key)) {
            var sched = ds_map_find_value(global.spell_db.learning_schedule, _char_key);
            if (ds_exists(sched, ds_type_map)) {
                var lvlStr = string(newLvl);
                if (ds_map_exists(sched, lvlStr)) {
                    var spellKey = ds_map_find_value(sched, lvlStr);
                    if (variable_struct_exists(global.spell_db, spellKey)) {
                        var spellData = global.spell_db[$ spellKey];
                        var known = false;
                        for (var i = 0; i < array_length(charStats.skills); i++) {
                            if (is_struct(charStats.skills[i])
                             && charStats.skills[i].name == spellData.name) {
                                known = true;
                                break;
                            }
                        }
                        if (!known) {
                            array_push(charStats.skills, struct_copy(spellData));
                            show_debug_message("    >>> Learned '" + spellData.name + "' <<<");
                        }
                    }
                }
            }
        }

        // Recompute XP requirement
        charStats.xp_require = scr_GetXPForLevel(newLvl + 1);
        show_debug_message("  [AddXP] New XP requirement: " + string(charStats.xp_require));
    }

    show_debug_message("  [AddXP] Final Lvl=" + string(charStats.level) 
                     + ", XP=" + string(charStats.xp) + "/" + string(charStats.xp_require));

    // 7) Replace back into map
    ds_map_replace(global.party_current_stats, _char_key, charStats);

    return leveled_up;
}

