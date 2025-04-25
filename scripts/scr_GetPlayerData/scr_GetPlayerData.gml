/// @function scr_GetPlayerData(_char_key)
/// @description Returns a battle struct for the character, with `equipment`.
function scr_GetPlayerData(_char_key) {
    var _base = scr_FetchCharacterInfo(_char_key);
    if (is_undefined(_base)) {
        // fallback empty
        return {
            character_key:_char_key, name:"(Unknown)",
            hp:0,   maxhp:0,
            mp:0,   maxmp:0,
            atk:0,  def:0,
            matk:0, mdef:0,
            spd:0,  luk:0,
            level:1, xp:0, xp_require:0,
            skills:[], skill_index:0, item_index:0,
            equipment:{
                weapon:noone, offhand:noone,
                armor:noone,  helm:noone,
                accessory:noone
            },
            is_defending:false,
            status:"none",
            battle_sprite:undefined
        };
    }

    // --- 1) persistent source (`obj_player` or your global map) ---
    var _pers;
    if (_char_key == "hero" && instance_exists(obj_player)) {
        _pers = obj_player;
    } else {
        if (!variable_global_exists("party_current_stats") 
            || !ds_exists(global.party_current_stats, ds_type_map)) {
            global.party_current_stats = ds_map_create();
        }
        var saved = ds_map_find_value(global.party_current_stats, _char_key);
        if (is_struct(saved)) {
            _pers = saved;
        } else {
            // initialize new
            var xp_req = scr_GetXPForLevel(2);
            var sk = [];
            if (variable_struct_exists(_base, "skills") && is_array(_base.skills)) {
                for (var i = 0; i < array_length(_base.skills); i++) {
                    if (is_struct(_base.skills[i]))
                        array_push(sk, struct_copy(_base.skills[i]));
                }
            }
            var new_stats = {
                hp: _base.hp_total,   maxhp: _base.hp_total,
                mp: _base.mp_total,   maxmp: _base.mp_total,
                atk:_base.atk,        def:_base.def,
                matk:_base.matk,      mdef:_base.mdef,
                spd:_base.spd,        luk:_base.luk,
                level:1, xp:0, xp_require: xp_req,
                skills:sk,
                equipment:{
                    weapon:noone, offhand:noone,
                    armor:noone,  helm:noone,
                    accessory:noone
                }
            };
            ds_map_add(global.party_current_stats, _char_key, new_stats);
            _pers = new_stats;
        }
    }

    // --- 2) build the output struct ---
    var d = {};
    d.character_key = _char_key;
    d.name          = _base.name;

    d.hp    = variable_struct_exists(_pers,"hp")       ? _pers.hp      : _base.hp_total;
    d.maxhp = variable_struct_exists(_pers,"maxhp")    ? _pers.maxhp   : _base.hp_total;
    d.mp    = variable_struct_exists(_pers,"mp")       ? _pers.mp      : _base.mp_total;
    d.maxmp = variable_struct_exists(_pers,"maxmp")    ? _pers.maxmp   : _base.mp_total;

    d.atk   = variable_struct_exists(_pers,"atk")      ? _pers.atk     : _base.atk;
    d.def   = variable_struct_exists(_pers,"def")      ? _pers.def     : _base.def;
    d.matk  = variable_struct_exists(_pers,"matk")     ? _pers.matk    : _base.matk;
    d.mdef  = variable_struct_exists(_pers,"mdef")     ? _pers.mdef    : _base.mdef;
    d.spd   = variable_struct_exists(_pers,"spd")      ? _pers.spd     : _base.spd;
    d.luk   = variable_struct_exists(_pers,"luk")      ? _pers.luk     : _base.luk;

    d.level     = variable_struct_exists(_pers,"level")     ? _pers.level     : 1;
    d.xp        = variable_struct_exists(_pers,"xp")        ? _pers.xp        : 0;
    d.xp_require= variable_struct_exists(_pers,"xp_require")? _pers.xp_require: scr_GetXPForLevel(d.level+1);

    // --- 3) learned skills (unchanged) ---
    var s = [], cur = d.level;
    if (variable_global_exists("spell_db") && is_struct(global.spell_db)
     && ds_exists(global.spell_db.learning_schedule, ds_type_map)
     && ds_map_exists(global.spell_db.learning_schedule, _char_key))
    {
        var sched = ds_map_find_value(global.spell_db.learning_schedule, _char_key);
        if (ds_exists(sched, ds_type_map)) {
            for (var L = 1; L <= cur; L++) {
                var k = string(L);
                if (ds_map_exists(sched, k)) {
                    var skey = ds_map_find_value(sched, k);
                    if (variable_struct_exists(global.spell_db, skey))
                        array_push(s, struct_copy(variable_struct_get(global.spell_db, skey)));
                }
            }
        }
    }
    d.skills     = s;
    d.skill_index= 0;
    d.item_index = 0;

    // --- 4) equipment copy from persistent ---
    if (variable_struct_exists(_pers,"equipment") && is_struct(_pers.equipment)) {
        d.equipment = _pers.equipment;
    } else {
        d.equipment = {
            weapon:noone, offhand:noone,
            armor:noone,  helm:noone,
            accessory:noone
        };
        if (_pers != _base) _pers.equipment = d.equipment;
    }

    d.is_defending = false;
    d.status       = "none";
    d.battle_sprite= _base.battle_sprite; // from your character DB

    return d;
}
