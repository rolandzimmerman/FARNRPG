/// @function scr_ApplyStatus(target_inst, effect_name, duration)
/// @description Applies a status effect to a target instance by updating the global map.
/// @returns {Bool} True if the status was applied, false otherwise.
function scr_ApplyStatus(target_inst, effect_name, duration) {
    // 1) Validate inputs
    if (!instance_exists(target_inst)) {
        show_debug_message("ERROR [ApplyStatus]: target does not exist.");
        return false;
    }
    if (!is_string(effect_name) || effect_name == "none") {
        show_debug_message("ERROR [ApplyStatus]: invalid effect name.");
        return false;
    }
    if (!is_real(duration) || duration <= 0) {
        show_debug_message("ERROR [ApplyStatus]: invalid duration.");
        return false;
    }

    // 2) Ensure map exists
    if (!variable_global_exists("battle_status_effects")
     || !ds_exists(global.battle_status_effects, ds_type_map)) {
        show_debug_message("CREATING status map...");
        global.battle_status_effects = ds_map_create();
    }

    var inst_id = target_inst.id;
    var status_data = {
        effect   : effect_name,
        duration : round(duration)
    };

    // 3) Add or replace
    if (ds_map_exists(global.battle_status_effects, inst_id)) {
        ds_map_replace(global.battle_status_effects, inst_id, status_data);
    } else {
        ds_map_add   (global.battle_status_effects, inst_id, status_data);
    }

    show_debug_message(" -> Applied '" + effect_name 
                     + "' to " + string(inst_id) 
                     + " for " + string(duration) + " turns.");
    return true;
}
