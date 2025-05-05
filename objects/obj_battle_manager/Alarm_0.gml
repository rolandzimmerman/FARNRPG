/// obj_battle_manager :: Alarm[0]
show_debug_message("⏰ Alarm[0] Triggered — Battle State: " + string(global.battle_state));

switch (global.battle_state) {

case "victory":
{
    show_debug_message("🏆 Victory! Summing XP from initial_enemy_xp...");

    // 1) Sum total XP from the recorded list
    total_xp_from_battle = 0;
    if (variable_instance_exists(id, "initial_enemy_xp")
     && ds_exists(initial_enemy_xp, ds_type_list)) {
        for (var i = 0; i < ds_list_size(initial_enemy_xp); i++) {
            total_xp_from_battle += ds_list_find_value(initial_enemy_xp, i);
        }
    }
    show_debug_message(" -> Total XP to award: " + string(total_xp_from_battle));

    // 2) Award that XP to every surviving party member
    var leveled_up = [];
    if (ds_exists(global.battle_party, ds_type_list)) {
        for (var i = 0; i < ds_list_size(global.battle_party); i++) {
            var inst = global.battle_party[| i];
            if (!instance_exists(inst)) continue;
            if (!variable_instance_exists(inst, "data") || inst.data.hp <= 0) continue;

            var key = inst.character_key;
            if (script_exists(scr_AddXPToCharacter)) {
                var did_level = scr_AddXPToCharacter(key, total_xp_from_battle);
                if (did_level) array_push(leveled_up, inst.data.name);
            }
        }
    }

    // 3) Show dialogue
scr_AddBattleLog("Victory! Gained " + string(total_xp_from_battle) + " XP.");

// then freeze the log:
with (obj_battle_log) {
    holdAtEnd = true;
}

    global.battle_state = "return_to_field";
    alarm[0] = 60;
}
break;

    case "defeat":
    {
        show_debug_message("💀 Defeat! Showing game over dialog...");

        if (script_exists(create_dialog)) {
            create_dialog([{ name: "Defeat", msg: "You have been defeated..." }]);
        }

        global.battle_state = "return_to_field";
        alarm[0] = 90;
    }
    break;

    case "return_to_field":
    {
        show_debug_message("Returning to overworld...");

        // Save HP/MP back to global stats
        if (ds_exists(global.battle_party, ds_type_list) && ds_exists(global.party_current_stats, ds_type_map)) {
            for (var i = 0; i < ds_list_size(global.battle_party); i++) {
                var inst = global.battle_party[| i];
                if (!instance_exists(inst)) continue;

                var key = inst.character_key;
                if (!is_string(key)) continue;

                var stats = ds_map_find_value(global.party_current_stats, key);
                if (!is_struct(stats)) continue;

    stats.hp          = max(0, inst.data.hp);
    stats.mp          = max(0, inst.data.mp);
    stats.overdrive   = clamp(inst.data.overdrive, 0, inst.data.overdrive_max);  // ← NEW
    stats.level       = inst.data.level;
    stats.xp          = inst.data.xp;
    stats.xp_require  = inst.data.xp_require;

                ds_map_replace(global.party_current_stats, key, stats);
            }
        }

        // Cleanup Instances_FX
        with (obj_battle_player) instance_destroy();
        with (obj_battle_enemy) instance_destroy();
        with (obj_battle_menu) instance_destroy();
        with (obj_dialog) instance_destroy();
        with (obj_attack_visual) instance_destroy();
        with (obj_popup_damage) instance_destroy();

        // Cleanup DS lists/maps
        if (ds_exists(global.battle_party, ds_type_list)) ds_list_destroy(global.battle_party);
        if (ds_exists(global.battle_enemies, ds_type_list)) ds_list_destroy(global.battle_enemies);
        if (ds_exists(global.battle_status_effects, ds_type_map)) ds_map_destroy(global.battle_status_effects);
        if (ds_exists(combatants_all, ds_type_list)) ds_list_destroy(combatants_all);

        global.battle_party = -1;
        global.battle_enemies = -1;
        global.battle_status_effects = -1;
        combatants_all = -1;

        stored_action_data = undefined;
        selected_target_id = noone;
        currentActor = noone;
        global.active_party_member_index = 0;
        global.battle_target = 0;

        // Return to original room — let Game Manager handle player positioning
        if (variable_global_exists("original_room") && room_exists(global.original_room)) {
            room_goto(global.original_room);
        } else {
            show_debug_message("ERROR: No valid return room found.");
            game_end();
        }
    }
    break;

    default:
        show_debug_message("⚠️ Alarm[0] reached in unknown battle state.");
        break;
}
