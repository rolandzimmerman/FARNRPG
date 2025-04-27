/// @function scr_PerformAttack(_attacker_inst, _target_inst)
function scr_PerformAttack(_attacker_inst, _target_inst) {
    // 1. Validate Attacker
    if (!instance_exists(_attacker_inst) || !variable_instance_exists(_attacker_inst, "data") || !is_struct(_attacker_inst.data)) {
        show_debug_message("ERROR [PerformAttack]: Invalid attacker.");
        return false;
    }
    var attacker_data = _attacker_inst.data;

    // --- Fill Overdrive on action ---
    if (variable_struct_exists(attacker_data, "overdrive")) {
        attacker_data.overdrive = min(attacker_data.overdrive + 5, attacker_data.overdrive_max);
        show_debug_message(" -> Overdrive for attacker is now " + string(attacker_data.overdrive));
    }

    // 2. Validate Target
    if (!instance_exists(_target_inst) || !variable_instance_exists(_target_inst, "data") || !is_struct(_target_inst.data)) {
        show_debug_message("Warning [PerformAttack]: Invalid target—turn consumed.");
        return true;
    }
    var target_data = _target_inst.data;

    // 3. Blind check
    if (variable_struct_exists(attacker_data, "status") && attacker_data.status == "blind" && irandom(99) < 50) {
         show_debug_message(" -> Attack missed due to Blind!");
         if (object_exists(obj_popup_damage)) {
             var miss_pop = instance_create_layer(_target_inst.x, _target_inst.y - 64, "Instances", obj_popup_damage);
             if (miss_pop != noone) miss_pop.damage_amount = "Miss!";
         }
         return true;
    }

    // 4. Calculate Damage
    var damage = max(1, (attacker_data.atk ?? 1) - (target_data.def ?? 0));
    if (variable_struct_exists(target_data, "is_defending") && target_data.is_defending) {
        damage = max(1, floor(damage / 2));
    }

    // 5. Apply Damage
    var old_hp = target_data.hp;
    target_data.hp = max(0, target_data.hp - damage);
    show_debug_message(" -> Dealt " + string(damage) + " to " + string(_target_inst) +
                      ". HP: " + string(old_hp) + " -> " + string(target_data.hp));
    if (object_exists(obj_popup_damage)) {
        var pop = instance_create_layer(_target_inst.x, _target_inst.y - 64, "Instances", obj_popup_damage);
        if (pop != noone) pop.damage_amount = string(damage);
    }
    if (variable_struct_exists(target_data, "is_defending")) target_data.is_defending = false;

    return true;
}
