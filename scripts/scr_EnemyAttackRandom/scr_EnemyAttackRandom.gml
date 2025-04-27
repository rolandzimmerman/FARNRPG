/// @function scr_EnemyAttackRandom(_enemy_inst)
/// @description Placeholder AI: Enemy attacks random living player. Checks instance status vars via scr_GetStatus.
/// @param {Id.Instance} _enemy_inst The enemy instance performing the attack.
/// @returns {Bool} True if an action was attempted (even if target invalid), False otherwise.
function scr_EnemyAttackRandom(_enemy_inst) {
    // Basic validation
    if (!instance_exists(_enemy_inst) || !variable_instance_exists(_enemy_inst, "data") || !is_struct(_enemy_inst.data)) {
        show_debug_message("Warning [EnemyAI]: Invalid enemy instance or data provided.");
        return true; // Count turn as used even if enemy data invalid
    }
    var e_data = _enemy_inst.data; // Enemy's data struct

    // --- Check Enemy Status via scr_GetStatus ---
    var enemy_status_info = script_exists(scr_GetStatus) ? scr_GetStatus(_enemy_inst) : undefined;
    if (is_struct(enemy_status_info)) {
         if (enemy_status_info.effect == "bind" && irandom(99) < 50) {
              show_debug_message(" -> Enemy " + string(_enemy_inst) + " bound, turn skipped.");
              if (object_exists(obj_popup_damage)) { instance_create_layer(_enemy_inst.x, _enemy_inst.y - 64, "Instances", obj_popup_damage).damage_amount = "Bound!"; }
              return true; // Turn used
         }
         if (enemy_status_info.effect == "shame") { // Example: Shame could prevent attacks
              show_debug_message(" -> Enemy " + string(_enemy_inst) + " shamed, turn skipped.");
              if (object_exists(obj_popup_damage)) { instance_create_layer(_enemy_inst.x, _enemy_inst.y - 64, "Instances", obj_popup_damage).damage_amount = "Shame!"; }
              return true; // Turn used
         }
         // Add checks for other statuses like sleep, paralysis
    }
    // --- End Status Check ---

    show_debug_message(" -> Enemy " + string(_enemy_inst) + " (" + (e_data.name ?? "Unknown") + ") performing action (Attack Random).");

    // Check for Blind status before attacking
    var missed_due_to_blind = false;
    if (is_struct(enemy_status_info) && enemy_status_info.effect == "blind" && irandom(99) < 50) { // 50% miss chance
        show_debug_message("    -> Enemy attack missed due to Blind!");
        // Need a target to show the "Miss!" popup near
        var temp_target = instance_find(obj_battle_player, 0); // Just find any player for position
        if (instance_exists(temp_target) && object_exists(obj_popup_damage)) {
             instance_create_layer(temp_target.x, temp_target.y - 64, "Instances", obj_popup_damage).damage_amount = "Miss!";
        }
        missed_due_to_blind = true;
        // return true; // Blind miss still uses the turn
    }

    // Find living targets
    var living_players = []; if (ds_exists(global.battle_party, ds_type_list)) { var _psize = ds_list_size(global.battle_party); show_debug_message("    -> Party list size for targeting: " + string(_psize)); for (var i = 0; i < _psize; i++) { var p = global.battle_party[| i]; var is_valid_target = false; if (instance_exists(p) && variable_instance_exists(p, "data") && is_struct(p.data) && variable_struct_exists(p.data, "hp") && p.data.hp > 0) { is_valid_target = true; } show_debug_message("      -> Checking player index " + string(i) + " (ID: " + string(p) + "): IsValid=" + string(is_valid_target) + ", HP=" + string(is_valid_target ? p.data.hp : "N/A")); if (is_valid_target) { array_push(living_players, p); } } } else { show_debug_message("   -> ERROR: global.battle_party is not valid for targeting!"); }
    show_debug_message("    -> Found " + string(array_length(living_players)) + " living player targets.");

    if (array_length(living_players) > 0) {
        var tgt_inst = living_players[irandom(array_length(living_players) - 1)];
        show_debug_message("    -> Chosen Target: " + string(tgt_inst));
        var tgt_data = tgt_inst.data;

        // Only calculate and apply damage if not missed due to blind
        if (!missed_due_to_blind) {
            var dmg = max(1, (e_data.atk ?? 1) - (tgt_data.def ?? 0));
            if (variable_struct_exists(tgt_data, "is_defending") && tgt_data.is_defending) { dmg = max(1, floor(dmg / 2)); }
            if (variable_struct_exists(tgt_data, "hp")) {
                 var hp_before = tgt_data.hp; tgt_data.hp = max(0, tgt_data.hp - dmg); show_debug_message("    -> Enemy attacked " + string(tgt_inst) + " for " + string(dmg) + " damage. Target HP: " + string(hp_before) + " -> " + string(tgt_data.hp));
                 if (object_exists(obj_popup_damage)) { /* Create Popup */ }
                 if (variable_struct_exists(tgt_data, "is_defending")) { tgt_data.is_defending = false; }
            }
        }
        return true; // Action was performed (or missed due to blind)
    } else {
        show_debug_message(" -> Enemy has no living targets to attack!");
        return true; // No targets, turn is still used
    }
}