/// @function scr_EnemyAttackRandom(_enemy_inst)
function scr_EnemyAttackRandom(_enemy_inst) {
    // Basic validation
    if (!instance_exists(_enemy_inst) || !variable_instance_exists(_enemy_inst, "data") || !is_struct(_enemy_inst.data)) {
        show_debug_message("Warning [EnemyAI]: Invalid enemy.");
        return true; // Consume turn even if invalid? Or false? Let's say true.
    }
    var e_data = _enemy_inst.data;

    // Status check moved to manager, assume we can act if we reach here

    // Choose random living player
    var living = [];
    if (ds_exists(global.battle_party, ds_type_list)) {
        var psz = ds_list_size(global.battle_party);
        for (var i = 0; i < psz; i++) {
            var p = global.battle_party[| i];
            if (instance_exists(p) && variable_instance_exists(p, "data") && is_struct(p.data) && p.data.hp > 0) {
                array_push(living, p);
            }
        }
    }
    if (array_length(living) == 0) {
        show_debug_message(" -> Enemy AI: No living targets.");
        return true; // No one to attack, turn ends
    }
    var tgt = living[irandom(array_length(living)-1)];
    if (!instance_exists(tgt) || !variable_instance_exists(tgt, "data")) { // Extra validation on chosen target
        show_debug_message(" -> Enemy AI: Chosen target invalid.");
        return true; // Turn ends
    }
    var td  = tgt.data;


    // Blind check
     var enemy_status = script_exists(scr_GetStatus) ? scr_GetStatus(_enemy_inst) : undefined; // Use GetStatus
     if (is_struct(enemy_status) && enemy_status.effect == "blind" && irandom(99) < 50) {
         show_debug_message(" -> Enemy attack missed due to Blind!");
         if (object_exists(obj_popup_damage)) instance_create_layer(tgt.x, tgt.y - 64, "Instances", obj_popup_damage).damage_amount = "Miss!";
         return true; // Attack missed, turn consumed
     }

    // Damage calc
    var dmg = max(1, (e_data.atk ?? 1) - (td.def ?? 0));
    if (td.is_defending) dmg = max(1, floor(dmg/2));
    var before = td.hp;
    td.hp = max(0, td.hp - dmg);
    show_debug_message(" -> Enemy dealt " + string(dmg) + " to " + string(tgt) + ". HP: " + string(before) + " -> " + string(td.hp));
    if (object_exists(obj_popup_damage)) {
        var pop = instance_create_layer(tgt.x, tgt.y - 64, "Instances", obj_popup_damage);
        if (pop != noone) pop.damage_amount = string(dmg);
    }
    if (td.is_defending) td.is_defending = false; // Clear target's defend state

    // +3 Overdrive for THAT player
    if (variable_struct_exists(td, "overdrive")) {
        td.overdrive = min(td.overdrive + 3, td.overdrive_max);
        show_debug_message(" -> " + string(tgt) + " OD = " + string(td.overdrive));
    }
    
    // IMMEDIATE DEATH CHECK (on the player target)
    if (script_exists(scr_ProcessDeathIfNecessary)) {
         // We usually don't 'process death' for players this way (they stay KO'd)
         // But we might check if the attack caused defeat
         // scr_ProcessDeathIfNecessary(tgt); 
         // Let's skip immediate player removal, check_win_loss handles defeat condition.
         if (td.hp <= 0) {
              show_debug_message(" -> Player " + string(tgt) + " was KO'd by enemy attack.");
         }
    }

    return true; // Attack completed, turn consumed
}