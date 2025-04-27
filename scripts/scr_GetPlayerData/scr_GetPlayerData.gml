/// @function scr_GetPlayerData(_char_key)
/// @description Returns a battle struct for the character, reading persistent data,
///              now including Overdrive fields (current and max).
/// @param {String} _char_key Character key.
/// @returns {Struct} Battle data struct.
function scr_GetPlayerData(_char_key) {
    show_debug_message("--- scr_GetPlayerData START for key: " + string(_char_key) + " ---");
    
    // 1) Fetch base definition
    var _base = scr_FetchCharacterInfo(_char_key);
    if (!is_struct(_base)) {
        // Fallback minimal struct
        return {
            character_key:_char_key,
            name:"(Unknown)",
            hp:1, maxhp:1,
            mp:0, maxmp:0,
            atk:1, def:1, matk:1, mdef:1, spd:1, luk:1,
            level:1, xp:0, xp_require:100,
            skills:[], skill_index:0, item_index:0,
            equipment:{weapon:noone,offhand:noone,armor:noone,helm:noone,accessory:noone},
            is_defending:false,
            overdrive:0, overdrive_max:100,
            battle_sprite:undefined
        };
    }
    
    // 2) Ensure the persistent map exists
    if (!variable_global_exists("party_current_stats") 
     || !ds_exists(global.party_current_stats, ds_type_map)) {
        global.party_current_stats = ds_map_create();
    }
    
    // 3) Retrieve or initialize the persistent stats struct
    var _pers;
    if (ds_map_exists(global.party_current_stats, _char_key)) {
        _pers = ds_map_find_value(global.party_current_stats, _char_key);
        // Add missing fields if needed
        if (!variable_struct_exists(_pers, "overdrive"))     _pers.overdrive     = 0;
        if (!variable_struct_exists(_pers, "overdrive_max")) _pers.overdrive_max = 100;
    } else {
        // First-time initialization
        var xp_req = script_exists(scr_GetXPForLevel)
                   ? scr_GetXPForLevel(2)
                   : 100;
        var baseHP = variable_struct_exists(_base, "hp_total")
                   ? _base.hp_total : 1;
        var baseMP = variable_struct_exists(_base, "mp_total")
                   ? _base.mp_total : 0;
        _pers = {
            hp: baseHP,
            maxhp: baseHP,
            mp: baseMP,
            maxmp: baseMP,
            atk: _base.atk  ?? 1,
            def: _base.def  ?? 1,
            matk:_base.matk ?? 1,
            mdef:_base.mdef ?? 1,
            spd: _base.spd  ?? 1,
            luk: _base.luk  ?? 1,
            level: 1,
            xp: 0,
            xp_require: xp_req,
            skills: [],
            equipment: {weapon:noone,offhand:noone,armor:noone,helm:noone,accessory:noone},
            overdrive: 0,
            overdrive_max: 100
        };
        ds_map_add(global.party_current_stats, _char_key, _pers);
    }
    
    // 4) Build the battle-time struct
    var d = {};
    d.character_key = _char_key;
    d.name          = _base.name  ?? "?";
    d.class         = _base.class ?? "?";
    
    // Copy core stats from persistent struct
    d.level       = _pers.level;
    d.xp          = _pers.xp;
    d.xp_require  = _pers.xp_require;
    d.hp          = _pers.hp;
    d.maxhp       = _pers.maxhp;
    d.mp          = _pers.mp;
    d.maxmp       = _pers.maxmp;
    d.atk         = _pers.atk;
    d.def         = _pers.def;
    d.matk        = _pers.matk;
    d.mdef        = _pers.mdef;
    d.spd         = _pers.spd;
    d.luk         = _pers.luk;
    d.equipment   = _pers.equipment;  // reference
    
    // Copy overdrive fields
    d.overdrive      = _pers.overdrive;
    d.overdrive_max  = _pers.overdrive_max;
    
    // Deep-copy skills array
    var sk_arr = [];
    for (var i = 0; i < array_length(_pers.skills); i++) {
        if (is_struct(_pers.skills[i])) {
            array_push(sk_arr, struct_copy(_pers.skills[i]));
        }
    }
    d.skills      = sk_arr;
    d.skill_index = 0;
    d.item_index  = 0;
    
    // Other battle flags
    d.is_defending  = false;
    d.battle_sprite = _base.battle_sprite;
    
    show_debug_message(
        " -> scr_GetPlayerData FINAL for " + _char_key +
        ": Lvl=" + string(d.level) +
        " XP=" + string(d.xp) + "/" + string(d.xp_require) +
        " OD=" + string(d.overdrive) + "/" + string(d.overdrive_max)
    );
    return d;
}
