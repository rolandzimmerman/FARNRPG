/// @function scr_PerformAttack(_attacker_inst, _target_inst)
/// @description Handles the basic Attack command. Calculates damage based on ATK/DEF,
///              applies it to the target, creates a damage popup, and returns true if action was performed.
/// @param {Instance} _attacker_inst The instance performing the attack.
/// @param {Instance} _target_inst   The instance being attacked.
/// @returns {Bool} True if attack was processed (even if target invalid), False on critical error.

function scr_PerformAttack(_attacker_inst, _target_inst) {
    // 1. Validate Attacker
    if (!instance_exists(_attacker_inst) || !variable_instance_exists(_attacker_inst, "data") || !is_struct(_attacker_inst.data)) {
        show_debug_message("ERROR [PerformAttack]: Invalid attacker instance or data.");
        return false; // Critical failure
    }
    var attacker_data = _attacker_inst.data;

    // 2. Validate Target
    if (!instance_exists(_target_inst) || !variable_instance_exists(_target_inst, "data") || !is_struct(_target_inst.data)) {
        show_debug_message("Warning [PerformAttack]: Target instance invalid or missing data (maybe died?). Attack has no effect.");
        // Create a "Miss" or "No Target" popup maybe?
        return true; // Count the turn as used even though attack didn't connect
    }
    var target_data = _target_inst.data;

    // 3. Check Attacker Status (Blind)
    if (variable_struct_exists(attacker_data, "status") && attacker_data.status == "blind" && irandom(99) < 50) { // 50% miss chance
         show_debug_message(" -> Attack missed due to Blind!");
         if (object_exists(obj_popup_damage)) {
              var miss_pop = instance_create_layer(_target_inst.x, _target_inst.y - 64, "Instances", obj_popup_damage);
              if (miss_pop != noone) miss_pop.damage_amount = "Miss!";
         }
         return true; // Turn is used
    }

    // 4. Calculate Damage (Basic ATK vs DEF)
    var attacker_atk = variable_struct_exists(attacker_data, "atk") ? attacker_data.atk : 1;
    var target_def   = variable_struct_exists(target_data, "def")   ? target_data.def   : 0;
    var damage = max(1, attacker_atk - target_def); // Ensure at least 1 damage

    // Apply Defend status if target is defending
    if (variable_struct_exists(target_data, "is_defending") && target_data.is_defending) {
        damage = floor(damage / 2);
        show_debug_message("    -> Target is defending! Damage halved to: " + string(damage));
        damage = max(1, damage); // Ensure defend doesn't reduce damage below 1
    }

    // 5. Apply Damage to Target HP
    if (variable_struct_exists(target_data, "hp")) {
        var old_hp = target_data.hp;
        target_data.hp = max(0, target_data.hp - damage); // Apply damage, floor is 0
        show_debug_message("    -> Dealt " + string(damage) + " damage to " + string(_target_inst) + ". HP: " + string(old_hp) + " -> " + string(target_data.hp));

        // 6. Create Damage Popup
        if (object_exists(obj_popup_damage)) {
            var pop = instance_create_layer(_target_inst.x, _target_inst.y - 64, "Instances", obj_popup_damage);
            if (pop != noone) {
                pop.damage_amount = string(damage);
                // Optional: Change color based on damage, crit, etc.
                // pop.text_color = c_red;
            }
        }

         // 7. Reset defend status after hit (optional)
         if (variable_struct_exists(target_data, "is_defending")) { target_data.is_defending = false; }

         return true; // Attack was performed successfully
    } else {
         show_debug_message("ERROR [PerformAttack]: Target is missing 'hp' field!");
         return true; // Still count turn as used even if target data is broken
    }
}