/// @function scr_GetStatus(target_inst)
/// @returns {Struct/undefined} { effect, duration } or undefined if none
function scr_GetStatus(target_inst) {
    if (!instance_exists(target_inst)) return undefined;
    if (!variable_global_exists("battle_status_effects")
     || !ds_exists(global.battle_status_effects, ds_type_map)) {
        return undefined;
    }
    var inst_id = target_inst.id;
    var status_data = ds_map_find_value(global.battle_status_effects, inst_id);
    // ds_map_find_value gives undefined if key not found
    return status_data;
}
