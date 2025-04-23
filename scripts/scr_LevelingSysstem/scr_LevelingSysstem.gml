/// @function scr_GetXPForLevel(_level)
/// @description Calculates the total XP required to reach a given level.
/// @param {Real} _level The target level.
/// @returns {Real} Total XP needed for that level.
function scr_GetXPForLevel(_level) {
    if (_level <= 1) return 0;
    // Using a simpler power curve for demonstration
    return floor(100 * power(_level - 1, 1.5));
}


/// @function scr_AddXPToCharacter(_char_key, _xp_gain)
/// @description Adds XP to a character, handles level ups, and updates persistent stats.
/// @param {String} _char_key The unique key of the character ("hero", "claude", etc.).
/// @param {Real} _xp_gain The amount of XP gained.
function scr_AddXPToCharacter(_char_key, _xp_gain) {
    show_debug_message("[AddXP] Adding " + string(_xp_gain) + " XP to character: " + _char_key);

    var _persistent_stats = undefined;
    var _is_hero = (_char_key == "hero" && instance_exists(obj_player));

    // 1. Find the persistent stats data source
    if (_is_hero) {
        _persistent_stats = obj_player;
    } else if (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) {
        _persistent_stats = ds_map_find_value(global.party_current_stats, _char_key);
        if (!is_struct(_persistent_stats)) {
             show_debug_message("  [AddXP] ERROR: Could not find persistent stats struct for '" + _char_key + "' in global map!");
             return;
        }
    } else {
        show_debug_message("  [AddXP] ERROR: global.party_current_stats map missing!");
        return;
    }

    // Ensure necessary stats exist
    var _base_data_fallback = scr_FetchCharacterInfo(_char_key);
    if (!variable_struct_exists(_persistent_stats, "level")) _persistent_stats.level = 1;
    if (!variable_struct_exists(_persistent_stats, "xp")) _persistent_stats.xp = 0;
    if (!variable_struct_exists(_persistent_stats, "xp_require")) _persistent_stats.xp_require = scr_GetXPForLevel(_persistent_stats.level + 1);
    // Ensure other stats exist for level up calculation
    if (!variable_struct_exists(_persistent_stats, "hp_total")) _persistent_stats.hp_total = _base_data_fallback.hp_total;
    if (!variable_struct_exists(_persistent_stats, "mp_total")) _persistent_stats.mp_total = _base_data_fallback.mp_total;
    if (!variable_struct_exists(_persistent_stats, "atk")) _persistent_stats.atk = _base_data_fallback.atk;
    if (!variable_struct_exists(_persistent_stats, "def")) _persistent_stats.def = _base_data_fallback.def;
    if (!variable_struct_exists(_persistent_stats, "matk")) _persistent_stats.matk = _base_data_fallback.matk;
    if (!variable_struct_exists(_persistent_stats, "mdef")) _persistent_stats.mdef = _base_data_fallback.mdef;
    if (!variable_struct_exists(_persistent_stats, "spd")) _persistent_stats.spd = _base_data_fallback.spd;
    if (!variable_struct_exists(_persistent_stats, "luk")) _persistent_stats.luk = _base_data_fallback.luk;


    // 2. Add XP
    _persistent_stats.xp += _xp_gain;
    show_debug_message("  [AddXP] " + _char_key + " XP after gain: " + string(_persistent_stats.xp) + " / " + string(_persistent_stats.xp_require));

    // 3. Check for Level Up
    var _leveled_up = false;
    // --- FIX: Ensure xp_require is greater than 0 to avoid infinite loop if formula returns 0 ---
    while (_persistent_stats.xp >= _persistent_stats.xp_require && _persistent_stats.xp_require > 0) {
        _leveled_up = true;
        show_debug_message("  [AddXP] LEVEL UP CHECK: XP (" + string(_persistent_stats.xp) + ") >= Req (" + string(_persistent_stats.xp_require) + "). Leveling up!"); // LOG

        _persistent_stats.level++;
        var _leveled_up_to = _persistent_stats.level;
        show_debug_message("  >>> LEVEL UP! " + _char_key + " reached Level " + string(_leveled_up_to) + " <<<");

        // --- Apply Stat Increases (Modify the persistent source directly) ---
        var hp_increase = 5 + irandom(2); var mp_increase = 2 + irandom(1);
        var atk_increase = 1; var def_increase = 1; var matk_increase = 1;
        var mdef_increase = 1; var spd_increase = (irandom(3) == 0) ? 1 : 0;
        var luk_increase = (irandom(4) == 0) ? 1 : 0;

        _persistent_stats.hp_total += hp_increase; _persistent_stats.mp_total += mp_increase;
        _persistent_stats.atk += atk_increase; _persistent_stats.def += def_increase;
        _persistent_stats.matk += matk_increase; _persistent_stats.mdef += mdef_increase;
        _persistent_stats.spd += spd_increase; _persistent_stats.luk += luk_increase;

        // Set current HP/MP to new max (these will be saved back after battle)
        _persistent_stats.hp = _persistent_stats.hp_total;
        _persistent_stats.mp = _persistent_stats.mp_total;

        show_debug_message("    Stats Increased: HP+" + string(hp_increase) + " MP+" + string(mp_increase) + " ATK+" + string(atk_increase) + " DEF+" + string(def_increase) + " ...");

        // --- Calculate XP needed for the *next* level ---
        var _next_level_xp_req = scr_GetXPForLevel(_leveled_up_to + 1);
        show_debug_message("    Previous XP Req: " + string(_persistent_stats.xp_require) + " | Next XP Req: " + string(_next_level_xp_req));
        _persistent_stats.xp_require = _next_level_xp_req;

        // Log values before next loop iteration
        show_debug_message("  [AddXP] End of Level Up Loop Iteration. XP: " + string(_persistent_stats.xp) + " | New Req: " + string(_persistent_stats.xp_require));

    } // End while level up loop

    if (!_leveled_up) {
         show_debug_message("  [AddXP] No level up this time for " + _char_key);
    }
    show_debug_message("  [AddXP] Finished adding XP for " + _char_key + ". Final Level: " + string(_persistent_stats.level) + " XP: " + string(_persistent_stats.xp) + "/" + string(_persistent_stats.xp_require));
}
