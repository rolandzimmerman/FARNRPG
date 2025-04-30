/// @function scr_PerformAttack(_attacker_inst, _target_inst)
/// @description Calculates and applies damage for a basic attack, including element/resistance. Called BY the attacker instance during its attack animation state.
/// @param {Id.Instance} _attacker_inst The instance performing the attack.
/// @param {Id.Instance} _target_inst The instance being attacked.
/// @returns {Bool} True if damage was applied or missed, False if target/attacker invalid pre-attack.
function scr_PerformAttack(_attacker_inst, _target_inst) {
    // --- <<< LOGGING: Entry Point >>> ---
    // Safely get names for logging
    var _user_name = "INVALID";
    if (instance_exists(_attacker_inst) && variable_instance_exists(_attacker_inst,"data") && is_struct(_attacker_inst.data)) { _user_name = object_get_name(_attacker_inst.object_index) + "["+string(_attacker_inst)+"], Name:"+(_attacker_inst.data.name ?? "??"); }
    var _target_name = "INVALID/NONE";
    if (instance_exists(_target_inst) && variable_instance_exists(_target_inst,"data") && is_struct(_target_inst.data)) { _target_name = object_get_name(_target_inst.object_index) + "["+string(_target_inst)+"], Name:"+(_target_inst.data.name ?? "??"); }
    show_debug_message("--- scr_PerformAttack START --- Attacker: " + _user_name + " | Target: " + _target_name); 
    // --- <<< END LOGGING >>> ---
     
    // 1. Validate Attacker & Target
    if (!instance_exists(_attacker_inst) || !variable_instance_exists(_attacker_inst, "data") || !is_struct(_attacker_inst.data)) {show_debug_message("PerformAttack Fail: Invalid Attacker Data"); return false;}
    if (!instance_exists(_target_inst) || !variable_instance_exists(_target_inst, "data") || !is_struct(_target_inst.data)) {show_debug_message("PerformAttack Fail: Invalid Target Data"); return false;}
    
    var attacker_data = _attacker_inst.data;
    var target_data = _target_inst.data;

    // Cannot target dead units
    if (!variable_struct_exists(target_data,"hp")) { show_debug_message("PerformAttack Fail: Target missing HP field."); return false; }
    if (target_data.hp <= 0) { show_debug_message("PerformAttack Fail: Target already has 0 HP."); return false; } // Fail the action if target already dead
    
    show_debug_message("  -> Validation PASSED."); // Log validation success

    // --- Get Attack Element from Weapon ---
    var attack_fx_info = { sprite: spr_pow, sound: snd_punch, element: "physical" }; // Default values
    if (script_exists(scr_GetWeaponAttackFX)) {
        attack_fx_info = scr_GetWeaponAttackFX(_attacker_inst); 
        show_debug_message("  -> Got FX info from scr_GetWeaponAttackFX.");
    } else { show_debug_message("  -> WARNING: scr_GetWeaponAttackFX missing, using defaults.");}
    var attack_element = attack_fx_info.element ?? "physical"; // Ensure element has a fallback
    show_debug_message("  -> Attack Element: " + attack_element); 

    // --- Fill Overdrive ---
    if (variable_struct_exists(attacker_data, "overdrive") && variable_struct_exists(attacker_data, "overdrive_max")) {
        var _od_before = attacker_data.overdrive;
        attacker_data.overdrive = min(attacker_data.overdrive + 5, attacker_data.overdrive_max); // Example: Gain 5 OD per attack
        show_debug_message("  -> Overdrive Gain: " + string(_od_before) + " -> " + string(attacker_data.overdrive)); 
    } else { show_debug_message("  -> Overdrive Gain: Attacker missing OD variables."); }
     
    // 3. Blind check
    var missed_by_blind = false; 
    var attacker_status = script_exists(scr_GetStatus) ? scr_GetStatus(_attacker_inst) : undefined; 
    if (is_struct(attacker_status) && attacker_status.effect == "blind") {
        var blind_miss_chance = 50; 
        show_debug_message("  -> Blind Check: Attacker is Blind. Rolling miss chance (" + string(blind_miss_chance) + "%)...");
        if (irandom(99) < blind_miss_chance) {
             show_debug_message("  -> Blind Check: Missed!");
             missed_by_blind = true; 
            if (object_exists(obj_popup_damage)) { 
                 var _layer_id = layer_get_id("Instances");
                 if (_layer_id != -1) {
                     var miss_pop = instance_create_layer(_target_inst.x, _target_inst.y - 64, _layer_id, obj_popup_damage);
                     if (miss_pop != noone) miss_pop.damage_amount = "Miss!";
                 }
            }
            show_debug_message("--- scr_PerformAttack END (Missed due to Blind) ---"); 
             return true; // Missed, but turn consumed
        } else { show_debug_message("  -> Blind Check: Hit!"); }
    }

    // 4. Calculate Base Damage
    var atk_stat = variable_struct_get(attacker_data, "atk") ?? 1; // Safe get
    var def_stat = variable_struct_get(target_data, "def") ?? 0;   // Safe get
    var base_damage = max(1, atk_stat - def_stat); // Ensure at least 1 before defense reduction
    var target_defending = variable_struct_get(target_data, "is_defending") ?? false; // Safe get
    if (target_defending) { base_damage = max(1, floor(base_damage / 2)); }
    show_debug_message("  -> Damage Calc: Attacker ATK=" + string(atk_stat) + ", Target DEF=" + string(def_stat) + ", Target Defending=" + string(target_defending) + " => Base Damage=" + string(base_damage));
    
    // 5. Apply Elemental Resistance Multiplier
    var resistance_multiplier = 1.0;
    if (script_exists(GetResistanceMultiplier) && variable_struct_exists(target_data, "resistances")) { 
        resistance_multiplier = GetResistanceMultiplier(target_data.resistances, attack_element); 
    } 
    show_debug_message("  -> Damage Calc: Resistance Multiplier (" + attack_element + ") = " + string(resistance_multiplier));
    
    var final_damage = floor(base_damage * resistance_multiplier);
    
    // Minimum Damage Fix (Allow 0 only if immune/resisted to <1)
    if (base_damage >= 1 && resistance_multiplier > 0) { final_damage = max(1, final_damage); } 
    else { final_damage = max(0, final_damage); } 
    show_debug_message("  -> Damage Calc: Final Damage = " + string(final_damage));

    // 6. Apply Final Damage
    var old_hp = target_data.hp;
    target_data.hp = max(0, target_data.hp - final_damage);
    var actual_dmg = old_hp - target_data.hp; 
    show_debug_message("  -> HP Change: Target HP Before=" + string(old_hp) + " | Damage Applied=" + string(final_damage) + " | Actual HP Change=" + string(actual_dmg) + " | Target HP After=" + string(target_data.hp));
                        
    // 7. Damage Popup 
    var popup_text = string(final_damage);
    var popup_color = c_white;
    if (resistance_multiplier <= 0 && final_damage == 0) { popup_text = "Immune"; popup_color = c_gray; } 
    else if (resistance_multiplier < 0.9 && final_damage > 0) { popup_text += " (Resist)"; popup_color = c_aqua; } // Only show resist if damage > 0
    else if (resistance_multiplier > 1.1) { popup_text += " (Weak!)"; popup_color = c_yellow; }
    
    if (object_exists(obj_popup_damage)) { /* ... create damage popup ... */ }
    
    // 8. Clear Defend State
    if (target_defending) { 
        target_data.is_defending = false; 
        show_debug_message("  -> Cleared target's Defend state."); 
    }

    // 9. IMMEDIATE DEATH CHECK
    if (script_exists(scr_ProcessDeathIfNecessary)) {
        scr_ProcessDeathIfNecessary(_target_inst); 
    }
    
    show_debug_message("--- scr_PerformAttack END --- Attacker: " + _user_name + " | Target: " + _target_name + " | Action Completed: true"); 

    return true; // Attack completed (hit or killed)
}