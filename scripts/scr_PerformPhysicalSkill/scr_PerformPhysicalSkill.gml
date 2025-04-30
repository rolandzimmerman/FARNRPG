/// @function scr_PerformPhysicalSkill(_user_inst, _skill_struct, _target_inst)
/// @description Calculates and applies damage/effects for a SKILL designated as physical. Returns true if action completed (hit/miss).
/// @param {Id.Instance} _user_inst The instance performing the skill.
/// @param {Struct} _skill_struct The skill data struct.
/// @param {Id.Instance} _target_inst The instance being targeted.
/// @returns {Bool} True if the action sequence completed (hit or miss), False if validation failed.
function scr_PerformPhysicalSkill(_user_inst, _skill_struct, _target_inst) {
    
    // --- Safely get names for Logging ---
    var _user_name = instance_exists(_user_inst) ? (variable_instance_get(_user_inst,"data").name ?? "User?") : "Invalid";
    var _target_name = instance_exists(_target_inst) ? (variable_instance_get(_target_inst,"data").name ?? "Target?") : "Invalid";
    var _skill_name = is_struct(_skill_struct) ? (_skill_struct.name ?? "Skill?") : "Invalid";
    show_debug_message("--- scr_PerformPhysicalSkill START --- User: " + _user_name + " | Skill: " + _skill_name + " | Target: " + _target_name); 

    // 1. Validate Inputs
    if (!instance_exists(_user_inst) || !variable_instance_exists(_user_inst, "data") || !is_struct(_user_inst.data)) {show_debug_message("PhysSkill Fail: Invalid User"); return false;}
    if (!instance_exists(_target_inst) || !variable_instance_exists(_target_inst, "data") || !is_struct(_target_inst.data)) {show_debug_message("PhysSkill Fail: Invalid Target"); return false;}
    if (!is_struct(_skill_struct) || !variable_struct_exists(_skill_struct, "effect")) { show_debug_message("PhysSkill Fail: Invalid Skill Struct"); return false; }
    
    var attacker_data = _user_inst.data;
    var target_data = _target_inst.data;

    // Cannot target dead units (unless maybe a specific physical revive skill?)
    if (!variable_struct_exists(target_data,"hp")) { show_debug_message("PhysSkill Fail: Target missing HP field."); return false; }
    if (target_data.hp <= 0) { show_debug_message("PhysSkill Fail: Target already has 0 HP."); return false; } 

    show_debug_message("  -> Validation PASSED."); 

    // --- Declare variables needed for hit/miss/popup ---
    var applied = false; // Will be set to true if action completes (hit or miss)
    var missed_by_blind = false; 
    var showPopup = true; 
    var popupText = ""; 
    var popupColor = c_white;

    // 2. Blind check
    var attacker_status = script_exists(scr_GetStatus) ? scr_GetStatus(_user_inst) : undefined; 
    if (is_struct(attacker_status) && attacker_status.effect == "blind") {
        var blind_miss_chance = 50; // Example 50% miss
        show_debug_message("  -> Blind Check: Attacker is Blind. Rolling miss chance (" + string(blind_miss_chance) + "%)...");
        if (irandom(99) < blind_miss_chance) {
             show_debug_message("  -> Blind Check: Missed!");
             missed_by_blind = true; 
             popupText = "Miss!"; // Set text for popup
             applied = true;    // Mark action as completed (a miss is still an action)
             // DO NOT return here anymore
        } else { 
             show_debug_message("  -> Blind Check: Hit!"); 
             missed_by_blind = false;
        }
    }
    
    // 3. Calculate and Apply Damage (Only if not missed by blind)
    if (!missed_by_blind) {
        show_debug_message("  -> Applying Damage/Effects...");
        
        // Use power_stat from skill, default to "atk"
        var power_stat = variable_struct_get(_skill_struct, "power_stat") ?? "atk"; 
        var atk_stat = variable_struct_get(attacker_data, power_stat) ?? 1; 
        var def_stat = variable_struct_get(target_data, "def") ?? 0; // Physical skills use DEF
        var base_skill_dmg = variable_struct_get(_skill_struct, "damage") ?? 0; 
        
        // Calculate base damage combining skill base and user stat vs target def
        var base_damage = max(1, base_skill_dmg + atk_stat - def_stat); 
        
        // Check if target is defending
        var target_defending = variable_struct_get(target_data, "is_defending") ?? false;
        if (target_defending) { base_damage = max(1, floor(base_damage / 2)); }
        show_debug_message("    -> Damage Calc: SkillDmg=" + string(base_skill_dmg) + " AttackerStat(" + power_stat + ")=" + string(atk_stat) + ", Target DEF=" + string(def_stat) + ", Defending=" + string(target_defending) + " => Base Damage=" + string(base_damage));

        // Apply Elemental Resistance using element from skill
        var attack_element = variable_struct_get(_skill_struct, "element") ?? "physical"; 
        var resistance_multiplier = 1.0;
        if (script_exists(GetResistanceMultiplier) && variable_struct_exists(target_data, "resistances")) { resistance_multiplier = GetResistanceMultiplier(target_data.resistances, attack_element); } 
        show_debug_message("    -> Damage Calc: Resistance Multiplier (" + attack_element + ") = " + string(resistance_multiplier));
        
        var final_damage = max(0, floor(base_damage * resistance_multiplier)); 
        // Apply Minimum Damage Rule
        if (base_damage >= 1 && resistance_multiplier > 0 && final_damage == 0) final_damage = 1; 
        show_debug_message("    -> Damage Calc: Final Damage = " + string(final_damage));

        // Apply Damage to Target HP
        var old_hp = target_data.hp;
        target_data.hp = max(0, target_data.hp - final_damage);
        var actual_dmg = old_hp - target_data.hp; 
        show_debug_message("    -> HP Change: Target HP Before=" + string(old_hp) + " | Dmg Applied=" + string(final_damage) + " | Actual Change=" + string(actual_dmg) + " | Target HP After=" + string(target_data.hp));

        // Set popup text for damage
        popupText = string(final_damage); popupColor = c_white; 
        if (resistance_multiplier <= 0 && final_damage == 0) { popupText = "Immune"; popupColor = c_gray; } 
        else if (resistance_multiplier < 0.9) { popupText += " (Resist)"; popupColor = c_aqua; } 
        else if (resistance_multiplier > 1.1) { popupText += " (Weak!)"; popupColor = c_yellow; }

        // Apply Status Effect from skill (if any)
        if (variable_struct_exists(_skill_struct, "status_effect")) {
             var chance = variable_struct_get(_skill_struct, "status_chance") ?? 1.0; 
             if (random(1.0) < chance) {
                 var status_effect = _skill_struct.status_effect;
                 var status_duration = variable_struct_get(_skill_struct, "status_duration") ?? 3;
                 if (script_exists(scr_ApplyStatus)) {
                     show_debug_message("    -> PhysSkill: Attempting to apply status '" + status_effect + "'");
                     scr_ApplyStatus(_target_inst, status_effect, status_duration);
                     // Maybe add status to popup? e.g. popupText += " +Slow!";
                 }
             } else { show_debug_message("    -> PhysSkill: Status effect chance failed."); }
        }
        
        // Clear Defend State if target was defending
        if (target_defending) { target_data.is_defending = false; show_debug_message("    -> Cleared target's Defend state."); }
        
        // IMMEDIATE DEATH CHECK for target
        if (script_exists(scr_ProcessDeathIfNecessary)) { scr_ProcessDeathIfNecessary(_target_inst); }
        
        applied = true; // Mark action as applied since damage/status attempt occurred
    } // End if !missed_by_blind
    
    // --- Create Popup ---
    if (applied && showPopup && popupText != "" && object_exists(obj_popup_damage) && instance_exists(_target_inst)) {
         var popup_layer_id = layer_get_id("Instances"); // Or other layer if needed
         if(popup_layer_id != -1){
              var pop = instance_create_layer(_target_inst.x, _target_inst.y - 64, popup_layer_id, obj_popup_damage);
              if (pop != noone) { pop.damage_amount = popupText; pop.text_color = popupColor; }
         }
    }

    show_debug_message("--- scr_PerformPhysicalSkill END --- | Action Applied Flag: " + string(applied)); 
    
    // Return true IF the action sequence happened (even if it missed)
    // Return false only if initial validation failed
    return applied; 
}