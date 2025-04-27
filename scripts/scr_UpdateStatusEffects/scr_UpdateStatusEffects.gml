/// @function scr_UpdateStatusEffects()
/// @description Iterates through the global status map, decrements durations, removes expired effects, and applies DOT/HOT.
///              Called once per round (e.g., in obj_battle_manager's check_win_loss state).

function scr_UpdateStatusEffects() {
    // Check if the map exists
    if (!variable_global_exists("battle_status_effects") || !ds_exists(global.battle_status_effects, ds_type_map)) {
        show_debug_message("ERROR [UpdateStatusEffects]: global.battle_status_effects map missing!");
        return; // Cannot proceed without the map
    }

    show_debug_message(" -> Updating Status Effects...");

    var status_map = global.battle_status_effects;
    var inst_id_key = ds_map_find_first(status_map); // Get the first instance ID (key)
    var keys_to_remove = ds_list_create(); // List to store keys of effects that expire this turn

    // Loop through all keys (instance IDs) currently in the status map
    while (!is_undefined(inst_id_key)) {
        var status_data = ds_map_find_value(status_map, inst_id_key); // Get the status struct {effect, duration}
        var target_inst = instance_find(id, inst_id_key); // Find the actual instance using its ID

        // If the instance doesn't exist anymore or status data is somehow invalid, mark for removal
        if (!instance_exists(target_inst) || !is_struct(status_data)) {
            show_debug_message("    -> Status target instance " + string(inst_id_key) + " no longer exists or data invalid. Marking for removal.");
            ds_list_add(keys_to_remove, inst_id_key);
        } else {
            // Instance exists, process status
            var effect_name = variable_struct_exists(status_data, "effect") ? status_data.effect : "none";
            var duration = variable_struct_exists(status_data, "duration") ? status_data.duration : 0;

            // Apply Damage Over Time / Heal Over Time Effects FIRST
            if (variable_instance_exists(target_inst, "data") && is_struct(target_inst.data)) {
                 var target_data = target_inst.data;
                 if (variable_struct_exists(target_data, "hp")) {
                     switch (effect_name) {
                          case "poison":
                               var poison_dmg = 5; // Example damage
                               target_data.hp = max(0, target_data.hp - poison_dmg);
                               show_debug_message("    -> Poison deals " + string(poison_dmg) + " damage to " + string(target_inst));
                               // Create poison damage popup?
                               break;
                          case "regen":
                               var regen_heal = 8; // Example heal
                               if (variable_struct_exists(target_data, "maxhp")) {
                                   target_data.hp = min(target_data.maxhp, target_data.hp + regen_heal);
                                    show_debug_message("    -> Regen heals " + string(regen_heal) + " HP for " + string(target_inst));
                                    // Create regen heal popup?
                               }
                               break;
                          // Add other DOT/HOT effects here
                     }
                 }
                 // Check for death caused by DOT
                 if (variable_struct_exists(target_data, "hp") && target_data.hp <= 0) {
                      show_debug_message("    -> Instance " + string(target_inst) + " died from status effect " + effect_name);
                      // Handle death visuals/state if needed immediately
                 }
            }

            // Decrement Duration
            duration -= 1;
            status_data.duration = duration; // Update duration in the struct
            show_debug_message("    -> Decremented status turns for " + string(target_inst) + " (" + effect_name + "). Remaining: " + string(duration));

            // Check if status expired
            if (duration <= 0) {
                show_debug_message("    -> Status " + effect_name + " wore off for " + string(target_inst));
                ds_list_add(keys_to_remove, inst_id_key); // Mark for removal from the map
            }
            // No need to ds_map_replace here, as we modified the struct directly by reference
        }
        // Move to the next instance ID in the map
        inst_id_key = ds_map_find_next(status_map, inst_id_key);
    } // End while loop

    // Remove expired effects from the map
    var num_removed = ds_list_size(keys_to_remove);
    if (num_removed > 0) {
         show_debug_message(" -> Removing " + string(num_removed) + " expired status effects...");
         for (var i = 0; i < num_removed; i++) {
             ds_map_delete(status_map, keys_to_remove[| i]);
         }
    }
    ds_list_destroy(keys_to_remove); // Clean up temporary list
    show_debug_message(" -> Status Effect Update Complete.");
}