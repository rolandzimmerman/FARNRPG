/// @function scr_GetPlayerData(_char_key)
/// @description Returns a battle struct for the character, reading persistent data.
///              Status effect fields are NOT included here. Adds complete final log.
function scr_GetPlayerData(_char_key) {
    show_debug_message("--- scr_GetPlayerData START for key: " + string(_char_key) + " ---");
    var _base = scr_FetchCharacterInfo(_char_key); // Get base definition

    // --- Handle missing base data ---
    if (is_undefined(_base)) {
        show_debug_message("scr_GetPlayerData: Base data undefined for " + string(_char_key) + ". Returning fallback.");
        return { /* Fallback struct */
            character_key:_char_key, name:"(Unknown)", class:"(Unknown)", hp:1, maxhp:1, mp:0, maxmp:0,
            atk:1, def:1, matk:1, mdef:1, spd:1, luk:1, level:1, xp:0, xp_require:100, skills:[],
            skill_index:0, item_index:0, equipment:{ weapon:noone, offhand:noone, armor:noone, helm:noone, accessory:noone },
            is_defending:false, /* No status fields */ battle_sprite:undefined
        };
    }

    // --- 1) Get persistent data source (_pers) ALWAYS from the global map ---
    var _pers = undefined;
    if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) { global.party_current_stats = ds_map_create(); }
    var saved = ds_map_find_value(global.party_current_stats, _char_key);
    show_debug_message(" -> Reading from Map for " + _char_key + ". Found: " + string(saved)); // Log raw map data

    if (is_struct(saved)) {
         _pers = saved;
         // Ensure essential persistent fields exist...
         if (!variable_struct_exists(_pers, "equipment")) { _pers.equipment = { weapon:noone, offhand:noone, armor:noone, helm:noone, accessory:noone }; }
         if (!variable_struct_exists(_pers, "skills") || !is_array(_pers.skills)) { _pers.skills = []; if (variable_struct_exists(_base, "skills") && is_array(_base.skills)) { /* Init skills */ } }
         if (!variable_struct_exists(_pers, "level")) _pers.level = 1; if (!variable_struct_exists(_pers, "xp")) _pers.xp = 0; /* etc */
         if (!variable_struct_exists(_pers, "xp_require")) _pers.xp_require = scr_GetXPForLevel(_pers.level + 1);
    } else { // Initialize NEW persistent stats in map
        show_debug_message("scr_GetPlayerData: Initializing NEW persistent stats in global map for: " + string(_char_key));
        var xp_req = (script_exists(scr_GetXPForLevel)) ? scr_GetXPForLevel(2) : 100;
        var _base_hp = variable_struct_exists(_base,"hp_total")?_base.hp_total:1; var _base_mp = variable_struct_exists(_base,"mp_total")?_base.mp_total:0;
        var new_stats = { hp: _base_hp, maxhp: _base_hp, mp: _base_mp, maxmp: _base_mp, atk: _base.atk??1, def:_base.def??1, matk:_base.matk??1, mdef:_base.mdef??1, spd:_base.spd??1, luk:_base.luk??1, level:1, xp:0, xp_require: xp_req, skills:[], equipment:{ /* default empty */ } };
        if (variable_struct_exists(_base, "skills") && is_array(_base.skills)) { /* copy base skills */ }
        ds_map_add(global.party_current_stats, _char_key, new_stats);
        _pers = new_stats;
    }

    // --- 2) Build the output struct 'd' for battle ---
    var d = {};
    d.character_key = _char_key; d.name = _base.name??"?"; d.class = _base.class??"?";
    if (!is_struct(_pers)) { /* Assign minimal defaults to d */ d.level=1; d.hp=1; /* etc */ d.skills=[]; d.equipment={}; }
    else { // Copy from persistent struct _pers
        d.level      = variable_struct_exists(_pers,"level")      ? _pers.level      : 1;
        d.xp         = variable_struct_exists(_pers,"xp")         ? _pers.xp         : 0;
        d.xp_require = variable_struct_exists(_pers,"xp_require") ? _pers.xp_require : ((script_exists(scr_GetXPForLevel)) ? scr_GetXPForLevel(d.level + 1) : 100);
        d.hp         = variable_struct_exists(_pers,"hp")         ? _pers.hp         : 1;
        d.maxhp      = variable_struct_exists(_pers,"maxhp")      ? _pers.maxhp      : (variable_struct_exists(_pers,"hp_total") ? _pers.hp_total : 1);
        d.mp         = variable_struct_exists(_pers,"mp")         ? _pers.mp         : 0;
        d.maxmp      = variable_struct_exists(_pers,"maxmp")      ? _pers.maxmp      : (variable_struct_exists(_pers,"mp_total") ? _pers.mp_total : 0);
        d.atk        = variable_struct_exists(_pers,"atk")        ? _pers.atk        : 1;
        d.def        = variable_struct_exists(_pers,"def")        ? _pers.def        : 1;
        d.matk       = variable_struct_exists(_pers,"matk")       ? _pers.matk       : 1;
        d.mdef       = variable_struct_exists(_pers,"mdef")       ? _pers.mdef       : 1;
        d.spd        = variable_struct_exists(_pers,"spd")        ? _pers.spd        : 1;
        d.luk        = variable_struct_exists(_pers,"luk")        ? _pers.luk        : 1;
        d.equipment  = _pers.equipment; // Equipment struct reference
    }

    // --- 3) Build FINAL skills list (Base + Learned) ---
    var final_skills = []; var known_skill_names = {};
    if (variable_struct_exists(_pers, "skills") && is_array(_pers.skills)) { for (var i = 0; i < array_length(_pers.skills); i++) { if (is_struct(_pers.skills[i]) && variable_struct_exists(_pers.skills[i], "name")) { var sc = struct_copy(_pers.skills[i]); array_push(final_skills, sc); known_skill_names[$ _pers.skills[i].name] = true; } } }
    var current_level = d.level;
    if (variable_global_exists("spell_db") && is_struct(global.spell_db) && variable_struct_exists(global.spell_db, "learning_schedule") && ds_exists(global.spell_db.learning_schedule, ds_type_map) && ds_map_exists(global.spell_db.learning_schedule, _char_key)) { var _sched_map = ds_map_find_value(global.spell_db.learning_schedule, _char_key); if (ds_exists(_sched_map, ds_type_map)) { for (var lvl = 1; lvl <= current_level; lvl++) { var _lvl_str = string(lvl); if (ds_map_exists(_sched_map, _lvl_str)) { var _skill_key = ds_map_find_value(_sched_map, _lvl_str); if (variable_struct_exists(global.spell_db, _skill_key)) { var _skill_data = global.spell_db[$ _skill_key]; var _skill_name = variable_struct_exists(_skill_data,"name") ? _skill_data.name : "UNKNOWN"; if (!variable_struct_exists(known_skill_names, _skill_name)) { array_push(final_skills, struct_copy(_skill_data)); known_skill_names[$ _skill_name] = true; } } } } } }
    d.skills = final_skills; d.skill_index = 0; d.item_index = 0;

    // --- Other battle-specific properties ---
    d.is_defending = false;
    d.battle_sprite = variable_struct_exists(_base, "battle_sprite") ? _base.battle_sprite : undefined;

    // Final Check Log - Includes Level/XP
    show_debug_message(" -> scr_GetPlayerData Final Check for " + _char_key + ": Lvl=" + string(d.level ?? "N/A") + " XP=" + string(d.xp ?? "N/A") + "/" + string(d.xp_require ?? "N/A") + " HP=" + string(d.hp ?? "N/A") + ", MP=" + string(d.mp ?? "N/A") );

    return d;
}