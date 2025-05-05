/// @function scr_CastSkill(user, skill, target)
/// @description Executes a skill: checks/deducts cost, applies effects, logs hits/misses.
function scr_CastSkill(user, skill, target) {
    // --- Determine Names ---
    var casterName = "Unknown";
    if (instance_exists(user) 
     && variable_instance_exists(user, "data") 
     && is_struct(user.data)) {
        casterName = user.data.name ?? "Unknown";
    }
    var skillName = is_struct(skill) 
                  && variable_struct_exists(skill, "name")
                  ? skill.name
                  : "Unknown Skill";
    var targetName = casterName;
    if (instance_exists(target) 
     && variable_instance_exists(target, "data") 
     && is_struct(target.data)) {
        targetName = target.data.name ?? "Unknown";
    }

    scr_AddBattleLog(casterName + " uses " + skillName + ".");

    // 1) Basic validation
    if (!instance_exists(user) 
     || !variable_instance_exists(user, "data")) {
        return false;
    }
    if (!is_struct(skill) 
     || !variable_struct_exists(skill, "effect")) {
        return false;
    }

    // 2) Silence check
    var statusUser = script_exists(scr_GetStatus) 
                   ? scr_GetStatus(user) 
                   : undefined;
    if (is_struct(statusUser)
     && statusUser.effect == "silence"
     && skill.effect != "heal_hp") {
        scr_AddBattleLog(casterName + " is silenced and cannot cast " + skillName + ".");
        return false;
    }

    // 3) Determine final target
    var ttype       = skill.target_type ?? "enemy";
    var needsTarget = (ttype != "self" && ttype != "all_allies" && ttype != "all_enemies");
    var finalTarget = needsTarget ? target : user;

    // 4) Shame redirect (50%)
    if (is_struct(statusUser)
     && statusUser.effect == "shame"
     && needsTarget
     && irandom(99) < 50) {
        finalTarget = user;
        scr_AddBattleLog("Shame redirects " + casterName + " to target themselves!");
    }

    // 5) Cost check
    var ud     = user.data;
    var cost   = skill.cost ?? 0;
    var isOD   = variable_struct_exists(skill, "overdrive") && skill.overdrive;
    if (isOD) {
        if (!(variable_struct_exists(ud, "overdrive")
           && variable_struct_exists(ud, "overdrive_max")
           && ud.overdrive >= ud.overdrive_max)) {
            scr_AddBattleLog(casterName + " does not have enough Overdrive.");
            return false;
        }
        ud.overdrive = 0;
    } else {
        if (!(variable_struct_exists(ud, "mp") && ud.mp >= cost)) {
            scr_AddBattleLog(casterName + " does not have enough MP.");
            return false;
        }
        ud.mp -= cost;
    }

    // 6) Blind miss check for damage/status skills
    var dmgSkills = ["damage_enemy", "blind", "bind", "shame"];
    if (needsTarget
     && array_contains(dmgSkills, skill.effect)
     && is_struct(statusUser)
     && statusUser.effect == "blind"
     && irandom(99) < 50) {
        scr_AddBattleLog(casterName + " missed " + targetName + " with " + skillName + " due to Blind.");
        return true;
    }

    // 7) Apply effect and log
    var applied = false;
    switch (skill.effect) {
        case "heal_hp": {
            if (instance_exists(finalTarget)
             && variable_instance_exists(finalTarget, "data")) {
                var td   = finalTarget.data;
                var base = skill.heal_amount ?? 0;
                var ps   = skill.power_stat ?? "matk";
                var val  = variable_struct_exists(ud, ps)
                         ? variable_struct_get(ud, ps)
                         : 0;
                var amt  = floor(base + val * 0.5);
                var old  = td.hp;
                td.hp    = min(td.maxhp, td.hp + amt);
                var healed = td.hp - old;

                scr_AddBattleLog(casterName
                    + " heals "
                    + string(healed)
                    + " HP on "
                    + ((finalTarget == user) ? casterName : targetName)
                    + ".");
                applied = true;
            }
        } break;

        case "damage_enemy": {
            if (instance_exists(finalTarget)
             && variable_instance_exists(finalTarget, "data")) {
                var td     = finalTarget.data;
                var base   = skill.damage ?? 0;
                var ps     = skill.power_stat ?? "matk";
                var atkVal = variable_struct_exists(ud, ps)
                           ? variable_struct_get(ud, ps)
                           : 0;
                var defKey = (ps == "matk") ? "mdef" : "def";
                var defVal = variable_struct_exists(td, defKey)
                           ? variable_struct_get(td, defKey)
                           : 0;
                var calc   = max(1, base + atkVal - defVal);

                if (is_struct(statusUser) && statusUser.effect == "disgust") {
                    calc = floor(calc * 0.5);
                }

                var mult   = 1.0;
                if (script_exists(GetResistanceMultiplier)
                 && variable_struct_exists(td, "resistances")) {
                    mult = GetResistanceMultiplier(td.resistances, skill.element ?? "physical");
                }
                var finalD = floor(calc * mult);
                if (calc >= 1 && mult > 0 && finalD < 1) finalD = 1;

                var oldHP = td.hp;
                td.hp    = max(0, td.hp - finalD);
                var dealt = oldHP - td.hp;

                scr_AddBattleLog(casterName
                    + " deals "
                    + string(dealt)
                    + " damage to "
                    + targetName
                    + " with "
                    + skillName
                    + ".");

                if (script_exists(scr_ProcessDeathIfNecessary)) {
                    scr_ProcessDeathIfNecessary(finalTarget);
                }
                applied = true;
            }
        } break;

        case "blind": case "bind": case "shame":
        case "webbed": case "silence": case "disgust": {
            if (instance_exists(finalTarget)) {
                applied = scr_ApplyStatus(finalTarget, skill.effect, skill.duration ?? 3);
                if (applied) {
                    scr_AddBattleLog(targetName
                        + " is afflicted with "
                        + skill.effect
                        + " by "
                        + casterName
                        + ".");
                } else {
                    scr_AddBattleLog(casterName
                        + " failed to apply "
                        + skill.effect
                        + " to "
                        + targetName
                        + ".");
                }
            }
        } break;
    }

    return applied;
}
