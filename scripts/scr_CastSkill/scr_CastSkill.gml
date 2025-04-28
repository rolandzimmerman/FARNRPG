/// @function scr_CastSkill(user, skill, target)
/// @description Executes a skill: checks/deducts cost, applies heal/damage/status, checks death. Returns true if action used/turn consumed.
/// NOTE: Triggered by Combatant State Machine during "attack_start".
function scr_CastSkill(user, skill, target) {
    show_debug_message("--- scr_CastSkill START --- User: " + string(user) + " Skill: " + (skill.name ?? "STRUCT") + " Target: " + string(target)); // Added more info to start log
    
    // 1) Validate Inputs
    if (!instance_exists(user) || !variable_instance_exists(user, "data") || !is_struct(user.data)) { show_debug_message("CastSkill Fail: Invalid User"); return false; }
    if (!is_struct(skill) || !variable_struct_exists(skill, "effect")) { show_debug_message("CastSkill Fail: Invalid Skill Struct"); return false; }
    var needsTarget = variable_struct_exists(skill, "requires_target") ? skill.requires_target : true;
    var finalTarget = needsTarget ? target : user; // Determine actual target
    
    // Validate final target - Allow targeting dead only for specific effects like "revive"
    var can_target_dead = (skill.effect == "revive"); // Add other effects if needed
    if (!instance_exists(finalTarget)) { 
        show_debug_message("CastSkill Fail: Target Instance does not exist."); 
        return false; 
    } 
    var td = (variable_instance_exists(finalTarget, "data") && is_struct(finalTarget.data)) ? finalTarget.data : noone;
    if (!is_struct(td)) { 
         show_debug_message("CastSkill Fail: Target data struct missing."); 
         return false; // Target must have data
    }
    if (!variable_struct_exists(td,"hp")) {
         show_debug_message("CastSkill Fail: Target data missing HP field."); 
         return false; // Target must have HP
    }
    if (td.hp <= 0 && !can_target_dead) { 
        show_debug_message("CastSkill Fail: Target is Dead and skill cannot target dead."); 
        return false; // Fail action if targeting dead unit (unless allowed)
    }

    var ud = user.data; // User data shortcut
   
    // 2. Cost / Usability Check 
    var cost = skill.cost ?? 0;
    var is_overdrive_skill = variable_struct_exists(skill, "overdrive") && skill.overdrive == true;
    var can_cast = false;

    if (is_overdrive_skill) {
         if (variable_struct_exists(ud, "overdrive") && variable_struct_exists(ud, "overdrive_max")) {
             can_cast = (ud.overdrive >= ud.overdrive_max);
             if (!can_cast) show_debug_message(" -> CastSkill Check: Not enough OD. Have " + string(ud.overdrive) + ", Need " + string(ud.overdrive_max));
         } else { show_debug_message(" -> CastSkill Check: Player missing OD vars."); can_cast = false;} // Ensure can_cast is false
    } else { // Normal MP Skill
         if (variable_struct_exists(ud, "mp")) {
             can_cast = (ud.mp >= cost);
             if (!can_cast) show_debug_message(" -> CastSkill Check: Not enough MP. Have " + string(ud.mp) + ", Need " + string(cost));
         } else { show_debug_message(" -> CastSkill Check: Player missing MP var."); can_cast = false; } // Ensure can_cast is false
    }

    // If cannot cast, exit the script returning false (action failed)
    if (!can_cast) {
         show_debug_message("--- scr_CastSkill END (Failed Usability Check) ---");
         return false; 
    }

    // --- <<< COST DEDUCTION >>> ---
    // Deduct cost now that we know the skill can be used
    if (is_overdrive_skill) {
         if (variable_struct_exists(ud, "overdrive")) {
             ud.overdrive = 0; // Consume Overdrive (Set to 0)
             show_debug_message(" -> CastSkill: Overdrive Consumed!");
         }
    } else {
         if (variable_struct_exists(ud, "mp")) {
              ud.mp -= cost; // Deduct MP Cost
              show_debug_message(" -> CastSkill: Deducted MP: " + string(cost) + ". Remaining: " + string(ud.mp));
         }
    }
    // --- <<< END COST DEDUCTION >>> ---


    // 3) Perform effect
    var applied = false; // Tracks if the effect logic was successfully applied (or missed)
    var showPopup = true; 
    var popupText = ""; 
    var popupColor = c_white;

    // Blind miss check (only for skills that require a target different from self)
    var attacker_status = script_exists(scr_GetStatus) ? scr_GetStatus(user) : undefined; 
    if (needsTarget && finalTarget != user && is_struct(attacker_status) && attacker_status.effect == "blind" && irandom(99) < 50) {
         popupText = "Miss!"; applied = true; 
         show_debug_message(" -> CastSkill: Missed due to Blind!");
    }

    // If not missed, attempt to apply the actual effect
    if (!applied) { 
        switch (skill.effect) {
            case "heal_hp":
                // (Ensure td is still valid, though checked earlier)
                if (is_struct(td) && variable_struct_exists(td, "hp") && variable_struct_exists(td, "maxhp")) {
                    var baseHeal  = variable_struct_exists(skill, "heal_amount") ? skill.heal_amount : 0;
                    var pstatKey  = variable_struct_exists(skill, "power_stat") ? skill.power_stat : "matk";
                    var userPower = variable_struct_exists(ud, pstatKey) ? variable_struct_get(ud, pstatKey) : 0;
                    var healAmt   = floor(baseHeal + userPower * 0.5); 
                    var beforeHP  = td.hp; td.hp = min(td.maxhp, td.hp + healAmt); var actual = td.hp - beforeHP;
                    if (actual > 0) { popupText = "+" + string(actual); popupColor = c_lime; } else { showPopup = false; } 
                    applied = true;
                } else applied = false; 
                break;

            case "damage_enemy": 
                 if (is_struct(td) && variable_struct_exists(td, "hp")) {
                    var attack_element = variable_struct_exists(skill, "element") ? skill.element : "physical";                     
                    var baseDmg = variable_struct_exists(skill, "damage") ? skill.damage : 0;
                    var pstatKey = variable_struct_exists(skill, "power_stat") ? skill.power_stat : "matk"; 
                    var atkPower = variable_struct_exists(ud, pstatKey) ? variable_struct_get(ud, pstatKey) : 0;
                    var defKey = (pstatKey == "matk") ? "mdef" : "def"; 
                    var tgtDef = variable_struct_exists(td, defKey) ? variable_struct_get(td, defKey) : 0;
                    var calculated_damage = max(1, baseDmg + atkPower - tgtDef);
                    if (variable_struct_exists(td, "is_defending") && td.is_defending) calculated_damage = max(1, floor(calculated_damage / 2));
                    var resistance_multiplier = 1.0;
                     if (script_exists(GetResistanceMultiplier) && variable_struct_exists(td, "resistances")) { resistance_multiplier = GetResistanceMultiplier(td.resistances, attack_element); }
                     var final_damage = floor(calculated_damage * resistance_multiplier); 
                     if (calculated_damage >= 1 && resistance_multiplier > 0) { final_damage = max(1, final_damage); } else { final_damage = max(0, final_damage); } // Min damage
                     var old_hp_dmg = td.hp; td.hp = max(0, td.hp - final_damage); 
                    
                     popupText = string(final_damage); popupColor = c_white; 
                     if (resistance_multiplier <= 0) { popupText = "Immune"; popupColor = c_gray; } else if (resistance_multiplier < 0.9) { popupText += " (Resist)"; popupColor = c_aqua; } else if (resistance_multiplier > 1.1) { popupText += " (Weak!)"; popupColor = c_yellow; }
                    applied = true;
                    show_debug_message(" -> Skill '" + (skill.name ?? "???") + "' dealt " + string(final_damage) + " ("+attack_element+") to " + string(finalTarget) + ". HP: " + string(old_hp_dmg) + " -> " + string(td.hp));
                    if (script_exists(scr_ProcessDeathIfNecessary)) { scr_ProcessDeathIfNecessary(finalTarget); }
                    if (variable_struct_exists(td, "is_defending")) td.is_defending = false;
                 } else applied = false; 
                 break;

            case "blind": case "bind": case "shame": case "poison": case "regen": case "haste": case "slow":
                 var dur = variable_struct_exists(skill, "duration") ? skill.duration : 3;
                 if (script_exists(scr_ApplyStatus)) { 
                      scr_ApplyStatus(finalTarget, skill.effect, dur); 
                      // Set popup text/color for status
                      var effName = string_upper(string_char_at(skill.effect, 1)) + string_copy(skill.effect, 2, string_length(skill.effect)-1);
                      popupText  = effName + "!";
                      if (skill.effect == "poison" || skill.effect == "blind" || skill.effect == "bind" || skill.effect == "shame" || skill.effect == "slow") popupColor = c_fuchsia;
                      else if (skill.effect == "regen" || skill.effect == "haste") popupColor = c_aqua; 
                      applied = true; 
                 } else { applied = false; show_debug_message("ERROR: scr_ApplyStatus script missing!"); }
                 break;
                 
             // Add case "revive" here if needed

            default:
                show_debug_message("⚠️ CastSkill: Unknown effect '" + string(skill.effect) + "'");
                applied = true; // Still counts as turn used even if unknown
                showPopup = false;
                break;
        } 
    } // End if !applied (miss check)

    // --- Popup ---
    // Create popup if the action was applied (hit/miss/status) and should show one
    if (applied && showPopup && popupText != "" && object_exists(obj_popup_damage) && instance_exists(finalTarget)) {
        var popup_layer_id = layer_get_id("Instances");
        if(popup_layer_id != -1) {
             var pop = instance_create_layer(finalTarget.x, finalTarget.y - 64, popup_layer_id, obj_popup_damage);
             if (pop != noone) { pop.damage_amount = popupText; pop.text_color = popupColor; }
        }
    }

    show_debug_message("--- scr_CastSkill END --- (Action Applied: " + string(applied) + ")"); 
    
    // Return true if the action was performed (even if missed), false only if usability check failed initially
    return applied; 
}