/// @function scr_PerformAttack(_attacker_inst, _target_inst)
/// @description Calculates and applies damage for a basic attack, including element/resistance. Called BY the attacker instance during its attack animation state.
/// @param {Id.Instance} _attacker_inst The instance performing the attack.
/// @param {Id.Instance} _target_inst The instance being attacked.
/// @returns {Bool} True if damage was applied or missed, False if target/attacker invalid pre-attack.
function scr_PerformAttack(_attacker_inst, _target_inst) {
    show_debug_message("--- scr_PerformAttack START ---");
    // 1. Validate Attacker & Target
    if (!instance_exists(_attacker_inst) || !variable_instance_exists(_attacker_inst, "data") || !is_struct(_attacker_inst.data)) {show_debug_message("PerformAttack: Invalid Attacker"); return false;}
    if (!instance_exists(_target_inst) || !variable_instance_exists(_target_inst, "data") || !is_struct(_target_inst.data)) {show_debug_message("PerformAttack: Invalid Target"); return false;}
    
    var attacker_data = _attacker_inst.data;
    var target_data = _target_inst.data;

    // Cannot target dead units
    if (!variable_struct_exists(target_data,"hp") || target_data.hp <= 0) {
         show_debug_message("Warning [PerformAttack]: Target already has 0 HP.");
         return false; // Fail the action
    }

    // --- Get Attack Element from Weapon ---
    var attack_fx_info = { sprite: spr_pow, sound: snd_punch, element: "physical" }; 
    if (script_exists(scr_GetWeaponAttackFX)) {
        attack_fx_info = scr_GetWeaponAttackFX(_attacker_inst); 
    }
    var attack_element = attack_fx_info.element; 
    show_debug_message(" -> Attack Element: " + attack_element);

    // --- Fill Overdrive ---
    if (variable_struct_exists(attacker_data, "overdrive") && variable_struct_exists(attacker_data, "overdrive_max")) {
        attacker_data.overdrive = min(attacker_data.overdrive + 5, attacker_data.overdrive_max);
    } 
    // <<< Extra brace removed from here >>>
    
    // 3. Blind check
     var attacker_status = script_exists(scr_GetStatus) ? scr_GetStatus(_attacker_inst) : undefined; 
     if (is_struct(attacker_status) && attacker_status.effect == "blind" && irandom(99) < 50) {
          show_debug_message(" -> Attack missed due to Blind!");
          if (object_exists(obj_popup_damage)) { 
                var _layer_id = layer_get_id("Instances");
                if (_layer_id != -1) {
                    var miss_pop = instance_create_layer(_target_inst.x, _target_inst.y - 64, _layer_id, obj_popup_damage);
                    if (miss_pop != noone) miss_pop.damage_amount = "Miss!";
                }
           }
          return true; // Missed, but turn consumed
     }

    // 4. Calculate Base Damage
    var atk_stat = attacker_data.atk ?? 1;
    var def_stat = target_data.def ?? 0;
    var base_damage = max(1, atk_stat - def_stat);
    if (variable_struct_exists(target_data, "is_defending") && target_data.is_defending) { base_damage = max(1, floor(base_damage / 2)); }
    
    // 5. Apply Elemental Resistance Multiplier
    var resistance_multiplier = 1.0;
    if (script_exists(GetResistanceMultiplier) && variable_struct_exists(target_data, "resistances")) { resistance_multiplier = GetResistanceMultiplier(target_data.resistances, attack_element); } 
    
    var final_damage = floor(base_damage * resistance_multiplier);
    
    // Minimum Damage Fix
    if (base_damage >= 1 && resistance_multiplier > 0) { 
         final_damage = max(1, final_damage); 
         if (final_damage == 1 && (base_damage * resistance_multiplier) < 1 && resistance_multiplier > 0) { show_debug_message("    -> Applied Min Damage Rule. Damage forced to: " + string(final_damage)); }
    } else { final_damage = max(0, final_damage); }

    // 6. Apply Final Damage
    var old_hp = target_data.hp;
    target_data.hp = max(0, target_data.hp - final_damage);
    show_debug_message(" -> Dealt " + string(final_damage) + " (" + attack_element + ") to " + string(_target_inst) + ". HP: " + string(old_hp) + " -> " + string(target_data.hp) + " (Base:" + string(base_damage) + " * Resist:" + string(resistance_multiplier) + ")");
                       
    // 7. Damage Popup 
    var popup_text = string(final_damage);
    var popup_color = c_white;
    if (resistance_multiplier <= 0 && final_damage == 0) { popup_text = "Immune"; popup_color = c_gray; } 
    else if (resistance_multiplier < 0.9) { popup_text += " (Resist)"; popup_color = c_aqua; }
    else if (resistance_multiplier > 1.1) { popup_text += " (Weak!)"; popup_color = c_yellow; }
    
    if (object_exists(obj_popup_damage)) {
         var popup_layer_id = layer_get_id("Instances");
         if(popup_layer_id != -1){
            var pop = instance_create_layer(_target_inst.x, _target_inst.y - 64, popup_layer_id, obj_popup_damage);
            if (pop != noone) { pop.damage_amount = popup_text; pop.text_color = popup_color; }
        }
    }
    
    // 8. Clear Defend State
    if (variable_struct_exists(target_data, "is_defending")) target_data.is_defending = false;

    // 9. IMMEDIATE DEATH CHECK
    if (script_exists(scr_ProcessDeathIfNecessary)) {
        scr_ProcessDeathIfNecessary(_target_inst); // Check and process if dead
    }
    
    show_debug_message("--- scr_PerformAttack END ---"); 

    return true; // Attack completed (hit or killed), animation flow continues.
}