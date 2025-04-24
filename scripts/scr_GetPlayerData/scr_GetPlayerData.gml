/// @function scr_GetPlayerData(_char_key)
/// @description Returns a battle-ready stat struct for a character, including learned spells.
/// @param {string} _char_key

function scr_GetPlayerData(_char_key) {
    var _base_data = scr_FetchCharacterInfo(_char_key);
    if (is_undefined(_base_data)) {
        return {
            character_key: _char_key,
            name: "(Unknown)",
            hp: 0, maxhp: 0, mp: 0, maxmp: 0,
            atk: 0, def: 0, matk: 0, mdef: 0,
            spd: 0, luk: 0,
            level: 1, xp: 0, xp_require: 0,
            skills: [], skill_index: 0, item_index: 0,
            is_defending: false, status: "none"
        };
    }

    var _persistent = undefined;

    if (_char_key == "hero" && instance_exists(obj_player)) {
        _persistent = obj_player;
    } else if (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) {
        var saved = ds_map_find_value(global.party_current_stats, _char_key);
        if (is_struct(saved)) {
            _persistent = saved;
        } else {
            var xp_req = script_exists(scr_GetXPForLevel) ? scr_GetXPForLevel(2) : 100;
            var new_stats = {
                hp: _base_data.hp_total, hp_total: _base_data.hp_total,
                mp: _base_data.mp_total, mp_total: _base_data.mp_total,
                level: 1, xp: 0, xp_require: xp_req,
                atk: _base_data.atk, def: _base_data.def,
                matk: _base_data.matk, mdef: _base_data.mdef,
                spd: _base_data.spd, luk: _base_data.luk
            };
            ds_map_add(global.party_current_stats, _char_key, new_stats);
            _persistent = new_stats;
        }
    } else {
        _persistent = _base_data;
    }

    var d = {};
    d.character_key = _char_key;
    d.name = _base_data.name;
    d.hp = variable_struct_exists(_persistent, "hp") ? _persistent.hp : _base_data.hp_total;
    d.maxhp = variable_struct_exists(_persistent, "hp_total") ? _persistent.hp_total : _base_data.hp_total;
    d.mp = variable_struct_exists(_persistent, "mp") ? _persistent.mp : _base_data.mp_total;
    d.maxmp = variable_struct_exists(_persistent, "mp_total") ? _persistent.mp_total : _base_data.mp_total;
    d.atk = variable_struct_exists(_persistent, "atk") ? _persistent.atk : _base_data.atk;
    d.def = variable_struct_exists(_persistent, "def") ? _persistent.def : _base_data.def;
    d.matk = variable_struct_exists(_persistent, "matk") ? _persistent.matk : _base_data.matk;
    d.mdef = variable_struct_exists(_persistent, "mdef") ? _persistent.mdef : _base_data.mdef;
    d.spd = variable_struct_exists(_persistent, "spd") ? _persistent.spd : _base_data.spd;
    d.luk = variable_struct_exists(_persistent, "luk") ? _persistent.luk : _base_data.luk;
    d.level = variable_struct_exists(_persistent, "level") ? _persistent.level : 1;
    d.xp = variable_struct_exists(_persistent, "xp") ? _persistent.xp : 0;
    d.xp_require = variable_struct_exists(_persistent, "xp_require")
        ? _persistent.xp_require
        : (script_exists(scr_GetXPForLevel) ? scr_GetXPForLevel(d.level + 1) : 100);

    // --- Spell learning ---
    var s = [];
    var current_level = d.level;

    if (
        variable_global_exists("spell_db") &&
        is_struct(global.spell_db) &&
        variable_struct_exists(global.spell_db, "learning_schedule")
    ) {
        var sched_map = global.spell_db.learning_schedule;

        if (ds_exists(sched_map, ds_type_map)) {
            if (ds_map_exists(sched_map, _char_key)) {
                var char_sched = ds_map_find_value(sched_map, _char_key);

                if (ds_exists(char_sched, ds_type_map)) {
                    for (var i = 1; i <= current_level; i++) {
                        var lvl_key = string(i);
                        if (ds_map_exists(char_sched, lvl_key)) {
                            var spell_key = ds_map_find_value(char_sched, lvl_key);

                            // ✅ Fixed line: Use variable_struct_get to access struct fields dynamically
                            if (variable_struct_exists(global.spell_db, spell_key)) {
                                array_push(s, variable_struct_get(global.spell_db, spell_key));
                            }
                        }
                    }
                }
            }
        }
    }

    d.skills = s;
    d.skill_index = 0;
    d.item_index = 0;
    d.is_defending = false;
    d.status = "none";

    show_debug_message(" [GetPlayerData] " + _char_key + " HP " + string(d.hp) + "/" + string(d.maxhp) + " | Level " + string(d.level) + " | Skills: " + string(array_length(d.skills)));

    return d;
}
