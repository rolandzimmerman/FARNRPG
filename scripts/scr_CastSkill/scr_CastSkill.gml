/// @function scr_CastSkill(user, skill, target)
/// @description Executes a skill: checks/deducts cost, applies heal/damage/status/steal, checks death. Returns true if action used/turn consumed.
function scr_CastSkill(user, skill, target) {
    // --- <<< LOGGING: Entry Point >>> ---
    var _user_name   = instance_exists(user)
                     ? (object_get_name(user.object_index) + "["+string(user)+"], Name:" +
                        (variable_struct_exists(user.data, "name") ? user.data.name : "??"))
                     : "INVALID";
    var _skill_name  = is_struct(skill) && variable_struct_exists(skill, "name")
                     ? skill.name
                     : "INVALID";
    var _target_name = instance_exists(target)
                     ? (object_get_name(target.object_index) + "["+string(target)+"], Name:" +
                        (variable_struct_exists(target.data, "name") ? target.data.name : "??"))
                     : (target == user ? "Self" : "INVALID/NONE");
    show_debug_message("--- scr_CastSkill START --- User: " + _user_name
                     + " | Skill: " + _skill_name
                     + " | Target: " + _target_name);
    // --- <<< END LOGGING >>> ---

    // Alias for ease
    var _target = target;

    // 1) Validate Inputs
    if (!instance_exists(user)
     || !variable_instance_exists(user, "data")
     || !is_struct(user.data)) {
        show_debug_message("CastSkill Fail: Invalid User");
        return false;
    }
    if (!is_struct(skill)
     || !variable_struct_exists(skill, "effect")) {
        show_debug_message("CastSkill Fail: Invalid Skill Struct");
        return false;
    }
    var needsTarget = variable_struct_exists(skill, "target_type")
                    && skill.target_type != "self"
                    && skill.target_type != "all_allies"
                    && skill.target_type != "all_enemies";
    var finalTarget = needsTarget ? _target : user;

    show_debug_message("  -> Needs Specific Target: " + string(needsTarget)
                     + " | Final Target: " + string(finalTarget));

    var can_target_dead = (skill.effect == "revive");
    if (needsTarget) {
        if (!instance_exists(finalTarget)) {
            show_debug_message("CastSkill Fail: Target does not exist.");
            return false;
        }
        var td_check = variable_instance_get(finalTarget, "data");
        if (!is_struct(td_check) || !variable_struct_exists(td_check, "hp")) {
            show_debug_message("CastSkill Fail: Target missing data.hp.");
            return false;
        }
        if (td_check.hp <= 0 && !can_target_dead) {
            show_debug_message("CastSkill Fail: Target is dead; cannot target.");
            return false;
        }
    }

    var ud = user.data; // User data shortcut

    // 2) Cost / Usability Check
    var cost         = variable_struct_exists(skill, "cost") ? skill.cost : 0;
    var is_overdrive = variable_struct_exists(skill, "overdrive") && skill.overdrive;
    var can_cast     = false;

    if (is_overdrive) {
        can_cast = variable_struct_exists(ud, "overdrive")
                && variable_struct_exists(ud, "overdrive_max")
                && ud.overdrive >= ud.overdrive_max;
    } else {
        can_cast = variable_struct_exists(ud, "mp") && ud.mp >= cost;
    }

    if (!can_cast) {
        show_debug_message("  -> Usability Check FAILED for " + _skill_name);
        show_debug_message("--- scr_CastSkill END (Usability) ---");
        return false;
    } else {
        show_debug_message("  -> Usability Check PASSED.");
    }

    // Deduct cost
    if (is_overdrive) {
        ud.overdrive = 0;
        show_debug_message("  -> Overdrive consumed.");
    } else {
        ud.mp -= cost;
        show_debug_message("  -> MP deducted: " + string(cost) + ", remaining: " + string(ud.mp));
    }

    // 3) Perform Effect
    var applied    = false;
    var showPopup  = true;
    var popupText  = "";
    var popupColor = c_white;

    // Blind‐miss check
    var missed_by_blind = false;
    if (needsTarget
     && finalTarget != user
     && (skill.effect == "damage_enemy"
      || skill.effect == "blind"
      || skill.effect == "bind"
      || skill.effect == "shame")
     && script_exists(scr_GetStatus)) {
        var st = scr_GetStatus(user);
        if (is_struct(st) && st.effect == "blind") {
            var missChance = 50;
            show_debug_message("  -> Blind check: " + string(missChance) + "%");
            if (irandom(99) < missChance) {
                popupText      = "Miss!";
                applied        = true;
                missed_by_blind= true;
                show_debug_message("  -> Blind: Missed");
            }
        }
    }

    if (!missed_by_blind) {
        show_debug_message("  -> Applying effect: " + skill.effect);
        switch (skill.effect) {
            case "heal_hp": {
                var t = finalTarget;
                if (instance_exists(t) && variable_instance_exists(t, "data")) {
                    var td      = t.data;
                    var base    = variable_struct_exists(skill, "heal_amount") ? skill.heal_amount : 0;
                    var pkey    = variable_struct_exists(skill, "power_stat")    ? skill.power_stat  : "matk";
                    var userStat= variable_struct_exists(ud, pkey)               ? variable_struct_get(ud, pkey) : 0;
                    var healAmt = floor(base + userStat * 0.5);
                    var before  = td.hp;
                    td.hp       = min(td.maxhp, td.hp + healAmt);
                    var actual  = td.hp - before;
                    popupText   = actual > 0 ? "+"+string(actual) : "No Effect";
                    popupColor  = actual > 0 ? c_lime : c_gray;
                    applied     = true;
                }
                break;
            }

            case "damage_enemy": {
                var t    = finalTarget;
                if (instance_exists(t) && variable_instance_exists(t, "data")) {
                    var td        = t.data;
                    var base      = variable_struct_exists(skill,"damage")     ? skill.damage   : 0;
                    var pkey      = variable_struct_exists(skill,"power_stat") ? skill.power_stat : "matk";
                    var userStat  = variable_struct_exists(ud,pkey)            ? variable_struct_get(ud,pkey) : 0;
                    var defKey    = (pkey=="matk") ? "mdef" : "def";
                    var defStat   = variable_struct_exists(td,defKey)          ? variable_struct_get(td,defKey) : 0;
                    var calc      = max(1, base + userStat - defStat);
                    if (variable_struct_exists(td,"is_defending") && td.is_defending) {
                        calc = floor(calc/2);
                    }
                    var resist    = 1.0;
                    if (script_exists(GetResistanceMultiplier)
                     && variable_struct_exists(td,"resistances")) {
                        var elem = variable_struct_exists(skill,"element") ? skill.element : "physical";
                        resist = GetResistanceMultiplier(td.resistances, elem);
                    }
                    var finalDmg  = floor(calc * resist);
                    if (calc>=1 && resist>0 && finalDmg==0) finalDmg = 1;
                    var beforeHP  = td.hp;
                    td.hp         = max(0, td.hp - finalDmg);
                    popupText     = string(finalDmg);
                    popupColor    = c_white;
                    applied       = true;
                    if (script_exists(scr_ProcessDeathIfNecessary)) {
                        scr_ProcessDeathIfNecessary(t);
                    }
                    if (variable_struct_exists(td,"is_defending")) td.is_defending = false;
                }
                break;
            }

            case "blind": case "bind": case "shame":
            case "poison": case "regen": case "haste": case "slow": {
                var t   = finalTarget;
                var dur = variable_struct_exists(skill,"duration") ? skill.duration : 3;
                if (script_exists(scr_ApplyStatus)) {
                    applied = scr_ApplyStatus(t, skill.effect, dur);
                }
                break;
            }

            case "steal_item": {
                if (!instance_exists(_target)) {
                    show_debug_message("Steal failed: no target");
                    break;
                }
                if (!variable_instance_exists(_target,"has_been_stolen")) {
                    var steals = variable_struct_exists(_target.data,"steal_table")
                               ? _target.data.steal_table : [];
                    var got = false;
                    for (var i=0; i<array_length(steals); i++) {
                        var e = steals[i];
                        if (irandom(999)/1000 < e.chance) {
                            scr_AddInventoryItem(e.item_key, 1);
                            popupText  = "Stole "+e.item_key+"!";
                            popupColor = c_yellow;
                            got = true;
                            break;
                        }
                    }
                    if (!got) {
                        popupText  = "Nothing!";
                        popupColor = c_gray;
                    }
                    _target.has_been_stolen = true;
                    applied = true;
                } else {
                    popupText  = "Already stolen!";
                    popupColor = c_gray;
                }
                break;
            }

            default:
                show_debug_message("Unknown effect: "+string(skill.effect));
                applied = true;
                showPopup = false;
                break;
        }
    }

    // 4) Popup
    if (applied && showPopup && popupText != "" && object_exists(obj_popup_damage)) {
        var popTgt = instance_exists(finalTarget) ? finalTarget : user;
        var pop    = instance_create_layer(popTgt.x, popTgt.y - 64,
                                           layer_get_id("Instances"),
                                           obj_popup_damage);
        if (instance_exists(pop)) {
            pop.damage_amount = popupText;
            pop.text_color    = popupColor;
        }
    }

    show_debug_message("--- scr_CastSkill END --- Applied: " + string(applied));
    return applied;
}
