/// @function scr_GetXPForLevel(_level)
/// @description Calculates the total XP required to reach a given level.
/// @param {Real} _level The target level.
/// @returns {Real} Total XP needed for that level.
function scr_GetXPForLevel(_level) {
    if (_level <= 1) return 0;
    return floor(100 * power(_level - 1, 1.5));
}


/// @function scr_AddXPToCharacter(_char_key, _xp_gain)
/// @description Adds XP, handles level ups, updates persistent stats in map DIRECTLY,
///              and teaches new spells based on level.
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

    // 2) Fetch struct directly (it's a reference)
    var charStats = ds_map_find_value(global.party_current_stats, _char_key);
    if (!is_struct(charStats)) {
        show_debug_message("  [AddXP] ERROR: No struct for key: " + _char_key);
        return false;
    }

    // --- Log before ---
    show_debug_message("  [AddXP] BEFORE: Lvl=" + string(charStats.level) 
                     + " XP="   + string(charStats.xp) 
                     + "/"       + string(charStats.xp_require));
    try { show_debug_message("    BEFORE Stats: " + json_encode(charStats)); } catch(_) {}

    // 3) Fetch base defaults
    var base = scr_FetchCharacterInfo(_char_key);
    if (!is_struct(base)) {
        show_debug_message("  [AddXP] WARNING: scr_FetchCharacterInfo failed for: " + _char_key);
    }

    // 4) Ensure fields exist
    if (!variable_struct_exists(charStats, "level"))     charStats.level     = base.level     ?? 1;
    if (!variable_struct_exists(charStats, "xp"))        charStats.xp        = base.xp        ?? 0;
    if (!variable_struct_exists(charStats, "xp_require"))charStats.xp_require= base.xp_require?? scr_GetXPForLevel(charStats.level + 1);
    if (!variable_struct_exists(charStats, "maxhp"))     charStats.maxhp     = base.maxhp     ?? 1;
    if (!variable_struct_exists(charStats, "hp"))        charStats.hp        = charStats.maxhp;
    if (!variable_struct_exists(charStats, "maxmp"))     charStats.maxmp     = base.maxmp     ?? 0;
    if (!variable_struct_exists(charStats, "mp"))        charStats.mp        = charStats.maxmp;
    if (!variable_struct_exists(charStats, "atk"))       charStats.atk       = base.atk       ?? 1;
    if (!variable_struct_exists(charStats, "def"))       charStats.def       = base.def       ?? 1;
    if (!variable_struct_exists(charStats, "matk"))      charStats.matk      = base.matk      ?? 1;
    if (!variable_struct_exists(charStats, "mdef"))      charStats.mdef      = base.mdef      ?? 1;
    if (!variable_struct_exists(charStats, "spd"))       charStats.spd       = base.spd       ?? 1;
    if (!variable_struct_exists(charStats, "luk"))       charStats.luk       = base.luk       ?? 1;
    if (!variable_struct_exists(charStats, "skills") 
     || !is_array(charStats.skills)) {
        charStats.skills = [];
    }

    // 3a) Pre‐fetch the spell DB (for learning)
    var spellDB = undefined;
    if (script_exists(scr_BuildSpellDB)) {
        spellDB = scr_BuildSpellDB();
    }

    // 5) Add the XP
    charStats.xp += _xp_gain;
    show_debug_message("  [AddXP] After gain: XP=" + string(charStats.xp) 
                     + "/"        + string(charStats.xp_require));

    // 6) Handle level‐ups
    var leveled_up = false;
    while (charStats.xp_require > 0
        && charStats.xp >= charStats.xp_require) {
        leveled_up = true;
        charStats.level++;
        var newLvl = charStats.level;
        show_debug_message("  >>> LEVEL UP! " + _char_key 
                         + " reached Level " + string(newLvl) + " <<<");

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

        // --- Learn new spells if scheduled ---
        if (is_struct(spellDB)
         && variable_struct_exists(spellDB, "learning_schedule")) {
            var schedMap = variable_struct_get(spellDB, "learning_schedule");
            if (ds_map_exists(schedMap, _char_key)) {
                var charSched = ds_map_find_value(schedMap, _char_key);
                var lvlKey    = string(newLvl);
                if (ds_map_exists(charSched, lvlKey)) {
                    var spellKey = ds_map_find_value(charSched, lvlKey);
                    if (variable_struct_exists(spellDB, spellKey)) {
                        var newSkill = variable_struct_get(spellDB, spellKey);
                        array_push(charStats.skills, newSkill);
                        show_debug_message("    -> Learned new skill: " 
                                         + (newSkill.name ?? spellKey));
                    }
                }
            }
        }

        // Recompute next XP requirement
        charStats.xp_require = scr_GetXPForLevel(newLvl + 1);
        show_debug_message("  [AddXP] New XP requirement: " 
                         + string(charStats.xp_require));
    }

    // --- Log after ---
    show_debug_message("  [AddXP] AFTER: Lvl=" + string(charStats.level) 
                     + " XP="   + string(charStats.xp) 
                     + "/"       + string(charStats.xp_require));
    try { show_debug_message("    AFTER Stats: " + json_encode(charStats)); } catch(_) {}

    return leveled_up;
}
