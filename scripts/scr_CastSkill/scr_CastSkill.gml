/// @function scr_CastSkill(user, skill, target)
/// @description Executes a skill: checks/deducts cost, applies effects (incl. new statuses), checks death.
function scr_CastSkill(user, skill, target) {
    // Logging entry...
    var userName  = instance_exists(user) 
                  ? object_get_name(user.object_index) + "["+string(user)+"]" 
                  : "INVALID";
    var skillName = is_struct(skill) && variable_struct_exists(skill,"name")
                  ? skill.name : "INVALID";
    show_debug_message("--- scr_CastSkill START --- " + userName + " uses " + skillName);

    // 1) Basic validation...
    if (!instance_exists(user) || !variable_instance_exists(user,"data")) return false;
    if (!is_struct(skill) || !variable_struct_exists(skill,"effect")) return false;

    // 2) Silence check
    var us = scr_GetStatus(user);
    if (is_struct(us) && us.effect == "silence" && skill.effect != "heal_hp") {
        show_debug_message("  → Silenced! Cannot cast " + skillName);
        return false;
    }

    // 3) Determine finalTarget
    var needsTarget = (skill.target_type ?? "enemy") != "self"
                   && (skill.target_type ?? "enemy") != "all_allies"
                   && (skill.target_type ?? "enemy") != "all_enemies";
    var finalTarget = needsTarget ? target : user;

    // 4) Shame check (50% redirect to self)
    if (is_struct(us) && us.effect == "shame" && needsTarget) {
        if (irandom(99) < 50) {
            finalTarget = user;
            show_debug_message("  → Shame triggered: targeting self!");
        }
    }

    // 5) Validate and cost‐check (MP / Overdrive)
    var ud = user.data;
    var cost = skill.cost ?? 0;
    var od   = variable_struct_exists(skill,"overdrive") && skill.overdrive;
    if (od) {
        if (!(variable_struct_exists(ud,"overdrive") && ud.overdrive >= ud.overdrive_max)) {
            show_debug_message("  → Not enough Overdrive");
            return false;
        }
        ud.overdrive = 0;
    } else {
        if (!(variable_struct_exists(ud,"mp") && ud.mp >= cost)) {
            show_debug_message("  → Not enough MP");
            return false;
        }
        ud.mp -= cost;
    }

    // 6) Blind miss check
    if (needsTarget && (skill.effect == "damage_enemy" 
                     || skill.effect == "blind" 
                     || skill.effect == "bind"
                     || skill.effect == "shame")
     && instance_exists(user)) {
        if (is_struct(us) && us.effect == "blind") {
            show_debug_message("  → Blind: rolling 50% miss...");
            if (irandom(99) < 50) {
                // play a “miss” popup?
                show_debug_message("  → Missed!");
                return true; // counts as turn used
            }
        }
    }

    // 7) Apply effect
    var applied = false;
    switch (skill.effect) {
        case "heal_hp": {
            if (instance_exists(finalTarget) && variable_instance_exists(finalTarget,"data")) {
                var td = finalTarget.data;
                var base = skill.heal_amount ?? 0;
                var ps   = skill.power_stat ?? "matk";
                var val  = (variable_struct_exists(ud,ps) ? variable_struct_get(ud,ps) : 0);
                var amt  = floor(base + val * 0.5);
                var old  = td.hp;
                td.hp    = min(td.maxhp, td.hp + amt);
                // popup...
                applied = true;
            }
            break;
        }
        case "damage_enemy": {
            if (instance_exists(finalTarget) && variable_instance_exists(finalTarget,"data")) {
                var td      = finalTarget.data;
                var base    = skill.damage ?? 0;
                var ps      = skill.power_stat ?? "matk";
                var atkVal  = variable_struct_exists(ud,ps) ? variable_struct_get(ud,ps) : 0;
                var defKey  = (ps=="matk")?"mdef":"def";
                var defVal  = variable_struct_exists(td,defKey)?variable_struct_get(td,defKey):0;
                var calc    = max(1, base + atkVal - defVal);
                // disgust reduces your damage by 50%
                if (is_struct(us) && us.effect == "disgust") {
                    calc = floor(calc * 0.5);
                    show_debug_message("  → Disgust: damage halved");
                }
                // resistances...
                var finalD = calc; 
                var oldHP  = td.hp;
                td.hp      = max(0, td.hp - finalD);
                // death check...
                applied = true;
            }
            break;
        }
        case "blind": case "bind": case "shame":
        case "webbed": case "silence": case "disgust": {
            applied = scr_ApplyStatus(finalTarget, skill.effect, skill.duration ?? 3);
            break;
        }
    }

    return applied;
}
