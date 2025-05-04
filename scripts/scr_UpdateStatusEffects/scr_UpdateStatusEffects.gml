/// @function scr_UpdateStatusEffects()
function scr_UpdateStatusEffects() {
    if (!variable_global_exists("battle_status_effects")
     || !ds_exists(global.battle_status_effects, ds_type_map)) {
        return;
    }

    var status_map   = global.battle_status_effects;
    var inst_ids     = ds_map_keys_to_array(status_map);
    var to_remove_ds = ds_list_create();

    // 1) Process each
    for (var i = 0; i < array_length(inst_ids); i++) {
        var inst_id      = inst_ids[i];
        var status_data  = ds_map_find_value(status_map, inst_id);
        if (!instance_exists(inst_id) || !is_struct(status_data)) {
            ds_list_add(to_remove_ds, inst_id);
            continue;
        }

        var effect   = status_data.effect;
        var duration = status_data.duration;
        var inst     = inst_id; // now we can treat it as the instance

        // DOT/HOT
        if (variable_instance_exists(inst, "data") && is_struct(inst.data)) {
            var td = inst.data;
            if (td.hp > 0) {
                switch (effect) {
                    case "poison":
                        td.hp = max(0, td.hp - 5);
                        break;
                    case "regen":
                        td.hp = min(td.maxhp, td.hp + 8);
                        break;
                }
                // (you can still call scr_ProcessDeathIfNecessary(inst) here)
            }
        }

        // decrement
        duration -= 1;
        if (duration <= 0) {
            ds_list_add(to_remove_ds, inst_id);
        } else {
            status_data.duration = duration;
            ds_map_replace(status_map, inst_id, status_data);
        }
    }

    // 2) Clean up
    for (var j = 0; j < ds_list_size(to_remove_ds); j++) {
        ds_map_delete(status_map, to_remove_ds[| j]);
    }
    ds_list_destroy(to_remove_ds);
}
