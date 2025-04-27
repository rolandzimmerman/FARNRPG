/// @function scr_CalculateEquippedStats(_base_stats)
/// @description Takes a character's data struct (from scr_GetPlayerData),
///              applies equipment bonuses, and returns the final battle stats struct.
///              Uses older syntax (variable_struct_exists) for compatibility.
/// @param {Struct} _base_stats The data struct returned by scr_GetPlayerData.
function scr_CalculateEquippedStats(_base_stats) {
    // 1) Initial check
    if (!is_struct(_base_stats)) {
        show_debug_message("ERROR [scr_CalculateEquippedStats]: Input '_base_stats' is not a struct!");
        return { hp:1, maxhp:1, mp:0, maxmp:0, atk:1, def:1, matk:1, mdef:1, spd:1, luk:1, level:1, name:"ERR", class:"ERR", skills:[], equipment:{}, is_defending:false, status:"none", character_key:"error", battle_sprite:undefined, xp:0, xp_require:100 };
    }

    // 2) Copy base stats safely into a new struct
    var final_stats = {};
    final_stats.character_key = variable_struct_exists(_base_stats, "character_key") ? _base_stats.character_key : "unknown";
    final_stats.name          = variable_struct_exists(_base_stats, "name")          ? _base_stats.name          : "Unknown";
    final_stats.class         = variable_struct_exists(_base_stats, "class")         ? _base_stats.class         : "Unknown";
    final_stats.battle_sprite = variable_struct_exists(_base_stats, "battle_sprite") ? _base_stats.battle_sprite : undefined;
    final_stats.level         = variable_struct_exists(_base_stats, "level")         ? _base_stats.level         : 1;
    final_stats.xp            = variable_struct_exists(_base_stats, "xp")            ? _base_stats.xp            : 0;
    final_stats.xp_require    = variable_struct_exists(_base_stats, "xp_require")    ? _base_stats.xp_require    : 100;
    final_stats.hp            = variable_struct_exists(_base_stats, "hp")            ? _base_stats.hp            : 1;
    final_stats.mp            = variable_struct_exists(_base_stats, "mp")            ? _base_stats.mp            : 0;
    final_stats.maxhp         = variable_struct_exists(_base_stats, "maxhp")         ? _base_stats.maxhp         : 1;
    final_stats.maxmp         = variable_struct_exists(_base_stats, "maxmp")         ? _base_stats.maxmp         : 0;
    final_stats.atk           = variable_struct_exists(_base_stats, "atk")           ? _base_stats.atk           : 1;
    final_stats.def           = variable_struct_exists(_base_stats, "def")           ? _base_stats.def           : 1;
    final_stats.matk          = variable_struct_exists(_base_stats, "matk")          ? _base_stats.matk          : 1;
    final_stats.mdef          = variable_struct_exists(_base_stats, "mdef")          ? _base_stats.mdef          : 1;
    final_stats.spd           = variable_struct_exists(_base_stats, "spd")           ? _base_stats.spd           : 1;
    final_stats.luk           = variable_struct_exists(_base_stats, "luk")           ? _base_stats.luk           : 1;
    if (variable_struct_exists(_base_stats, "skills") && is_array(_base_stats.skills)) { final_stats.skills = _base_stats.skills; } else { final_stats.skills = []; }
    if (variable_struct_exists(_base_stats, "equipment") && is_struct(_base_stats.equipment)) { final_stats.equipment = _base_stats.equipment; } else { final_stats.equipment = { weapon:noone, offhand:noone, armor:noone, helm:noone, accessory:noone }; }
    final_stats.is_defending  = variable_struct_exists(_base_stats, "is_defending")  ? _base_stats.is_defending  : false;
    // Status is no longer part of this data struct, it's an instance variable on the battler

    // 3) Accumulate bonuses from equipment
    if (!is_struct(final_stats.equipment)) { return final_stats; }
    var bonus_maxhp = 0, bonus_maxmp = 0, bonus_atk = 0, bonus_def = 0; var bonus_matk = 0, bonus_mdef = 0, bonus_spd = 0, bonus_luk = 0;
    var slots = ["weapon","offhand","armor","helm","accessory"];
    for (var i = 0; i < array_length(slots); i++) {
        var slot = slots[i]; if (variable_struct_exists(final_stats.equipment, slot)) { var item_key = variable_struct_get(final_stats.equipment, slot);
            if (is_string(item_key) && item_key != "noone") { if (variable_global_exists("item_database") && ds_exists(global.item_database, ds_type_map)) { var item = scr_GetItemData(item_key); if (is_struct(item) && variable_struct_exists(item, "bonuses") && is_struct(item.bonuses)) { var b = item.bonuses; bonus_maxhp += variable_struct_exists(b, "hp_total") ? b.hp_total : 0; bonus_maxmp += variable_struct_exists(b, "mp_total") ? b.mp_total : 0; bonus_atk += variable_struct_exists(b, "atk") ? b.atk : 0; bonus_def += variable_struct_exists(b, "def") ? b.def : 0; bonus_matk += variable_struct_exists(b, "matk") ? b.matk : 0; bonus_mdef += variable_struct_exists(b, "mdef") ? b.mdef : 0; bonus_spd += variable_struct_exists(b, "spd") ? b.spd : 0; bonus_luk += variable_struct_exists(b, "luk") ? b.luk : 0; } } } }
    }

    // 4) Apply bonuses
    final_stats.maxhp += bonus_maxhp; final_stats.maxmp += bonus_maxmp; final_stats.atk += bonus_atk; final_stats.def += bonus_def; final_stats.matk += bonus_matk; final_stats.mdef += bonus_mdef; final_stats.spd += bonus_spd; final_stats.luk += bonus_luk;

    // 5) Clamp values
    final_stats.hp = max(0, min(final_stats.hp, final_stats.maxhp)); final_stats.mp = max(0, min(final_stats.mp, final_stats.maxmp));
    final_stats.atk = max(0, final_stats.atk); final_stats.def = max(0, final_stats.def); final_stats.matk= max(0, final_stats.matk); final_stats.mdef= max(0, final_stats.mdef); final_stats.spd = max(0, final_stats.spd); final_stats.luk = max(0, final_stats.luk);

    return final_stats;
}