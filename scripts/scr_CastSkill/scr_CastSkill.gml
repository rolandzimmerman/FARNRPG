/// @function scr_CastSkill(user, skill, target)
/// @description Executes a skill: checks/deducts cost, applies effects (incl. new statuses), checks death.
function scr_CastSkill(user, skill, target) {
    // Logging entry...
    var userName  = instance_exists(user)
                  ? object_get_name(user.object_index) + "[" + string(user) + "]"
                  : "INVALID";
    var skillName = is_struct(skill) && variable_struct_exists(skill, "name")
                  ? skill.name
                  : "INVALID";
    show_debug_message("--- scr_CastSkill START --- " + userName + " uses " + skillName);

    // 1) Basic validation...
    if (!instance_exists(user) || !variable_instance_exists(user, "data")) return false;
    if (!is_struct(skill) || !variable_struct_exists(skill, "effect")) return false;

    // 2) Silence check
    var us = script_exists(scr_GetStatus) ? scr_GetStatus(user) : undefined;
    if (is_struct(us)
     && us.effect == "silence"
     && skill.effect != "heal_hp") {
        show_debug_message("  -> Silenced! Cannot cast " + skillName);
        return false;
    }

    // 3) Determine finalTarget
    var ttype = skill.target_type ?? "enemy";
    var needsTarget = (ttype != "self" && ttype != "all_allies" && ttype != "all_enemies");
    var finalTarget = needsTarget ? target : user;

    // 4) Shame redirect (50%)
    if (is_struct(us) && us.effect == "shame" && needsTarget) {
        if (irandom(99) < 50) {
            finalTarget = user;
            show_debug_message("  -> Shame triggered: targeting self!");
        }
    }

    // 5) Validate and cost-check (MP / Overdrive)
    var ud   = user.data;
    var cost = skill.cost ?? 0;
    var isOD = variable_struct_exists(skill, "overdrive") && skill.overdrive;
    if (isOD) {
        // only if od fields exist and full
        if (!(variable_struct_exists(ud, "overdrive")
           && variable_struct_exists(ud, "overdrive_max")
           && ud.overdrive >= ud.overdrive_max)) {
            show_debug_message("  -> Not enough Overdrive");
            return false;
        }
        ud.overdrive = 0;
    } else {
        if (!(variable_struct_exists(ud, "mp") && ud.mp >= cost)) {
            show_debug_message("  -> Not enough MP");
            return false;
        }
        ud.mp -= cost;
    }

    // 6) Blind miss check (only on damaging/status skills)
    var dmgSkills = ["damage_enemy", "blind", "bind", "shame"];
    if (needsTarget
     && array_contains(dmgSkills, skill.effect)
     && is_struct(us) && us.effect == "blind") {
        show_debug_message("  -> Blind: rolling 50% miss...");
        if (irandom(99) < 50) {
            show_debug_message("  -> Missed!");
            return true; // counts as used turn
        }
    }

    // 7) Apply effect
    var applied = false;
    switch (skill.effect) {
        case "heal_hp": {
            if (instance_exists(finalTarget)
             && variable_instance_exists(finalTarget, "data")) {
                var td  = finalTarget.data;
                var base= skill.heal_amount ?? 0;
                var ps  = skill.power_stat ?? "matk";
                var val = variable_struct_exists(ud, ps) 
                        ? variable_struct_get(ud, ps) 
                        : 0;
                var amt = floor(base + val * 0.5);
                var old = td.hp;
                td.hp    = min(td.maxhp, td.hp + amt);
                scr_AddBattleLog(skillName + " heals " 
                               + string(td.hp - old) 
                               + " HP");
                applied = true;
            }
        } break;

        case "damage_enemy": {
            if (instance_exists(finalTarget)
             && variable_instance_exists(finalTarget, "data")) {
                var td       = finalTarget.data;
                var base     = skill.damage ?? 0;
                var ps       = skill.power_stat ?? "matk";
                var atkVal   = variable_struct_exists(ud, ps) 
                             ? variable_struct_get(ud, ps) 
                             : 0;
                var defKey   = (ps == "matk") ? "mdef" : "def";
                var defVal   = variable_struct_exists(td, defKey) 
                             ? variable_struct_get(td, defKey) 
                             : 0;
                var calc     = max(1, base + atkVal - defVal);

                // Disgust halves damage
                if (is_struct(us) && us.effect == "disgust") {
                    calc = floor(calc * 0.5);
                    show_debug_message("  -> Disgust: damage halved");
                }

                // Resistances
                var mult = 1.0;
                if (script_exists(GetResistanceMultiplier)
                 && variable_struct_exists(td, "resistances")) {
                    mult = GetResistanceMultiplier(
                              td.resistances,
                              skill.element ?? "physical"
                           );
                }
                var finalD = floor(calc * mult);
                if (calc >= 1 && mult > 0 && finalD < 1) finalD = 1;

                var old = td.hp;
                td.hp    = max(0, td.hp - finalD);

                scr_AddBattleLog(skillName + " deals "
                               + string(old - td.hp)
                               + " damage");

                if (script_exists(scr_ProcessDeathIfNecessary))
                    scr_ProcessDeathIfNecessary(finalTarget);

                applied = true;
            }
        } break;

        case "blind": case "bind": case "shame":
        case "webbed": case "silence": case "disgust": {
            if (instance_exists(finalTarget)) {
                applied = scr_ApplyStatus(
                              finalTarget,
                              skill.effect,
                              skill.duration ?? 3
                          );
                if (applied) {
                    scr_AddBattleLog(
                      finalTarget.data.name
                    + " is afflicted with "
                    + skill.effect
                    );
                }
            }
        } break;
    }

    return applied;
}
