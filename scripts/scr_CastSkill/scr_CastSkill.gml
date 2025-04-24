/// scr_CastSkill.gml
/// @function scr_CastSkill(user, skill, target)
/// @description Executes a skill: spends MP, applies damage/heal/status, and returns true if the turn should advance.
/// @param {Instance} user   The battle‐instance casting the skill (e.g., obj_battle_player instance).
/// @param {Struct}   skill  A skill struct with fields like name, cost, effect, damage, heal_amount, duration, requires_target.
/// @param {Instance} target The battle‐instance target of the skill (or noone).

function scr_CastSkill(user, skill, target) {
    // 1) Validate
    if (!instance_exists(user) || !variable_instance_exists(user, "data") || !is_struct(user.data)) return false;
    if (!is_struct(skill) || !variable_struct_exists(skill, "effect"))  return false;
    var needs = variable_struct_exists(skill, "requires_target") ? skill.requires_target : true;
    if (needs && !instance_exists(target)) return false;

    var ud = user.data;

    // 2) Shame prevents any skill
    if (ud.status == "shame") {
        if (object_exists(obj_popup_damage)) {
            var pop = instance_create_layer(user.x, user.y - 64, "Instances", obj_popup_damage);
            if (pop != noone) { pop.damage_amount = "Shame!"; pop.text_color = c_red; }
        }
        return true;
    }

    // 3) MP cost
    if (ud.mp < skill.cost) {
        if (script_exists(scr_dialogue)) create_dialog([{ name:"System", msg:"Not enough MP!" }]);
        return false;
    }
    ud.mp -= skill.cost;

    // 4) Perform effect
    var applied = false;
    switch (skill.effect) {

        case "heal_hp":
            // … (your existing heal logic) …
            // e.g. compute amount, clamp to maxhp, show popup…
            applied = true;
            break;

        case "damage_enemy":
            if (instance_exists(target) && variable_instance_exists(target, "data") && is_struct(target.data)) {
                var td = target.data;
                // 50% miss if caster is blind
                if (ud.status == "blind" && irandom(99) < 50) {
                    if (object_exists(obj_popup_damage)) {
                        var miss = instance_create_layer(target.x, target.y - 64, "Instances", obj_popup_damage);
                        if (miss != noone) miss.damage_amount = "Miss!";
                    }
                    applied = true;
                    break;
                }
                var base = variable_struct_exists(skill, "damage") ? skill.damage : 0;
                var matk = variable_struct_exists(ud, "matk")   ? ud.matk   : 0;
                var mdef = variable_struct_exists(td, "mdef")   ? td.mdef   : 0;
                var dmg  = max(1, base + matk - mdef);
                if (variable_struct_exists(td, "is_defending") && td.is_defending) dmg = floor(dmg/2);
                td.hp = max(0, td.hp - dmg);
                if (object_exists(obj_popup_damage)) {
                    var pop = instance_create_layer(target.x, target.y - 64, "Instances", obj_popup_damage);
                    if (pop != noone) pop.damage_amount = string(dmg);
                }
                applied = true;
            }
            break;

        case "blind":
            if (instance_exists(target) && is_struct(target.data)) {
                target.data.status       = "blind";
                target.data.status_turns = skill.duration;
                if (object_exists(obj_popup_damage)) {
                    var p = instance_create_layer(target.x, target.y - 64, "Instances", obj_popup_damage);
                    if (p!=noone) p.damage_amount="Blind!";
                }
                applied = true;
            }
            break;

        case "bind":
            if (instance_exists(target) && is_struct(target.data)) {
                target.data.status       = "bind";
                target.data.status_turns = skill.duration;
                if (object_exists(obj_popup_damage)) {
                    var p2 = instance_create_layer(target.x, target.y - 64, "Instances", obj_popup_damage);
                    if (p2!=noone) p2.damage_amount="Bind!";
                }
                applied = true;
            }
            break;

        case "shame":
            if (instance_exists(target) && is_struct(target.data)) {
                target.data.status       = "shame";
                target.data.status_turns = skill.duration;
                if (object_exists(obj_popup_damage)) {
                    var p3 = instance_create_layer(target.x, target.y - 64, "Instances", obj_popup_damage);
                    if (p3!=noone) p3.damage_amount="Shame!";
                }
                applied = true;
            }
            break;

        default:
            show_debug_message("⚠️ Unknown skill effect: " + string(skill.effect));
            applied = true;
            break;
    }

    return applied;
}
