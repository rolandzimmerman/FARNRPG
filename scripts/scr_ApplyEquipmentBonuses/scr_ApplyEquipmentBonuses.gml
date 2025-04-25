/// @function scr_ApplyEquipmentBonuses(_char_data)
/// @description Returns a new struct that includes base stats + equipment bonuses.
/// @param {Struct} _char_data - Character data (must include base stats and equipment)
function scr_ApplyEquipmentBonuses(_char_data) {
    if (!is_struct(_char_data)) return _char_data;

    // start from original (will mutate the copy)
    var result = _char_data;

    // ensure slot struct
    if (!variable_struct_exists(_char_data, "equipment")) {
        result.equipment = {
            weapon:    noone,
            offhand:   noone,
            armor:     noone,
            helm:      noone,
            accessory: noone
        };
    }

    // accumulate bonuses
    var bonus = {
        atk:0, def:0, matk:0, mdef:0,
        spd:0, luk:0, hp_total:0, mp_total:0
    };

    var slots = ["weapon","offhand","armor","helm","accessory"];
    for (var i = 0; i < array_length(slots); i++) {
        var sn = slots[i];
        var key = _char_data.equipment[? sn];
        if (is_string(key) && variable_global_exists("item_database") && ds_exists(global.item_database, ds_type_map)) {
            var it = scr_GetItemData(key);
            if (is_struct(it) && variable_struct_exists(it, "bonuses")) {
                var b = it.bonuses;
                bonus.atk      += (variable_struct_exists(b,"atk")      ? b.atk      : 0);
                bonus.def      += (variable_struct_exists(b,"def")      ? b.def      : 0);
                bonus.matk     += (variable_struct_exists(b,"matk")     ? b.matk     : 0);
                bonus.mdef     += (variable_struct_exists(b,"mdef")     ? b.mdef     : 0);
                bonus.spd      += (variable_struct_exists(b,"spd")      ? b.spd      : 0);
                bonus.luk      += (variable_struct_exists(b,"luk")      ? b.luk      : 0);
                bonus.hp_total += (variable_struct_exists(b,"hp_total") ? b.hp_total : 0);
                bonus.mp_total += (variable_struct_exists(b,"mp_total") ? b.mp_total : 0);
            }
        }
    }

    // apply
    result.atk      += bonus.atk;
    result.def      += bonus.def;
    result.matk     += bonus.matk;
    result.mdef     += bonus.mdef;
    result.spd      += bonus.spd;
    result.luk      += bonus.luk;
    result.hp_total += bonus.hp_total;
    result.mp_total += bonus.mp_total;

    return result;
}
