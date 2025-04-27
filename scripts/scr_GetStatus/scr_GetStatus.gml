/// @function scr_GetStatus(target_inst)
/// @description Checks the global map and returns the status struct for an instance.
/// @param {Id.Instance} target_inst   The instance to check.
/// @returns {Struct / Undefined} The status struct {effect, duration} or undefined if no status or map missing.

function scr_GetStatus(target_inst) {
    // Basic validation
    if (!instance_exists(target_inst)) {
        return undefined;
    }
    if (!variable_global_exists("battle_status_effects") || !ds_exists(global.battle_status_effects, ds_type_map)) {
        // Map might not be created yet or was destroyed prematurely
        // show_debug_message("Warning [GetStatus]: global.battle_status_effects map missing!");
        return undefined;
    }

    var inst_id = target_inst.id; // Get the instance ID to use as the key
    var status_data = ds_map_find_value(global.battle_status_effects, inst_id);

    // ds_map_find_value returns undefined if key not found, which is desired behavior
    return status_data;
}