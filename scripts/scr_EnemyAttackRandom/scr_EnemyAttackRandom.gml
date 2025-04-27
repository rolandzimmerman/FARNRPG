/// @function scr_EnemyAttackRandom(_enemy_inst)
function scr_EnemyAttackRandom(_enemy_inst) {
    // Basic validation
    if (!instance_exists(_enemy_inst) || !variable_instance_exists(_enemy_inst, "data") || !is_struct(_enemy_inst.data)) {
        show_debug_message("Warning [EnemyAI]: Invalid enemy.");
        return true;
    }
    var e_data = _enemy_inst.data;

    // Status check (bind/shame)...
    var status = script_exists(scr_GetStatus) ? scr_GetStatus(_enemy_inst) : undefined;
    if (is_struct(status) && status.effect == "bind" && irandom(99) < 50) {
        show_debug_message(" -> Enemy bound, skip.");
        return true;
    }

    // Choose random living player
    var living = [];
    if (ds_exists(global.battle_party, ds_type_list)) {
        var psz = ds_list_size(global.battle_party);
        for (var i = 0; i < psz; i++) {
            var p = global.battle_party[| i];
            if (instance_exists(p) && is_struct(p.data) && p.data.hp > 0) {
                array_push(living, p);
            }
        }
    }
    if (array_length(living) == 0) {
        show_debug_message(" -> No targets.");
        return true;
    }
    var tgt = living[irandom(array_length(living)-1)];
    var td  = tgt.data;

    // Blind check
    if (is_struct(status) && status.effect == "blind" && irandom(99) < 50) {
        show_debug_message(" -> Enemy attack missed.");
        if (object_exists(obj_popup_damage)) instance_create_layer(tgt.x, tgt.y - 64, "Instances", obj_popup_damage).damage_amount = "Miss!";
        return true;
    }

    // Damage calc
    var dmg = max(1, (e_data.atk ?? 1) - (td.def ?? 0));
    if (td.is_defending) dmg = max(1, floor(dmg/2));
    var before = td.hp;
    td.hp = max(0, td.hp - dmg);
    show_debug_message(" -> Enemy dealt " + string(dmg) + " to " + string(tgt));
    if (object_exists(obj_popup_damage)) {
        var pop = instance_create_layer(tgt.x, tgt.y - 64, "Instances", obj_popup_damage);
        if (pop != noone) pop.damage_amount = string(dmg);
    }
    if (td.is_defending) td.is_defending = false;

    // +3 Overdrive for THAT player
    if (variable_struct_exists(td, "overdrive")) {
        td.overdrive = min(td.overdrive + 3, td.overdrive_max);
        show_debug_message(" -> " + string(tgt) + " OD = " + string(td.overdrive));
    }

    return true;
}
