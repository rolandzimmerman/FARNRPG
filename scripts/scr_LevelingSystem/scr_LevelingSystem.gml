/// @function scr_GetXPForLevel(_level)
/// @description Calculates the total XP required to reach a given level.
/// @param {Real} _level The target level.
/// @returns {Real} Total XP needed for that level.
function scr_GetXPForLevel(_level) {
    if (_level <= 1) return 0;
    return floor(100 * power(_level - 1, 1.5));
}


/// @function scr_AddXPToCharacter(_char_key, _xp_gain)
/// @description Adds XP to a character, handles level ups, and updates persistent stats.
///             Includes logic to learn new spells upon leveling up.
/// @param {String} _char_key The unique key of the character ("hero", "claude", etc.).
/// @param {Real} _xp_gain The amount of XP gained.
/// @returns {Bool} True if a level up occurred, false otherwise.
function scr_AddXPToCharacter(_char_key, _xp_gain) {
    show_debug_message("[AddXP] Adding " + string(_xp_gain) + " XP to character: " + _char_key);

    var _persistent_stats = undefined;
    var _is_hero = (_char_key == "hero" && instance_exists(obj_player));

    // Find persistent stats source
    if (_is_hero) { _persistent_stats = obj_player; }
    else if (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) {
        _persistent_stats = ds_map_find_value(global.party_current_stats, _char_key);
        if (!is_struct(_persistent_stats)) { show_debug_message("  [AddXP] Error: Persistent stats not found for character: " + _char_key); return false; } // Exit if not found
    } else { show_debug_message("  [AddXP] Error: global.party_current_stats map not found."); return false; } // Exit if map missing

    // Ensure necessary stats exist and initialize if missing (including skills)
    // Fetch base data to use as fallback for initial values if persistent stats are new
    var _base_data_fallback = scr_FetchCharacterInfo(_char_key); // Make sure you have this function
    if (!is_struct(_base_data_fallback)) { show_debug_message("  [AddXP] Error: Base character data not found for: " + _char_key); return false; }

    if (!variable_struct_exists(_persistent_stats, "level")) _persistent_stats.level = 1;
    if (!variable_struct_exists(_persistent_stats, "xp")) _persistent_stats.xp = 0;
    // Calculate initial xp_require based on the character's current level
    if (!variable_struct_exists(_persistent_stats, "xp_require")) _persistent_stats.xp_require = scr_GetXPForLevel(_persistent_stats.level + 1);

    // Initialize basic stats from base data if they don't exist in persistent stats
    if (!variable_struct_exists(_persistent_stats, "hp_total")) _persistent_stats.hp_total = _base_data_fallback.hp_total;
    if (!variable_struct_exists(_persistent_stats, "mp_total")) _persistent_stats.mp_total = _base_data_fallback.mp_total;
    if (!variable_struct_exists(_persistent_stats, "atk"))       _persistent_stats.atk = _base_data_fallback.atk;
    if (!variable_struct_exists(_persistent_stats, "def"))       _persistent_stats.def = _base_data_fallback.def;
    if (!variable_struct_exists(_persistent_stats, "matk"))     _persistent_stats.matk = _base_data_fallback.matk;
    if (!variable_struct_exists(_persistent_stats, "mdef"))     _persistent_stats.mdef = _base_data_fallback.mdef;
    if (!variable_struct_exists(_persistent_stats, "spd"))       _persistent_stats.spd = _base_data_fallback.spd;
    if (!variable_struct_exists(_persistent_stats, "luk"))       _persistent_stats.luk = _base_data_fallback.luk;

    // Initialize current HP/MP to total if they don't exist
    if (!variable_struct_exists(_persistent_stats, "hp")) _persistent_stats.hp = _persistent_stats.hp_total;
    if (!variable_struct_exists(_persistent_stats, "mp")) _persistent_stats.mp = _persistent_stats.mp_total;

    // *** IMPORTANT: Initialize skills array if it doesn't exist ***
    // This ensures characters added to the persistent stats gain their starting skills.
    if (!variable_struct_exists(_persistent_stats, "skills") || !is_array(_persistent_stats.skills)) {
        show_debug_message("  [AddXP] Initializing skills for " + _char_key + " from base data.");
        // Assuming _base_data_fallback has the initial skills defined
        if (variable_struct_exists(_base_data_fallback, "skills") && is_array(_base_data_fallback.skills)) {
            // Deep copy the skill structs to avoid modifying the base data later
            var _initial_skills_copy = [];
            for (var i = 0; i < array_length(_base_data_fallback.skills); ++i) {
                if (is_struct(_base_data_fallback.skills[i])) {
                    array_push(_initial_skills_copy, struct_copy(_base_data_fallback.skills[i]));
                }
            }
            _persistent_stats.skills = _initial_skills_copy;
        } else {
            // If base data doesn't have skills or it's not an array, start with an empty array
            _persistent_stats.skills = [];
            show_debug_message("  [AddXP] Warning: Base data for " + _char_key + " does not contain a 'skills' array. Initializing with empty skills.");
        }
    }


    // Add XP
    _persistent_stats.xp += _xp_gain;
    show_debug_message("  [AddXP] " + _char_key + " XP after gain: " + string(_persistent_stats.xp) + " / " + string(_persistent_stats.xp_require));

    // Check for Level Up
    var leveled_up_this_time = false; // Initialize flag to return
    while (_persistent_stats.xp >= _persistent_stats.xp_require && _persistent_stats.xp_require > 0) {
        leveled_up_this_time = true; // Set flag on level up
        show_debug_message("  [AddXP] LEVEL UP CHECK: XP (" + string(_persistent_stats.xp) + ") >= Req (" + string(_persistent_stats.xp_require) + "). Leveling up!");

        _persistent_stats.level++;
        var _leveled_up_to = _persistent_stats.level;
        show_debug_message("  >>> LEVEL UP! " + _char_key + " reached Level " + string(_leveled_up_to) + " <<<");

        // Apply Stat Increases
        // These are example increases; you might want a more sophisticated system
        var hp_increase = 5 + irandom(2);
        var mp_increase = 2 + irandom(1);
        var atk_increase = 1;
        var def_increase = 1;
        var matk_increase = 1;
        var mdef_increase = 1;
        var spd_increase = (irandom(3) == 0) ? 1 : 0; // Spd doesn't increase every level
        var luk_increase = (irandom(4) == 0) ? 1 : 0; // Luk increases less often

        _persistent_stats.hp_total += hp_increase;
        _persistent_stats.mp_total += mp_increase;
        _persistent_stats.atk += atk_increase;
        _persistent_stats.def += def_increase;
        _persistent_stats.matk += matk_increase;
        _persistent_stats.mdef += mdef_increase;
        _persistent_stats.spd += spd_increase;
        _persistent_stats.luk += luk_increase;

        // Fully restore HP/MP on level up
        _persistent_stats.hp = _persistent_stats.hp_total;
        _persistent_stats.mp = _persistent_stats.mp_total;

        show_debug_message("    Stats Increased: HP+" + string(hp_increase) + " MP+" + string(mp_increase) +
            ". New Stats: HP Total: " + string(_persistent_stats.hp_total) + ", MP Total: " + string(_persistent_stats.mp_total) +
            ", ATK: " + string(_persistent_stats.atk) + ", DEF: " + string(_persistent_stats.def) +
            ", MATK: " + string(_persistent_stats.matk) + ", MDEF: " + string(_persistent_stats.mdef) +
            ", SPD: " + string(_persistent_stats.spd) + ", LUK: " + string(_persistent_stats.luk));


        // --- Check for and Learn New Spells ---
        // Ensure the spell database exists and contains learning schedule for this character
        if (variable_global_exists("spell_db") && is_struct(global.spell_db) &&
            variable_struct_exists(global.spell_db, "learning_schedule") &&
            variable_struct_exists(global.spell_db.learning_schedule, _char_key))
        {
            var _char_learning = global.spell_db.learning_schedule[$ _char_key]; // Use $ to access struct field by variable string

            // Check if the character learns a spell at this specific level
            // Levels in the learning schedule are stored as string keys
            var _level_str = string(_leveled_up_to);
            if (variable_struct_exists(_char_learning, _level_str)) {
                var _spell_id_to_learn = _char_learning[$ _level_str];

                // Find the actual spell data in the spell database
                if (variable_struct_exists(global.spell_db, _spell_id_to_learn) && is_struct(global.spell_db[$ _spell_id_to_learn])) {
                    var _learned_spell_struct = global.spell_db[$ _spell_id_to_learn];

                    // Add the learned spell struct to the character's skills array
                    // Check if the character already knows the skill (optional, prevents duplicates)
                    var _already_knows = false;
                    if (is_array(_persistent_stats.skills)) {
                        for (var i = 0; i < array_length(_persistent_stats.skills); ++i) {
                            // Check if the current skill entry is a struct and has a name field
                            if (is_struct(_persistent_stats.skills[i]) && variable_struct_exists(_persistent_stats.skills[i], "name")) {
                                if (_persistent_stats.skills[i].name == _learned_spell_struct.name) {
                                    _already_knows = true;
                                    break;
                                }
                            }
                        }
                    } else {
                        // If skills wasn't an array, re-initialize it
                        _persistent_stats.skills = [];
                        show_debug_message("    Warning: _persistent_stats.skills was not an array. Re-initializing.");
                    }


                    if (!_already_knows) {
                        // Add the new spell to the skills array
                        array_push(_persistent_stats.skills, struct_copy(_learned_spell_struct)); // Use struct_copy to add a copy!
                        show_debug_message("    >>> " + _char_key + " learned '" + _learned_spell_struct.name + "'! <<<");
                        // You might want to add a visual notification (like a text popup) here
                    } else {
                        show_debug_message("    " + _char_key + " already knows '" + _learned_spell_struct.name + "'.");
                    }
                } else {
                    show_debug_message("⚠️ Spell '" + _spell_id_to_learn + "' not found in global.spell_db!");
                }
            }
        } else {
            // This warning is helpful during development if you forget to set up the spell_db or learning_schedule
            // show_debug_message("    Warning: Spell database or learning schedule missing for " + _char_key + ".");
        }
        // --- End Check for and Learn New Spells ---


        // Calculate XP needed for the *next* level
        var _next_level_xp_req = scr_GetXPForLevel(_leveled_up_to + 1);
        _persistent_stats.xp_require = _next_level_xp_req;

        show_debug_message("  [AddXP] End of Level Up Loop Iteration. XP: " + string(_persistent_stats.xp) + " | New Req: " + string(_persistent_stats.xp_require));

    } // End while level up loop

    if (!leveled_up_this_time) {
         show_debug_message("  [AddXP] No level up this time for " + _char_key);
    }
    show_debug_message("  [AddXP] Finished adding XP for " + _char_key + ". Final Level: " + string(_persistent_stats.level) + " XP: " + string(_persistent_stats.xp) + "/" + string(_persistent_stats.xp_require));

    return leveled_up_this_time; // Return the flag
}

// Note: You will need a function scr_FetchCharacterInfo(_char_key)
// that retrieves the base character struct from your global.character_db.
// Example:
/*
/// @function scr_FetchCharacterInfo(_char_key)
/// @description Fetches the base character data struct from the global database.
/// @param {String} _char_key The unique key of the character.
/// @returns {Struct} The character base data struct, or undefined if not found.
function scr_FetchCharacterInfo(_char_key) {
    if (variable_global_exists("character_db") && ds_exists(global.character_db, ds_type_map)) {
        return ds_map_find_value(global.character_db, _char_key);
    }
    return undefined;
}
*/