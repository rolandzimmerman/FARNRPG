/// @function scr_CastSkill(user, skill, target)
/// @description Executes a skill: spends MP, applies heal/damage/status, fills/consumes Overdrive, returns true if action used.
function scr_CastSkill(user, skill, target) {
    // 1) Validate Inputs
    if (!instance_exists(user) || !variable_instance_exists(user, "data") || !is_struct(user.data)) return false;
    if (!is_struct(skill) || !variable_struct_exists(skill, "effect")) return false;
    var needsTarget = variable_struct_exists(skill, "requires_target") ? skill.requires_target : true;
    var finalTarget = needsTarget ? target : user; // Determine actual target
    // Validate final target now
    if (!instance_exists(finalTarget)) return false; 
    // Check if target is already dead if applying harmful effect
    var td = (variable_instance_exists(finalTarget, "data") && is_struct(finalTarget.data)) ? finalTarget.data : noone;
    if (needsTarget && is_struct(td) && td.hp <= 0 && skill.effect != "revive") { // Example: Allow targeting dead for revive
         show_debug_message("Warning [CastSkill]: Target has 0 HP.");
         return false; // Fail action if targeting dead unit (unless it's revive etc)
    }


    var ud = user.data;
   
    // 2) Status interrupts (moved to manager, can remove here or leave as backup)
    // var status = script_exists(scr_GetStatus) ? scr_GetStatus(user) : undefined;
    // if (is_struct(status)) { ... }

    // 3) Overdrive-skill check
    if (variable_struct_exists(skill, "overdrive") && skill.overdrive) {
        if (!variable_struct_exists(ud, "overdrive") || ud.overdrive < ud.overdrive_max) { // Check var exists
            show_debug_message(" -> Overdrive not ready.");
            return false;
        }
    }

    // 4) MP cost
    var cost = variable_struct_exists(skill, "cost") ? skill.cost : 0;
     if (!variable_struct_exists(ud, "mp") || ud.mp < cost) { // Check var exists
        show_debug_message(" -> CastSkill: Not enough MP!");
        return false;
     }
    // Deduct cost only after checks pass
    ud.mp -= cost;
    show_debug_message(" -> CastSkill: MP after deduction: " + string(ud.mp));

    // 5) Perform effect
    var applied = false; // Track if effect logic ran
    var showPopup = true;
    var popupText = "";
    var popupColor = c_white;

    // Blind miss check (only if needs target and is not self?)
     var attacker_status = script_exists(scr_GetStatus) ? scr_GetStatus(user) : undefined; // Use GetStatus
     if (needsTarget && finalTarget != user && is_struct(attacker_status) && attacker_status.effect == "blind" && irandom(99) < 50) {
         popupText = "Miss!";
         applied   = true; // Turn is used even on miss
     }

    if (!applied) { // If not missed due to blind
        switch (skill.effect) {
            case "heal_hp":
                if (is_struct(td) && variable_struct_exists(td, "hp") && variable_struct_exists(td, "maxhp")) {
                    var baseHeal  = variable_struct_exists(skill, "heal_amount") ? skill.heal_amount : 0;
                    var pstatKey  = variable_struct_exists(skill, "power_stat") ? skill.power_stat : "matk";
                    var userPower = variable_struct_exists(ud, pstatKey) ? variable_struct_get(ud, pstatKey) : 0;
                    var healAmt   = floor(baseHeal + userPower * 0.5); // Example scaling
                    var beforeHP  = td.hp;
                    td.hp         = min(td.maxhp, td.hp + healAmt);
                    var actual    = td.hp - beforeHP;
                    if (actual > 0) { popupText = "+" + string(actual); popupColor = c_lime; } 
                    else { showPopup = false; } // Don't show +0
                    applied = true;
                } else applied = false; // Failed if target invalid
                break;

            case "damage_enemy": // Assuming skills named this always target enemies
                 // Double check target is actually enemy? Or trust caller?
                if (is_struct(td) && variable_struct_exists(td, "hp")) {
                    var baseDmg   = variable_struct_exists(skill, "damage") ? skill.damage : 0;
                    var pstatKey  = variable_struct_exists(skill, "power_stat") ? skill.power_stat : "atk";
                    var atkPower  = variable_struct_exists(ud, pstatKey) ? variable_struct_get(ud, pstatKey) : 0;
                    var defKey    = (pstatKey == "matk") ? "mdef" : "def";
                    var tgtDef    = variable_struct_exists(td, defKey) ? variable_struct_get(td, defKey) : 0;
                    var dmg       = max(1, baseDmg + atkPower - tgtDef);
                    if (variable_struct_exists(td, "is_defending") && td.is_defending) dmg = max(1, floor(dmg / 2));
                    
                    var old_hp_dmg = td.hp; // Store hp before damage
                    td.hp = max(0, td.hp - dmg); // Apply damage
                    
                    popupText  = string(dmg);
                    popupColor = c_white;
                    applied    = true;
                    
                    show_debug_message(" -> Skill '" + skill.name + "' dealt " + string(dmg) + " to " + string(finalTarget) + ". HP: " + string(old_hp_dmg) + " -> " + string(td.hp));
                     
                    // IMMEDIATE DEATH CHECK for damage skills
                    if (script_exists(scr_ProcessDeathIfNecessary)) {
                        scr_ProcessDeathIfNecessary(finalTarget); 
                    }
                    // Clear target defend state if hit
                    if (variable_struct_exists(td, "is_defending")) td.is_defending = false;

                } else applied = false; // Failed if target invalid
                break;

            // Status Effects (Blind, Bind, Shame, Poison, Regen, Haste, Slow etc)
            case "blind": case "bind": case "shame": case "poison": case "regen": case "haste": case "slow":
                 // Add more statuses here if needed
                var dur = variable_struct_exists(skill, "duration") ? skill.duration : 3;
                if (script_exists(scr_ApplyStatus)) {
                    scr_ApplyStatus(finalTarget, skill.effect, dur);
                    // Generate popup text (capitalize first letter)
                     var effName = string_upper(string_char_at(skill.effect, 1)) + string_copy(skill.effect, 2, string_length(skill.effect)-1);
                     popupText  = effName + "!";
                     // Choose color based on effect type?
                     if (skill.effect == "poison" || skill.effect == "blind" || skill.effect == "bind" || skill.effect == "shame" || skill.effect == "slow") popupColor = c_fuchsia;
                     else if (skill.effect == "regen" || skill.effect == "haste") popupColor = c_aqua; 
                     
                    applied    = true;
                } else applied = false; // Failed if script missing
                break;

            default:
                show_debug_message("⚠️ CastSkill: Unknown effect '" + string(skill.effect) + "'");
                applied   = true; // Consume turn even if effect unknown
                showPopup = false;
                break;
        }
    } // End if !applied (miss check)

    // 6) Overdrive fill for normal skills (only if action applied/missed)
    if (applied && (!variable_struct_exists(skill, "overdrive") || !skill.overdrive)) {
         if (variable_struct_exists(ud, "overdrive")) { // Check exists before modifying
             ud.overdrive = min(ud.overdrive + 10, ud.overdrive_max); // Example OD gain
             show_debug_message(" -> Overdrive now " + string(ud.overdrive));
         }
    }

    // 7) Popup
    if (applied && showPopup && popupText != "" && object_exists(obj_popup_damage) && instance_exists(finalTarget)) {
        var pop = instance_create_layer(finalTarget.x, finalTarget.y - 64, "Instances", obj_popup_damage);
        if (pop != noone) {
            pop.damage_amount = popupText;
            pop.text_color    = popupColor;
        }
    }

    // 8) Consume Overdrive if used (only if action applied)
    if (applied && variable_struct_exists(skill, "overdrive") && skill.overdrive) {
        ud.overdrive = 0;
        show_debug_message(" -> Overdrive consumed!");
    }

    // Return true if the turn was used (action applied or missed), false if it failed before execution (e.g., no MP)
    return applied; 
}