/// @function scr_UpdateStatusEffects()
/// @description Iterates through the global status map, decrements durations, removes expired effects, and applies DOT/HOT.

function scr_UpdateStatusEffects() {
    if (!variable_global_exists("battle_status_effects") || !ds_exists(global.battle_status_effects, ds_type_map)) { return; }

    show_debug_message(" -> Updating Status Effects...");
    var status_map = global.battle_status_effects;
    var inst_id_key = ds_map_find_first(status_map);
    var keys_to_remove = ds_list_create();

    while (!is_undefined(inst_id_key)) {
        var status_data = ds_map_find_value(status_map, inst_id_key);
        // Find instance using parent if possible, otherwise need specific object checks
        var target_inst = instance_find(id, inst_id_key); // Find ANY instance with this ID

        if (!instance_exists(target_inst) || !is_struct(status_data)) {
            ds_list_add(keys_to_remove, inst_id_key);
        } else {
            var effect_name = variable_struct_exists(status_data, "effect") ? status_data.effect : "none";
            var duration = variable_struct_exists(status_data, "duration") ? status_data.duration : 0;

            // Apply Damage Over Time / Heal Over Time Effects FIRST
            if (variable_instance_exists(target_inst, "data") && is_struct(target_inst.data)) {
                 var target_data = target_inst.data;
                 if (variable_struct_exists(target_data, "hp") && target_data.hp > 0) { // Only apply DOT/HOT if alive
                     switch (effect_name) {
                          case "poison":
                               var poison_dmg = 5; // Example damage
                               target_data.hp = max(0, target_data.hp - poison_dmg);
                               show_debug_message("    -> Poison deals " + string(poison_dmg) + " damage to " + string(target_inst));
                               if (object_exists(obj_popup_damage)) { instance_create_layer(target_inst.x, target_inst.y-64, "Instances", obj_popup_damage).damage_amount = string(poison_dmg);}
                               break;
                          case "regen":
                               var regen_heal = 8; // Example heal
                               if (variable_struct_exists(target_data, "maxhp")) {
                                   var old_hp = target_data.hp;
                                   target_data.hp = min(target_data.maxhp, target_data.hp + regen_heal);
                                   var actual_heal = target_data.hp - old_hp;
                                   if(actual_heal > 0) {
                                        show_debug_message("    -> Regen heals " + string(actual_heal) + " HP for " + string(target_inst));
                                        if (object_exists(obj_popup_damage)) { instance_create_layer(target_inst.x, target_inst.y-64, "Instances", obj_popup_damage).damage_amount = string(actual_heal);}
                                   }
                               }
                               break;
                     }
                     // Re-check for death after DOT
                     if (target_data.hp <= 0) { show_debug_message("    -> Instance " + string(target_inst) + " died from status effect " + effect_name); }
                 }
            }

            // Decrement Duration
            duration -= 1; status_data.duration = duration;
            show_debug_message("    -> Decremented status turns for " + string(target_inst) + " (" + effect_name + "). Remaining: " + string(duration));
            if (duration <= 0) { ds_list_add(keys_to_remove, inst_id_key); }
        }
        inst_id_key = ds_map_find_next(status_map, inst_id_key);
    } // End while loop

    // Remove expired effects
    var num_removed = ds_list_size(keys_to_remove); if (num_removed > 0) { show_debug_message(" -> Removing " + string(num_removed) + " expired status effects..."); for (var i = 0; i < num_removed; i++) { ds_map_delete(status_map, keys_to_remove[| i]); } } ds_list_destroy(keys_to_remove);
    show_debug_message(" -> Status Effect Update Complete.");
}