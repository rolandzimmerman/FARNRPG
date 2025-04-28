/// @function scr_UpdateStatusEffects()
/// @description Iterates through the global status map, decrements durations, removes expired effects, and applies DOT/HOT.

function scr_UpdateStatusEffects() {
    if (!variable_global_exists("battle_status_effects") || !ds_exists(global.battle_status_effects, ds_type_map)) { return; }

    show_debug_message(" -> Updating Status Effects...");
    var status_map = global.battle_status_effects;
    
    // Use ds_map_keys_to_array for safer iteration than find_first/find_next when potentially modifying the map
    var inst_id_array = ds_map_keys_to_array(status_map); 
    var array_len = array_length(inst_id_array);
    var keys_to_remove = ds_list_create(); // List to store keys for removal *after* iteration

    for (var i = 0; i < array_len; i++) {
        var inst_id_key = inst_id_array[i]; // This is the instance ID
        var status_data = ds_map_find_value(status_map, inst_id_key); // Fetch data using key

        // Check if the instance associated with this ID still exists
        if (!instance_exists(inst_id_key) || !is_struct(status_data)) {
            ds_list_add(keys_to_remove, inst_id_key); // Mark invalid entry for removal
            // show_debug_message("    -> Status target " + string(inst_id_key) + " no longer exists or data invalid. Marking for removal.");
        } else {
             // Instance exists, proceed with status logic
             var target_inst = inst_id_key; // Use the ID directly as the instance reference
             var effect_name = variable_struct_exists(status_data, "effect") ? status_data.effect : "none";
             var duration = variable_struct_exists(status_data, "duration") ? status_data.duration : 0;
             var continue_processing = true; // Flag to check if effect should still tick down

            // Apply Damage Over Time / Heal Over Time Effects FIRST
             if (variable_instance_exists(target_inst, "data") && is_struct(target_inst.data)) {
                 var target_data = target_inst.data;
                 if (variable_struct_exists(target_data, "hp") && target_data.hp > 0) { // Only apply DOT/HOT if alive
                     switch (effect_name) {
                         case "poison":
                             var poison_dmg = 5; // Example damage
                             var old_hp_p = target_data.hp;
                             target_data.hp = max(0, target_data.hp - poison_dmg);
                             show_debug_message("    -> Poison deals " + string(poison_dmg) + " damage to " + string(target_inst) + " HP: " + string(old_hp_p) + " -> " + string(target_data.hp));
                             if (object_exists(obj_popup_damage)) { 
                                 var pop = instance_create_layer(target_inst.x, target_inst.y-64, "Instances", obj_popup_damage);
                                 if (pop != noone) { pop.damage_amount = string(poison_dmg); pop.text_color = c_purple; } // Example color
                             }
                             break;
                         case "regen":
                             var regen_heal = 8; // Example heal
                             if (variable_struct_exists(target_data, "maxhp")) {
                                 var old_hp_r = target_data.hp;
                                 target_data.hp = min(target_data.maxhp, target_data.hp + regen_heal);
                                 var actual_heal = target_data.hp - old_hp_r;
                                 if(actual_heal > 0) {
                                     show_debug_message("    -> Regen heals " + string(actual_heal) + " HP for " + string(target_inst));
                                     if (object_exists(obj_popup_damage)) { 
                                         var pop = instance_create_layer(target_inst.x, target_inst.y-64, "Instances", obj_popup_damage);
                                         if (pop != noone) { pop.damage_amount = "+" + string(actual_heal); pop.text_color = c_lime; } // Example color
                                     }
                                 }
                             }
                             break;
                     }
                     // Re-check for death after DOT
                     if (target_data.hp <= 0) { 
                         show_debug_message("    -> Instance " + string(target_inst) + " died from status effect " + effect_name); 
                         // Death processing happens later in check_win_loss, but stop duration countdown maybe?
                         // continue_processing = false; // Uncomment if duration shouldn't tick down on the turn they die from DOT
                     }
                 } else { // Target HP <= 0 before DOT/HOT applied
                      continue_processing = false; // Don't decrement duration if already dead
                 }
             } else { // Target has no data struct
                 continue_processing = false; 
             } // end if data exists

            // Decrement Duration if applicable
            if (continue_processing) {
                 duration -= 1; 
                 status_data.duration = duration; // Update duration in the struct

                 show_debug_message("    -> Decremented status turns for " + string(target_inst) + " (" + effect_name + "). Remaining: " + string(duration));
                 
                 if (duration <= 0) { 
                     ds_list_add(keys_to_remove, inst_id_key); // Mark for removal
                     show_debug_message("    -> Status " + effect_name + " expired for " + string(target_inst));
                 } else {
                     // Update the map with the modified struct if it hasn't expired
                     ds_map_replace(status_map, inst_id_key, status_data);
                 }
            } else {
                 // If we skipped processing (e.g., target was dead), should the status be removed?
                 // Let's keep it for now, maybe they get revived. It won't tick down.
                 // Alternatively, add to keys_to_remove if dead?
                 // ds_list_add(keys_to_remove, inst_id_key); 
            }
        } // end if instance exists
    } // End for loop iterating keys

    // Remove expired/invalid effects AFTER iterating
    var num_removed = ds_list_size(keys_to_remove); 
    if (num_removed > 0) { 
        show_debug_message(" -> Removing " + string(num_removed) + " status effects from map..."); 
        for (var i = 0; i < num_removed; i++) { 
            ds_map_delete(status_map, keys_to_remove[| i]); 
        } 
    } 
    ds_list_destroy(keys_to_remove);
    show_debug_message(" -> Status Effect Update Complete.");
}