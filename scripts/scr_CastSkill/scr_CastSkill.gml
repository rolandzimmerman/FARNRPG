/// @function scr_CastSkill(user, skill, target)
/// @description Executes a skill: spends MP, applies heal/damage/status, and returns true if turn is consumed.
/// @param {Instance} user   The battle instance casting the skill.
/// @param {Struct}   skill  The skill data struct (must contain `effect`, `cost`, etc.).
/// @param {Instance} target The battle instance being targeted (or same as user if self-target).
/// @returns {Bool} True if the action was consumed (even on a “miss”), false if it failed outright.
function scr_CastSkill(user, skill, target) {
    // 1) Validate
    if (!instance_exists(user) || !variable_instance_exists(user, "data") || !is_struct(user.data)) return false;
    if (!is_struct(skill) || !variable_struct_exists(skill, "effect")) return false;
    var needsTarget = variable_struct_exists(skill, "requires_target") ? skill.requires_target : true;
    var finalTarget = needsTarget ? target : user;
    if (!instance_exists(finalTarget)) return false;

    var ud = user.data;
    var td = (variable_instance_exists(finalTarget, "data") && is_struct(finalTarget.data))
           ? finalTarget.data : noone;

    // 2) Status check
    var status = script_exists(scr_GetStatus) ? scr_GetStatus(user) : undefined;
    if (is_struct(status)) {
        if (status.effect == "shame") {
            show_debug_message(" -> CastSkill: 'shame' prevents action."); 
            return true;
        }
        if (status.effect == "bind" && irandom(99) < 50) {
            show_debug_message(" -> CastSkill: bound, action skipped."); 
            return true;
        }
    }

    // 3) MP cost
    var cost = variable_struct_exists(skill, "cost") ? skill.cost : 0;
    var currentMP = variable_struct_exists(ud, "mp") ? ud.mp : 0;
    show_debug_message(" -> CastSkill: Checking MP for '" + string(skill.name) + "'. Cost=" 
                     + string(cost) + ", Have=" + string(currentMP));
    if (currentMP < cost) {
        show_debug_message(" -> CastSkill: Not enough MP!"); 
        return false;
    }
    ud.mp -= cost;
    show_debug_message(" -> CastSkill: MP after deduction: " + string(ud.mp));

    // 4) Execute effect
    var applied    = false;
    var showPopup  = true;
    var popupText  = "";
    var popupColor = c_white;
    var missedByBlind = false;

    if (needsTarget && target != user && is_struct(status) 
     && status.effect == "blind" && irandom(99) < 50) {
        missedByBlind = true;
        popupText     = "Miss!";
        applied       = true;
    }

    if (!missedByBlind) {
        switch (skill.effect) {
            case "heal_hp":
                if (is_struct(td)
                 && variable_struct_exists(td, "hp")
                 && variable_struct_exists(td, "maxhp")) {

                    var baseHeal  = variable_struct_exists(skill, "heal_amount") ? skill.heal_amount : 0;
                    var powerStat = variable_struct_exists(skill, "power_stat")   ? skill.power_stat   : "matk";
                    var userPower = variable_struct_exists(ud, powerStat)
                                  ? variable_struct_get(ud, powerStat)
                                  : 0;

                    var totalHeal = floor(baseHeal + userPower * 0.5);
                    var beforeHP  = td.hp;
                    td.hp         = min(td.maxhp, td.hp + totalHeal);

                    var actual = td.hp - beforeHP;
                    if (actual > 0) {
                        popupText  = "+" + string(actual);
                        popupColor = c_lime;
                    } else {
                        showPopup = false;
                    }
                    applied = true;
                }
                break;

            case "damage_enemy":
                if (is_struct(td) && variable_struct_exists(td, "hp")) {

                    var baseDmg   = variable_struct_exists(skill, "damage")     ? skill.damage : 0;
                    var powerStat = variable_struct_exists(skill, "power_stat") ? skill.power_stat : "atk";
                    var atkPower  = variable_struct_exists(ud, powerStat)
                                  ? variable_struct_get(ud, powerStat)
                                  : 0;
                    var defStat   = (powerStat == "matk") ? "mdef" : "def";
                    var tgtDef    = variable_struct_exists(td, defStat)
                                  ? variable_struct_get(td, defStat)
                                  : 0;

                    var dmg = max(1, baseDmg + atkPower - tgtDef);
                    if (variable_struct_exists(td, "is_defending") && td.is_defending) {
                        dmg = max(1, floor(dmg / 2));
                    }
                    td.hp -= dmg;
                    popupText  = string(dmg);
                    popupColor = c_white;
                    applied    = true;
                }
                break;

            case "blind":
            case "bind":
            case "shame":
                var dur = variable_struct_exists(skill, "duration") ? skill.duration : 3;
                if (script_exists(scr_ApplyStatus)) {
                    scr_ApplyStatus(finalTarget, skill.effect, dur);
                    var eff = string_upper(string_char_at(skill.effect, 1))
                            + string_copy(skill.effect, 2, string_length(skill.effect)-1);
                    popupText  = eff + "!";
                    popupColor = c_fuchsia;
                    applied    = true;
                }
                break;

            default:
                show_debug_message("⚠️ CastSkill: Unknown effect '" + string(skill.effect) + "'");
                applied   = true;
                showPopup = false;
                break;
        }
    }

    // 5) Popup
    if (showPopup && popupText != "" && object_exists(obj_popup_damage) && instance_exists(finalTarget)) {
        var pop = instance_create_layer(finalTarget.x, finalTarget.y-64, "Instances", obj_popup_damage);
        if (pop != noone) {
            pop.damage_amount = popupText;
            pop.text_color    = popupColor;
        }
    }

    show_debug_message(" -> CastSkill: applied=" + string(applied));
    return applied;
}
