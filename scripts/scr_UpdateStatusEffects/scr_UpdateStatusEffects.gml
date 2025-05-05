/// @function scr_UpdateStatusEffects()
function scr_UpdateStatusEffects() {
    scr_AddBattleLog("UpdateStatusEffects START");
    if (!variable_global_exists("battle_status_effects")) return;
    var map = global.battle_status_effects;
    var keys = ds_map_keys_to_array(map);
    var to_remove = ds_list_create();

    for (var i = 0; i < array_length(keys); i++) {
        var inst = keys[i];
        var sd   = ds_map_find_value(map, inst);
        if (!instance_exists(inst)) {
            ds_list_add(to_remove, inst);
            scr_AddBattleLog("Status target gone: " + string(inst));
            continue;
        }
        scr_AddBattleLog("Processing status on " + string(inst) + ": " + sd.effect + " (" + string(sd.duration) + ")");
        switch (sd.effect) {
            case "poison":
                inst.data.hp = max(0, inst.data.hp - 5);
                scr_AddBattleLog("Poison tick: HP→" + string(inst.data.hp));
                break;
            case "regen":
                inst.data.hp = min(inst.data.maxhp, inst.data.hp + 8);
                scr_AddBattleLog("Regen tick: HP→" + string(inst.data.hp));
                break;
        }
        sd.duration -= 1;
        if (sd.duration <= 0) {
            ds_list_add(to_remove, inst);
            scr_AddBattleLog("Status expired on " + string(inst));
        } else {
            ds_map_replace(map, inst, sd);
        }
    }
    for (var j = 0; j < ds_list_size(to_remove); j++) {
        ds_map_delete(map, to_remove[|j]);
    }
    ds_list_destroy(to_remove);
    scr_AddBattleLog("UpdateStatusEffects END");
}
