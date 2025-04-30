/// @function scr_CastSkill(user, skill, target)
/// @description Executes a skill: checks/deducts cost, applies heal/damage/status, checks death. Returns true if action used/turn consumed.
function scr_CastSkill(user, skill, target) {
    // --- <<< LOGGING: Entry Point >>> ---
    var _user_name = instance_exists(user) ? (object_get_name(user.object_index) + "["+string(user)+"], Name:"+(user.data.name ?? "??")) : "INVALID";
    var _skill_name = is_struct(skill) ? (skill.name ?? "Unnamed Skill") : "INVALID";
    var _target_name = instance_exists(target) ? (object_get_name(target.object_index) + "["+string(target)+"], Name:"+(target.data.name ?? "??")) : (target == user ? "Self" : "INVALID/NONE");
    show_debug_message("--- scr_CastSkill START --- User: " + _user_name + " | Skill: " + _skill_name + " | Target: " + _target_name); 
    // --- <<< END LOGGING >>> ---
    
    // 1) Validate Inputs
    if (!instance_exists(user) || !variable_instance_exists(user, "data") || !is_struct(user.data)) { show_debug_message("CastSkill Fail: Invalid User"); return false; }
    if (!is_struct(skill) || !variable_struct_exists(skill, "effect")) { show_debug_message("CastSkill Fail: Invalid Skill Struct"); return false; }
    var needsTarget = skill.target_type != "self" && skill.target_type != "all_allies" && skill.target_type != "all_enemies"; // Determine if a specific target instance is needed vs self/all
    var finalTarget = needsTarget ? target : user; // If targeting needed, use provided target, else default to user (for self/all)
    
    show_debug_message("  -> Needs Specific Target Instance: " + string(needsTarget) + " | Final Target Ref: " + string(finalTarget));

    // Validate final target if one is required (allow dead for revive)
    var can_target_dead = (skill.effect == "revive"); 
    if (needsTarget) { // Only validate if we actually need a specific instance
        if (!instance_exists(finalTarget)) { show_debug_message("CastSkill Fail: Target Instance does not exist."); return false; } 
        var td_check = variable_instance_get(finalTarget,"data"); // Use safe get
        if (!is_struct(td_check) || !variable_struct_exists(td_check,"hp")) { show_debug_message("CastSkill Fail: Target missing data or HP field."); return false; }
        if (td_check.hp <= 0 && !can_target_dead) { show_debug_message("CastSkill Fail: Target is Dead and skill cannot target dead."); return false; }
    }
    // Note: Target Data 'td' will be fetched inside the effect switch if needed

    var ud = user.data; // User data shortcut
    
    // 2. Cost / Usability Check 
    var cost = skill.cost ?? 0;
    var is_overdrive_skill = variable_struct_exists(skill, "overdrive") && skill.overdrive == true;
    var can_cast = false;

    if (is_overdrive_skill) {
        // ... (OD check logic remains same) ...
         if (variable_struct_exists(ud, "overdrive") && variable_struct_exists(ud, "overdrive_max")) { can_cast = (ud.overdrive >= ud.overdrive_max); } 
         else { can_cast = false; }
    } else { // Normal MP Skill
        // ... (MP check logic remains same) ...
         if (variable_struct_exists(ud, "mp")) { can_cast = (ud.mp >= cost); } 
         else { can_cast = false; }
    }

    if (!can_cast) {
        show_debug_message("  -> Usability Check FAILED. Cannot cast " + _skill_name + ".");
        show_debug_message("--- scr_CastSkill END (Failed Usability Check) ---");
        return false; 
    } else { show_debug_message("  -> Usability Check PASSED."); }

    // --- Cost Deduction ---
    if (is_overdrive_skill) { ud.overdrive = 0; show_debug_message("  -> Cost: Overdrive Consumed!"); } 
    else { ud.mp -= cost; show_debug_message("  -> Cost: Deducted MP: " + string(cost) + ". Remaining: " + string(ud.mp)); }

    // 3) Perform effect
    var applied = false; 
    var showPopup = true; 
    var popupText = ""; 
    var popupColor = c_white;

    // Blind miss check (only for single-target offensive skills?)
    // --- <<< LOGGING: Blind Check >>> ---
    var missed_by_blind = false;
    var attacker_status = script_exists(scr_GetStatus) ? scr_GetStatus(user) : undefined; 
    if (needsTarget && finalTarget != user && (skill.effect == "damage_enemy" || skill.effect == "blind" || skill.effect == "bind" || skill.effect == "shame" /* add other offensive status */) && is_struct(attacker_status) && attacker_status.effect == "blind") {
        var blind_miss_chance = 50; // Example: 50% miss chance
        show_debug_message("  -> Blind Check: User is Blind. Rolling miss chance (" + string(blind_miss_chance) + "%)...");
        if (irandom(99) < blind_miss_chance) {
            popupText = "Miss!"; applied = true; missed_by_blind = true; 
            show_debug_message("  -> Blind Check: Missed!");
        } else { show_debug_message("  -> Blind Check: Hit!"); }
    }
    // --- <<< END LOGGING >>> ---

    // If not missed by blind, apply effect
    if (!missed_by_blind) { 
        // --- <<< LOGGING: Applying Effect >>> ---
        show_debug_message("  -> Applying Effect: " + string(skill.effect ?? "N/A"));
        // --- <<< END LOGGING >>> ---
        switch (skill.effect) {
            case "heal_hp":
                // Fetch target data INSIDE the case, as finalTarget might be user or target instance
                var target_inst_heal = finalTarget; // Use the determined final target
                if (instance_exists(target_inst_heal) && variable_instance_exists(target_inst_heal,"data")) {
                    var td_heal = target_inst_heal.data;
                    if(is_struct(td_heal) && variable_struct_exists(td_heal,"hp") && variable_struct_exists(td_heal,"maxhp")) {
                        var baseHeal = skill.heal_amount ?? 0;
                        var pstatKey = skill.power_stat ?? "matk";
                        var userPower = variable_struct_get(ud, pstatKey) ?? 0;
                        var healAmt = floor(baseHeal + userPower * 0.5); // Example formula
                        var beforeHP = td_heal.hp; 
                        td_heal.hp = min(td_heal.maxhp, td_heal.hp + healAmt); 
                        var actual = td_heal.hp - beforeHP;
                        
                        // --- <<< LOGGING: Heal Details >>> ---
                        show_debug_message("    -> HEAL: Base=" + string(baseHeal) + " UserPower(" + pstatKey + ")=" + string(userPower) + " TotalCalc=" + string(healAmt));
                        show_debug_message("    -> HEAL: Target HP Before=" + string(beforeHP) + " | Target HP After=" + string(td_heal.hp) + " | Actual Heal=" + string(actual));
                        // --- <<< END LOGGING >>> ---

                        if (actual > 0) { popupText = "+" + string(actual); popupColor = c_lime; } else { popupText = "No Effect"; popupColor = c_gray; } 
                        applied = true;
                    } else { applied = false; show_debug_message("    -> HEAL Fail: Target data invalid (hp/maxhp)."); }
                } else { applied = false; show_debug_message("    -> HEAL Fail: Target instance invalid."); }
                break;

            case "damage_enemy": 
                // Fetch target data INSIDE the case
                 var target_inst_dmg = finalTarget; // Should be the enemy instance passed in 'target'
                 if (instance_exists(target_inst_dmg) && variable_instance_exists(target_inst_dmg,"data")) {
                    var td_dmg = target_inst_dmg.data;
                    if (is_struct(td_dmg) && variable_struct_exists(td_dmg,"hp")) {
                        var attack_element = skill.element ?? "physical"; 
                        var baseDmg = skill.damage ?? 0;
                        var pstatKey = skill.power_stat ?? "matk"; 
                        var atkPower = variable_struct_get(ud, pstatKey) ?? 0;
                        var defKey = (pstatKey == "matk") ? "mdef" : "def"; 
                        var tgtDef = variable_struct_get(td_dmg, defKey) ?? 0;
                        var calculated_damage = max(1, baseDmg + atkPower - tgtDef); // Example formula
                        if (variable_struct_get(td_dmg, "is_defending") ?? false) calculated_damage = max(1, floor(calculated_damage / 2));
                        var resistance_multiplier = 1.0;
                        if (script_exists(GetResistanceMultiplier) && variable_struct_exists(td_dmg, "resistances")) { resistance_multiplier = GetResistanceMultiplier(td_dmg.resistances, attack_element); }
                        var final_damage = max(0, floor(calculated_damage * resistance_multiplier)); // Allow 0 damage
                        if (calculated_damage >= 1 && resistance_multiplier > 0 && final_damage == 0) final_damage = 1; // Ensure minimum 1 damage unless immune/resisted to 0
                        
                        var old_hp_dmg = td_dmg.hp; 
                        td_dmg.hp = max(0, td_dmg.hp - final_damage); 
                        var actual_dmg = old_hp_dmg - td_dmg.hp; // Calculate actual damage dealt

                        // --- <<< LOGGING: Damage Details >>> ---
                        show_debug_message("    -> DAMAGE: Base=" + string(baseDmg) + " UserPower(" + pstatKey + ")=" + string(atkPower) + " TgtDef(" + defKey + ")=" + string(tgtDef));
                        show_debug_message("    -> DAMAGE: CalcDmg=" + string(calculated_damage) + " ResistMult=" + string(resistance_multiplier) + " FinalDmg=" + string(final_damage));
                        show_debug_message("    -> DAMAGE: Target HP Before=" + string(old_hp_dmg) + " | Target HP After=" + string(td_dmg.hp) + " | Actual Dmg=" + string(actual_dmg));
                        // --- <<< END LOGGING >>> ---

                        popupText = string(final_damage); popupColor = c_white; 
                        if (resistance_multiplier <= 0) { popupText = "Immune"; popupColor = c_gray; } 
                        else if (resistance_multiplier < 0.9) { popupText += " (Resist)"; popupColor = c_aqua; } 
                        else if (resistance_multiplier > 1.1) { popupText += " (Weak!)"; popupColor = c_yellow; }
                        applied = true;
                        if (script_exists(scr_ProcessDeathIfNecessary)) { scr_ProcessDeathIfNecessary(finalTarget); }
                        if (variable_struct_exists(td_dmg, "is_defending")) td_dmg.is_defending = false;
                    } else { applied = false; show_debug_message("    -> DAMAGE Fail: Target data invalid (hp).");}
                 } else { applied = false; show_debug_message("    -> DAMAGE Fail: Target instance invalid.");}
                break;

            case "blind": case "bind": case "shame": case "poison": case "regen": case "haste": case "slow":
                // ... (Status effect logic remains same, assumes scr_ApplyStatus works) ...
                 var dur = variable_struct_exists(skill, "duration") ? skill.duration : 3;
                 if (script_exists(scr_ApplyStatus)) { 
                     applied = scr_ApplyStatus(finalTarget, skill.effect, dur); // Check return value? Assume true for now.
                      if (applied) { /* Set popup */ } else { /* Failed to apply? */ }
                 } else { applied = false; }
                 break;
                 
            // Add case "revive" etc.
            
            default:
                 show_debug_message("⚠️ CastSkill: Unknown effect '" + string(skill.effect) + "'");
                 applied = true; showPopup = false;
                 break;
        } 
    } // End if !missed_by_blind

    // --- Popup ---
    if (applied && showPopup && popupText != "" && object_exists(obj_popup_damage) && instance_exists(finalTarget)) {
         // ... (Create popup logic remains same) ...
         var pop = instance_create_layer(finalTarget.x, finalTarget.y - 64, layer_get_id("Instances"), obj_popup_damage);
         if (pop != noone) { pop.damage_amount = popupText; pop.text_color = popupColor; }
    }

    // --- <<< LOGGING: Exit Point >>> ---
    show_debug_message("--- scr_CastSkill END --- User: " + _user_name + " | Skill: " + _skill_name + " | Target: " + _target_name + " | Action Applied Flag: " + string(applied)); 
    // --- <<< END LOGGING >>> ---
    
    return applied; // Return true if the action sequence completed (even if missed/resisted), false only on usability fail
}