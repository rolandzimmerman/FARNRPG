/// @function scr_CalculateEquippedStats(_base_stats)
/// @description Takes a character's base stats (from scr_GetPlayerData),
/// applies equipment bonuses, and returns the final battle stats struct.
function scr_CalculateEquippedStats(_base_stats) {
    // 1) Copy base stats into a new struct
    var final_stats = {
        character_key: _base_stats.character_key,
        name:          _base_stats.name,
        battle_sprite: _base_stats.battle_sprite,
        level:         _base_stats.level,
        xp:            _base_stats.xp,
        xp_require:    _base_stats.xp_require,

        // current HP/MP
        hp:            _base_stats.hp,
        mp:            _base_stats.mp,
        // max HP/MP
        maxhp:         _base_stats.maxhp,
        maxmp:         _base_stats.maxmp,

        // primary stats
        atk:           _base_stats.atk,
        def:           _base_stats.def,
        matk:          _base_stats.matk,
        mdef:          _base_stats.mdef,
        spd:           _base_stats.spd,
        luk:           _base_stats.luk,

        skills:        _base_stats.skills,
        equipment:     _base_stats.equipment,  // copy reference
        is_defending:  _base_stats.is_defending,
        status:        _base_stats.status
    };

    // 2) If there's no equipment struct, just return
    if (!variable_struct_exists(_base_stats, "equipment") || !is_struct(_base_stats.equipment)) {
        return final_stats;
    }

    // 3) Accumulate bonuses
    var bonus_maxhp = 0, bonus_maxmp = 0;
    var bonus_atk   = 0, bonus_def   = 0;
    var bonus_matk  = 0, bonus_mdef  = 0;
    var bonus_spd   = 0, bonus_luk   = 0;

    var slots = ["weapon","offhand","armor","helm","accessory"];
    for (var i = 0; i < array_length(slots); i++) {
        var slot = slots[i];
        if (variable_struct_exists(_base_stats.equipment, slot)) {
            // Safely read the field from the struct
            var item_key = variable_struct_get(_base_stats.equipment, slot);
            // Only proceed if it's a valid string key
            if (is_string(item_key)
                && variable_global_exists("item_database")
                && ds_exists(global.item_database, ds_type_map)
            ) {
                var item = scr_GetItemData(item_key);
                if (is_struct(item) && variable_struct_exists(item, "bonuses")) {
                    var b = item.bonuses;
                    if (variable_struct_exists(b, "hp_total")) bonus_maxhp += b.hp_total;
                    if (variable_struct_exists(b, "mp_total")) bonus_maxmp += b.mp_total;
                    if (variable_struct_exists(b, "atk"))      bonus_atk   += b.atk;
                    if (variable_struct_exists(b, "def"))      bonus_def   += b.def;
                    if (variable_struct_exists(b, "matk"))     bonus_matk  += b.matk;
                    if (variable_struct_exists(b, "mdef"))     bonus_mdef  += b.mdef;
                    if (variable_struct_exists(b, "spd"))      bonus_spd   += b.spd;
                    if (variable_struct_exists(b, "luk"))      bonus_luk   += b.luk;
                }
            }
        }
    }

    // 4) Apply bonuses to final_stats
    final_stats.maxhp += bonus_maxhp;
    final_stats.maxmp += bonus_maxmp;
    final_stats.atk   += bonus_atk;
    final_stats.def   += bonus_def;
    final_stats.matk  += bonus_matk;
    final_stats.mdef  += bonus_mdef;
    final_stats.spd   += bonus_spd;
    final_stats.luk   += bonus_luk;

    // Ensure current HP/MP do not exceed new maxima
    final_stats.hp = min(final_stats.hp, final_stats.maxhp);
    final_stats.mp = min(final_stats.mp, final_stats.maxmp);

    return final_stats;
}
