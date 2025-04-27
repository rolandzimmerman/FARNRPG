/// @function scr_ApplyStatus(target_inst, effect_name, duration)
/// @description Applies a status effect to a target instance by updating the global map.
/// @param {Id.Instance} target_inst   The instance to affect.
/// @param {String}      effect_name   The name of the status (e.g., "poison", "blind").
/// @param {Real}        duration      The number of turns the status should last.

function scr_ApplyStatus(target_inst, effect_name, duration) {
    // Validate inputs
    if (!instance_exists(target_inst)) {
        show_debug_message("ERROR [ApplyStatus]: Target instance does not exist.");
        return;
    }
    if (!is_string(effect_name) || effect_name == "none") {
        show_debug_message("ERROR [ApplyStatus]: Invalid effect name provided.");
        return; // Don't apply "none" or invalid names
    }
    if (!is_numeric(duration) || duration <= 0) {
        show_debug_message("ERROR [ApplyStatus]: Invalid duration provided.");
        return; // Duration must be positive
    }

    // Ensure the global map exists
    if (!variable_global_exists("battle_status_effects") || !ds_exists(global.battle_status_effects, ds_type_map)) {
        show_debug_message("ERROR [ApplyStatus]: global.battle_status_effects map missing! Creating...");
        global.battle_status_effects = ds_map_create(); // Attempt to recover
    }

    var inst_id = target_inst.id; // Use instance ID as the key
    var status_data = {
        effect: effect_name,
        duration: round(duration) // Ensure duration is an integer
    };

    show_debug_message(" -> Applying status '" + effect_name + "' to " + string(inst_id) + " for " + string(duration) + " turns.");
    ds_map_replace(global.battle_status_effects, inst_id, status_data); // Replace existing or add new entry
}