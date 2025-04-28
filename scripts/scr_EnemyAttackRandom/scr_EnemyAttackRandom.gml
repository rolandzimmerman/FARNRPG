/// @function scr_EnemyAttackRandom(_enemy_inst)
/// @description Enemy selects a random living player, attacks them, considering elements and resistances.
/// @param {Id.Instance} _enemy_inst The enemy instance performing the attack.
/// @returns {Bool} True if the action sequence should proceed (attack hit, missed, or target invalid).
function scr_EnemyAttackRandom(_enemy_inst) {
    // 1. Validate Attacker
    if (!instance_exists(_enemy_inst) || !variable_instance_exists(_enemy_inst, "data") || !is_struct(_enemy_inst.data)) {
        show_debug_message("Warning [EnemyAI]: Invalid enemy instance.");
        return true; 
    }
    var e_data = _enemy_inst.data;

    // 2. Status check (Bind/Shame - Redundant if manager checks, but safe)
    var status = script_exists(scr_GetStatus) ? scr_GetStatus(_enemy_inst) : undefined;
    if (is_struct(status)) {
         if (status.effect == "shame") { show_debug_message(" -> Enemy shamed, skip."); return true; }
         if (status.effect == "bind" && irandom(99) < 50) { show_debug_message(" -> Enemy bound, skip."); return true; }
    }

    // 3. Choose random living player target
    var living_players = [];
    if (ds_exists(global.battle_party, ds_type_list)) {
        var party_size = ds_list_size(global.battle_party);
        for (var i = 0; i < party_size; i++) {
            var p_inst = global.battle_party[| i];
            if (instance_exists(p_inst) && variable_instance_exists(p_inst,"data") && is_struct(p_inst.data) && variable_struct_exists(p_inst.data,"hp") && p_inst.data.hp > 0) {
                array_push(living_players, p_inst);
            }
        }
    }
    if (array_length(living_players) == 0) { show_debug_message(" -> Enemy AI: No living targets."); return true; }
    var target_inst = living_players[irandom(array_length(living_players)-1)];
    if (!instance_exists(target_inst) || !variable_instance_exists(target_inst,"data") || !is_struct(target_inst.data) || !variable_struct_exists(target_inst.data,"hp")) { show_debug_message(" -> Enemy AI: Chosen target became invalid."); return true; }
    var target_data = target_inst.data; 
    if (target_data.hp <= 0) { show_debug_message(" -> Enemy AI: Target already KO'd."); return true; }

    // 4. Blind Check 
    if (is_struct(status) && status.effect == "blind" && irandom(99) < 50) {
        show_debug_message(" -> Enemy attack missed due to Blind!");
        if (object_exists(obj_popup_damage)) { 
             var miss_layer_id = layer_get_id("Instances");
             if(miss_layer_id != -1) {
                 var miss_pop = instance_create_layer(target_inst.x, target_inst.y - 64, miss_layer_id, obj_popup_damage);
                 if (miss_pop != noone) miss_pop.damage_amount = "Miss!";
             }
        }
        return true; 
    }

    // 5. Get Attack Element 
    var attack_element = e_data.attack_element ?? "physical"; 
    show_debug_message("    -> Enemy Attack Element: " + attack_element);

    // 6. Calculate Base Damage 
    var atk_stat = e_data.atk ?? 1;
    var def_stat = target_data.def ?? 0;
    var base_damage = max(1, atk_stat - def_stat); 
    if (variable_struct_exists(target_data, "is_defending") && target_data.is_defending) { base_damage = max(1, floor(base_damage / 2)); }
    
    // 7. Apply Elemental Resistance Multiplier
    var resistance_multiplier = 1.0;
    if (script_exists(GetResistanceMultiplier) && variable_struct_exists(target_data, "resistances")) {
         resistance_multiplier = GetResistanceMultiplier(target_data.resistances, attack_element);
    } else if (!script_exists(GetResistanceMultiplier)){ show_debug_message("    -> Warning: GetResistanceMultiplier script missing!"); }
    
    var final_damage = floor(base_damage * resistance_multiplier);
    
    // --- MINIMUM DAMAGE FIX ---
    if (base_damage >= 1 && resistance_multiplier > 0) { 
         final_damage = max(1, final_damage); 
         if (final_damage == 1 && (base_damage * resistance_multiplier) < 1 && resistance_multiplier > 0) { 
              show_debug_message("    -> Applied Min Damage Rule. Damage forced to: " + string(final_damage));
         }
    } else {
         final_damage = max(0, final_damage); 
    }
    // --- END FIX ---

    // 8. Apply Final Damage & Add Logging
    var old_hp = target_data.hp;
    show_debug_message("    -> Applying Final Damage: " + string(final_damage) + " to Target HP (Before): " + string(old_hp)); 
    target_data.hp = max(0, target_data.hp - final_damage); 
    show_debug_message("    -> Target HP (After): " + string(target_data.hp)); 
    
    show_debug_message(" -> Enemy " + string(_enemy_inst) + " dealt " + string(final_damage) + " (" + attack_element + ") to " + string(target_inst) +
                       ". HP: " + string(old_hp) + " -> " + string(target_data.hp) + 
                       " (Base:" + string(base_damage) + " * Resist:" + string(resistance_multiplier) + ")");
                       
    // 9. Damage Popup 
    var popup_text = string(final_damage);
    var popup_color = c_white;
    if (resistance_multiplier <= 0) { popup_text = "Immune"; popup_color = c_gray; } 
    else if (resistance_multiplier < 0.9) { popup_text += " (Resist)"; popup_color = c_aqua; }
    else if (resistance_multiplier > 1.1) { popup_text += " (Weak!)"; popup_color = c_yellow; }
    if (object_exists(obj_popup_damage)) {
        var popup_layer_id = layer_get_id("Instances");
        if (popup_layer_id != -1) {
            var pop = instance_create_layer(target_inst.x, target_inst.y - 64, popup_layer_id, obj_popup_damage);
            if (pop != noone) { pop.damage_amount = popup_text; pop.text_color = popup_color; }
        } else { show_debug_message("ERROR: Cannot create popup, layer 'Instances' missing."); }
    }
    
    // 10. Clear Target Defend State
    if (variable_struct_exists(target_data, "is_defending")) target_data.is_defending = false;

    // 11. Overdrive Gain for Target
    if (variable_struct_exists(target_data, "overdrive") && variable_struct_exists(target_data,"overdrive_max")) {
        target_data.overdrive = min(target_data.overdrive + 3, target_data.overdrive_max); 
        show_debug_message("    -> Target Overdrive: " + string(target_data.overdrive));
     }

    // 12. IMMEDIATE DEATH CHECK (for Player)
    if (target_data.hp <= 0) {
        show_debug_message(" -> Player " + string(target_inst) + " was KO'd by enemy attack.");
    }
    
    show_debug_message("--- scr_EnemyAttackRandom END ---"); 

    return true; // Indicate action was processed
}