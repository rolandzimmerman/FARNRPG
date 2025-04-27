/// @function scr_CastSkill(user, skill, target)
/// @description Executes a skill: spends MP, applies heal/damage/status, fills/consumes Overdrive, returns true if turn used.
/// @param {Instance} user   The battle instance casting the skill.
/// @param {Struct}   skill  The skill data struct (must contain `effect`, `cost`, etc.).
/// @param {Instance} target The battle instance being targeted (or same as user if self-target).
/// @returns {Bool} True if the action consumed the turn, false if it failed outright.
function scr_CastSkill(user, skill, target) {
    // 1) Validate Inputs
    if (!instance_exists(user) || !variable_instance_exists(user, "data") || !is_struct(user.data)) return false;
    if (!is_struct(skill) || !variable_struct_exists(skill, "effect")) return false;
    var needsTarget = variable_struct_exists(skill, "requires_target") ? skill.requires_target : true;
    var finalTarget = needsTarget ? target : user;
    if (!instance_exists(finalTarget)) return false;

    var ud = user.data;
    var td = (variable_instance_exists(finalTarget, "data") && is_struct(finalTarget.data))
           ? finalTarget.data : noone;

    // 2) Status interrupts
    var status = script_exists(scr_GetStatus) ? scr_GetStatus(user) : undefined;
    if (is_struct(status)) {
        if (status.effect == "shame") { show_debug_message(" -> CastSkill: 'shame' prevents action."); return true; }
        if (status.effect == "bind"  && irandom(99) < 50) { show_debug_message(" -> CastSkill: bound, action skipped."); return true; }
    }

    // 3) Overdrive-skill check
    if (variable_struct_exists(skill, "overdrive") && skill.overdrive) {
        if (ud.overdrive < ud.overdrive_max) {
            show_debug_message(" -> Overdrive not ready.");
            return false;
        }
    }

    // 4) MP cost
    var cost = variable_struct_exists(skill, "cost") ? skill.cost : 0;
    if (ud.mp < cost) {
        show_debug_message(" -> CastSkill: Not enough MP!");
        return false;
    }
    ud.mp -= cost;
    show_debug_message(" -> CastSkill: MP after deduction: " + string(ud.mp));

    // 5) Perform effect
    var applied = false;
    var showPopup = true;
    var popupText = "";
    var popupColor = c_white;

    // Blind miss check
    if (needsTarget && is_struct(status) && status.effect == "blind" && irandom(99) < 50) {
        popupText = "Miss!";
        applied   = true;
    }

    if (!applied) {
        switch (skill.effect) {
            case "heal_hp":
                if (is_struct(td) && variable_struct_exists(td, "hp") && variable_struct_exists(td, "maxhp")) {
                    var baseHeal  = variable_struct_exists(skill, "heal_amount") ? skill.heal_amount : 0;
                    var pstatKey  = variable_struct_exists(skill, "power_stat")   ? skill.power_stat   : "matk";
                    var userPower = variable_struct_exists(ud, pstatKey)
                                  ? variable_struct_get(ud, pstatKey)
                                  : 0;
                    var healAmt   = floor(baseHeal + userPower * 0.5);
                    var beforeHP  = td.hp;
                    td.hp         = min(td.maxhp, td.hp + healAmt);
                    var actual    = td.hp - beforeHP;
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
                    var pstatKey  = variable_struct_exists(skill, "power_stat") ? skill.power_stat : "atk";
                    var atkPower  = variable_struct_exists(ud, pstatKey)
                                  ? variable_struct_get(ud, pstatKey)
                                  : 0;
                    var defKey    = (pstatKey == "matk") ? "mdef" : "def";
                    var tgtDef    = variable_struct_exists(td, defKey)
                                  ? variable_struct_get(td, defKey)
                                  : 0;
                    var dmg       = max(1, baseDmg + atkPower - tgtDef);
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
                    var effName = string_upper(string_char_at(skill.effect, 1))
                                + string_copy(skill.effect, 2, string_length(skill.effect)-1);
                    popupText  = effName + "!";
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

    // 6) Overdrive fill for normal skills
    if (applied && !variable_struct_exists(skill, "overdrive")) {
        ud.overdrive = min(ud.overdrive + 10, ud.overdrive_max);
        show_debug_message(" -> Overdrive now " + string(ud.overdrive));
    }

    // 7) Popup
    if (showPopup && popupText != "" && object_exists(obj_popup_damage) && instance_exists(finalTarget)) {
        var pop = instance_create_layer(finalTarget.x, finalTarget.y - 64, "Instances", obj_popup_damage);
        if (pop != noone) {
            pop.damage_amount = popupText;
            pop.text_color    = popupColor;
        }
    }

    // 8) Consume Overdrive if used
    if (variable_struct_exists(skill, "overdrive") && skill.overdrive && applied) {
        ud.overdrive = 0;
        show_debug_message(" -> Overdrive consumed!");
    }

    return applied;
}
