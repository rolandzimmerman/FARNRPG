/// @function scr_EnemyAttackRandom(_enemy_inst)
/// @description Placeholder AI: Enemy attacks a random living party member. Includes logging.
/// @param {Instance} _enemy_inst The enemy instance performing the attack.
/// @returns {Bool} True if an action was attempted (even if target invalid), False otherwise.
function scr_EnemyAttackRandom(_enemy_inst) {
    // Basic validation
    if (!instance_exists(_enemy_inst) || !variable_instance_exists(_enemy_inst, "data") || !is_struct(_enemy_inst.data)) {
        show_debug_message("Warning [EnemyAI]: Invalid enemy instance or data provided.");
        return true; // Count turn as used even if enemy data invalid
    }
    var e_data = _enemy_inst.data; // Enemy's data struct

    show_debug_message(" -> Enemy " + string(_enemy_inst) + " (" + (e_data.name ?? "Unknown") + ") performing action (Attack Random).");

    // Find all living party members
    var living_players = [];
    show_debug_message("    -> Searching for living players..."); // DEBUG
    if (ds_exists(global.battle_party, ds_type_list)) {
        var _psize = ds_list_size(global.battle_party);
        show_debug_message("    -> Party list size: " + string(_psize)); // DEBUG
        for (var i = 0; i < _psize; i++) {
            var p = global.battle_party[| i];
            // Check if player instance exists, has data, and is alive
             var is_valid_target = false;
             if (instance_exists(p)) {
                 if (variable_instance_exists(p, "data") && is_struct(p.data)) {
                     if (variable_struct_exists(p.data, "hp") && p.data.hp > 0) {
                          is_valid_target = true;
                     }
                 }
             }
             show_debug_message("      -> Checking player index " + string(i) + " (ID: " + string(p) + "): IsValid=" + string(is_valid_target) + ", HP=" + string(is_valid_target ? p.data.hp : "N/A")); // DEBUG
             if (is_valid_target) {
                  array_push(living_players, p);
             }
        }
    } else { show_debug_message("   -> ERROR: global.battle_party is not a valid list!"); }

    show_debug_message("    -> Found " + string(array_length(living_players)) + " living player targets."); // DEBUG

    // If there are living targets, choose one randomly
    if (array_length(living_players) > 0) {
        var tgt_inst = living_players[irandom(array_length(living_players) - 1)]; // Choose random target
        show_debug_message("    -> Chosen Target: " + string(tgt_inst)); // DEBUG
        var tgt_data = tgt_inst.data; // Target's data struct

        // Basic damage calculation (uses enemy ATK vs player DEF)
        var dmg = max(1, (e_data.atk ?? 1) - (tgt_data.def ?? 0));

        // Apply defend status if target is defending
        if (variable_struct_exists(tgt_data, "is_defending") && tgt_data.is_defending) { dmg = max(1, floor(dmg / 2)); }

        // Apply damage if target has HP
        if (variable_struct_exists(tgt_data, "hp")) {
             var hp_before = tgt_data.hp;
             tgt_data.hp = max(0, tgt_data.hp - dmg); // Apply damage, minimum 0 HP
             show_debug_message("    -> Enemy attacked " + string(tgt_inst) + " for " + string(dmg) + " damage. Target HP: " + string(hp_before) + " -> " + string(tgt_data.hp));
             // Create damage popup
             if (object_exists(obj_popup_damage)) { /* Create popup */ }
             if (variable_struct_exists(tgt_data, "is_defending")) { tgt_data.is_defending = false; } // Reset defend
             return true; // Action completed successfully
        } else { show_debug_message("    -> ERROR: Target player missing HP field!"); return true; } // Count turn as used
    } else {
        show_debug_message(" -> Enemy has no living targets!");
        return true; // No targets, turn is still used
    }
}