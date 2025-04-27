/// @function scr_CastSkill(user, skill, target)
/// @description Executes skill, spends MP, applies effects using status scripts, returns true if turn used.
/// @param {Instance} user The battle instance casting the skill.
/// @param {Struct}   skill The skill data struct.
/// @param {Instance} target The battle instance target (or user if self-target).

function scr_CastSkill(user, skill, target) {
    // 1) Validate Inputs
    if (!instance_exists(user) || !variable_instance_exists(user, "data") || !is_struct(user.data)) { show_debug_message("ERROR [CastSkill]: Invalid user"); return false; }
    if (!is_struct(skill) || !variable_struct_exists(skill, "effect")) { show_debug_message("ERROR [CastSkill]: Invalid skill"); return false; }
    var needs_target = variable_struct_exists(skill, "requires_target") ? skill.requires_target : true;
    var final_target_inst = needs_target ? target : user;
    if (!instance_exists(final_target_inst)) { show_debug_message("ERROR [CastSkill]: Target instance invalid"); return false; }
    var target_has_data = (variable_instance_exists(final_target_inst, "data") && is_struct(final_target_inst.data));
    var ud = user.data;
    var td = target_has_data ? final_target_inst.data : noone;

    // 2) Check User Status (using scr_GetStatus)
    var user_status_info = script_exists(scr_GetStatus) ? scr_GetStatus(user) : undefined;
    if (is_struct(user_status_info)) {
         if (user_status_info.effect == "shame") { /* Popup */ return true; }
         if (user_status_info.effect == "bind" && irandom(99) < 50) { /* Popup */ return true; }
    }

    // 3) Check & Deduct MP Cost
    var cost = variable_struct_exists(skill, "cost") ? skill.cost : 0;
    var current_mp = variable_struct_exists(ud, "mp") ? ud.mp : 0;
    show_debug_message(" -> CastSkill: Check MP for '" + string(skill.name) + "'. Cost=" + string(cost) + ", User MP Before=" + string(current_mp));
    if (current_mp < cost) { show_debug_message(" -> CastSkill: Not enough MP! Action fails."); return false; }
    if (variable_struct_exists(ud, "mp")) { ud.mp -= cost; show_debug_message(" -> CastSkill: MP Deducted. New MP=" + string(ud.mp)); }

    // 4) Perform effect
    var applied = false; var show_popup = true; var popup_text = ""; var popup_color = c_white; var missed_due_to_blind = false;
    // Blind check on user
    if (needs_target && target != user && is_struct(user_status_info) && user_status_info.effect == "blind" && irandom(99) < 50) { show_debug_message(" -> CastSkill: Missed due to Blind!"); popup_text = "Miss!"; applied = true; show_popup = true; missed_due_to_blind = true; }

    if (!missed_due_to_blind) {
        switch (skill.effect) {
            case "heal_hp":
                if (is_struct(td)) { var heal_base = variable_struct_exists(skill, "heal_amount") ? skill.heal_amount : 0; var power_stat = variable_struct_exists(skill, "power_stat") ? skill.power_stat : "matk"; var user_power = variable_struct_exists(ud, power_stat) ? variable_struct_get(ud, power_stat) : 0; var heal_total = floor(heal_base + user_power * 0.5); heal_total = max(0, heal_total); if (variable_struct_exists(td, "hp") && variable_struct_exists(td, "maxhp")) { var old_hp = td.hp; td.hp = min(td.maxhp, td.hp + heal_total); var actual_healed = td.hp - old_hp; if (actual_healed > 0) { popup_text = string(actual_healed); popup_color = c_lime; applied = true; } else { applied = true; show_popup = false; } } else { applied = false; show_popup = false; } } else { applied = false; show_popup = false;}
                break;
            case "damage_enemy":
                 if (is_struct(td)) { var base = variable_struct_exists(skill, "damage") ? skill.damage : 0; var power_stat = variable_struct_exists(skill, "power_stat") ? skill.power_stat : "atk"; var user_power = variable_struct_exists(ud, power_stat) ? variable_struct_get(ud, power_stat) : 0; var target_defense_stat = (power_stat == "matk") ? "mdef" : "def"; var target_defense = variable_struct_exists(td, target_defense_stat) ? variable_struct_get(td, target_defense_stat) : 0; var dmg  = max(1, base + user_power - target_defense); if (variable_struct_exists(td, "is_defending") && td.is_defending) dmg = max(1, floor(dmg/2)); if (variable_struct_exists(td, "hp")) { td.hp = max(0, td.hp - dmg); popup_text = string(dmg); popup_color = c_white; applied = true; } else { applied = false; show_popup = false; } } else { applied = true; show_popup = false; }
                break;
            // --- CORRECTED STATUS APPLICATION ---
            case "blind": case "bind": case "shame": // Add other status keys
                show_debug_message(" -> CastSkill: Applying status '" + skill.effect + "' to target " + string(final_target_inst));
                var duration = variable_struct_exists(skill, "duration") ? skill.duration : 3;
                // Call script to apply status
                if (script_exists(scr_ApplyStatus)) {
                     scr_ApplyStatus(final_target_inst, skill.effect, duration);
                     // Create popup text using compatible functions
                     var _effect_string = skill.effect; var _first_char = string_upper(string_char_at(_effect_string, 1)); var _rest = string_copy(_effect_string, 2, string_length(_effect_string) - 1); popup_text = _first_char + _rest + "!";
                     popup_color = c_fuchsia;
                     applied = true; // <<<< ENSURE THIS IS TRUE
                     show_debug_message("    -> Called scr_ApplyStatus. Applied flag set to true.");
                } else {
                    show_debug_message("ERROR: scr_ApplyStatus script missing!");
                    applied = false; // Fail if script missing
                    show_popup = false;
                }
                break;
            // --- END CORRECTION ---
            default: show_debug_message("⚠️ Unknown skill effect: " + string(skill.effect)); applied = true; show_popup = false; break;
        }
    } else { applied = true; } // Miss still uses turn

    // --- 5) Create Popup Text ---
    if (show_popup && popup_text != "" && object_exists(obj_popup_damage) && instance_exists(final_target_inst)) { var pop = instance_create_layer(final_target_inst.x, final_target_inst.y - 64, "Instances", obj_popup_damage); if (pop != noone) { pop.damage_amount = popup_text; pop.text_color = popup_color; } }

    show_debug_message(" -> CastSkill: Returning applied = " + string(applied));
    return applied;
}