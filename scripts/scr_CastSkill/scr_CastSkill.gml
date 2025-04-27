/// @function scr_CastSkill(user, skill, target)
/// @description Executes skill, spends MP, applies effects using status scripts, returns true if turn used.
/// @param {Instance} user The battle instance casting the skill.
/// @param {Struct}   skill The skill data struct.
/// @param {Instance} target The battle instance target (or user if self-target).

function scr_CastSkill(user, skill, target) {
    // 1) Validate Inputs
    if (!instance_exists(user) || !variable_instance_exists(user, "data") || !is_struct(user.data)) { return false; }
    if (!is_struct(skill) || !variable_struct_exists(skill, "effect")) { return false; }
    var needs_target = variable_struct_exists(skill, "requires_target") ? skill.requires_target : true;
    var final_target_inst = needs_target ? target : user;
    if (!instance_exists(final_target_inst)) { return false; }
    var target_has_data = (variable_instance_exists(final_target_inst, "data") && is_struct(final_target_inst.data));
    var ud = user.data; var td = target_has_data ? final_target_inst.data : noone;

    // 2) Check User Status (using scr_GetStatus)
    var user_status_info = script_exists(scr_GetStatus) ? scr_GetStatus(user) : undefined; if (is_struct(user_status_info)) { if (user_status_info.effect == "shame") { /* Popup */ return true; } if (user_status_info.effect == "bind" && irandom(99) < 50) { /* Popup */ return true; } }

    // 3) Check & Deduct MP Cost
    var cost = variable_struct_exists(skill, "cost") ? skill.cost : 0; var current_mp = variable_struct_exists(ud, "mp") ? ud.mp : 0;
    show_debug_message(" -> CastSkill: Check MP for '" + string(skill.name) + "'. Cost=" + string(cost) + ", User MP Before=" + string(current_mp));
    if (current_mp < cost) { show_debug_message(" -> CastSkill: Not enough MP! Action fails."); return false; }
    if (variable_struct_exists(ud, "mp")) { ud.mp -= cost; show_debug_message(" -> CastSkill: MP Deducted. New MP=" + string(ud.mp)); }

    // 4) Perform effect
    var applied = false; var show_popup = true; var popup_text = ""; var popup_color = c_white; var missed_due_to_blind = false;
    if (needs_target && target != user && is_struct(user_status_info) && user_status_info.effect == "blind" && irandom(99) < 50) { missed_due_to_blind = true; popup_text = "Miss!"; applied = true; show_popup = true; }

    if (!missed_due_to_blind) {
        switch (skill.effect) {
            case "heal_hp": if (is_struct(td)) { /* Healing Logic */ applied = true; /* ... */ } else { applied = false; show_popup = false; } break;
            case "damage_enemy": if (is_struct(td)) { /* Damage Logic */ applied = true; /* ... */ } else { applied = true; show_popup = false; } break;
            case "blind": case "bind": case "shame": // Add other status keys
                show_debug_message(" -> CastSkill: Applying status '" + skill.effect + "' to target " + string(final_target_inst));
                var duration = variable_struct_exists(skill, "duration") ? skill.duration : 3;
                if (script_exists(scr_ApplyStatus)) {
                     scr_ApplyStatus(final_target_inst, skill.effect, duration);
                     var _eff_str = skill.effect; var _f = string_upper(string_char_at(_eff_str, 1)); var _r = string_copy(_eff_str, 2, string_length(_eff_str) - 1); popup_text = _f + _r + "!";
                     popup_color = c_fuchsia;
                     applied = true; // <<< ENSURE THIS IS TRUE
                } else { applied = false; show_popup = false; }
                break;
            default: show_debug_message("⚠️ Unknown skill effect: " + string(skill.effect)); applied = true; show_popup = false; break;
        }
    } else { applied = true; } // Miss still uses turn

    // 5) Create Popup Text
    if (show_popup && popup_text != "" && object_exists(obj_popup_damage) && instance_exists(final_target_inst)) { /* Create popup */ }

    show_debug_message(" -> CastSkill: Returning applied = " + string(applied));
    return applied;
}