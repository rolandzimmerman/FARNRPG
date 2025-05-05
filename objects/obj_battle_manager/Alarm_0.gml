/// obj_battle_manager :: Alarm[0]
show_debug_message("⏰ Alarm[0] Triggered — Battle State: " + string(global.battle_state));

switch (global.battle_state) {

    case "victory":
    {
        // 1) Sum XP
        total_xp_from_battle = 0;
        if (variable_instance_exists(id, "initial_enemy_xp")
         && ds_exists(initial_enemy_xp, ds_type_list)) {
            for (var i = 0; i < ds_list_size(initial_enemy_xp); i++) {
                total_xp_from_battle += ds_list_find_value(initial_enemy_xp, i);
            }
        }
        show_debug_message(" -> Total XP to award: " + string(total_xp_from_battle));

        // Log the victory
        scr_AddBattleLog("Victory! Gained " + string(total_xp_from_battle) + " XP.");
        with (obj_battle_log) holdAtEnd = true;

        // 2) Award XP and collect level-up info
        var _infos = [];
        if (ds_exists(global.battle_party, ds_type_list)) {
            for (var i = 0; i < ds_list_size(global.battle_party); i++) {
                var inst = global.battle_party[| i];
                if (!instance_exists(inst)) continue;
                if (!variable_instance_exists(inst, "data") || inst.data.hp <= 0) continue;

                // Capture the **equipped** stats before leveling
                var oldStats = {
                    maxhp: inst.data.maxhp,
                    maxmp: inst.data.maxmp,
                    atk:   inst.data.atk,
                    def:   inst.data.def,
                    matk:  inst.data.matk,
                    mdef:  inst.data.mdef,
                    spd:   inst.data.spd,
                    luk:   inst.data.luk
                };

                // Award XP (this may bump level & base stats)
                var didLevel = scr_AddXPToCharacter(inst.character_key, total_xp_from_battle);
                if (!didLevel) continue;

                // Get the **base** stats from your persistent/template data
                var baseAfter = scr_GetPlayerData(inst.character_key);

                // Now re-apply equipment if that helper exists
                var withEquip = baseAfter;
                if (script_exists(scr_CalculateEquippedStats)) {
                    withEquip = scr_CalculateEquippedStats(baseAfter, inst.data.equipment);
                }

                // Build the new equipped stats
                var newStats = {
                    maxhp: withEquip.maxhp,
                    maxmp: withEquip.maxmp,
                    atk:   withEquip.atk,
                    def:   withEquip.def,
                    matk:  withEquip.matk,
                    mdef:  withEquip.mdef,
                    spd:   withEquip.spd,
                    luk:   withEquip.luk
                };

                array_push(_infos, {
                    name: inst.data.name ?? "Unknown",
                    old:  oldStats,
                    new:  newStats
                });
            }
        }
        global.battle_level_up_infos = _infos;

        // 3) Next step: either show popups or return
        if (array_length(_infos) > 0) {
            global.battle_state         = "show_levelup";
            global.battle_levelup_index = 0;
            instance_create_layer(0, 0, "Instances", obj_levelup_popup);
        } else {
            global.battle_state = "return_to_field";
            alarm[0] = 60;
        }
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

        // Save HP/MP/OD back to global stats
        if (ds_exists(global.battle_party, ds_type_list)
         && ds_exists(global.party_current_stats, ds_type_map)) {
            for (var i = 0; i < ds_list_size(global.battle_party); i++) {
                var inst = global.battle_party[| i];
                if (!instance_exists(inst)) continue;
                var key = inst.character_key;
                var stats = ds_map_find_value(global.party_current_stats, key);
                if (!is_struct(stats)) continue;

                stats.hp        = max(0, inst.data.hp);
                stats.mp        = max(0, inst.data.mp);
                stats.overdrive = clamp(inst.data.overdrive, 0, inst.data.overdrive_max);
                stats.level     = inst.data.level;
                stats.xp        = inst.data.xp;
                stats.xp_require= inst.data.xp_require;

                ds_map_replace(global.party_current_stats, key, stats);
            }
        }

        // Cleanup instances and DS
        with (obj_battle_player)  instance_destroy();
        with (obj_battle_enemy)   instance_destroy();
        with (obj_battle_menu)    instance_destroy();
        with (obj_dialog)         instance_destroy();
        with (obj_attack_visual)  instance_destroy();
        with (obj_popup_damage)   instance_destroy();

        if (ds_exists(global.battle_party, ds_type_list))     ds_list_destroy(global.battle_party);
        if (ds_exists(global.battle_enemies, ds_type_list))   ds_list_destroy(global.battle_enemies);
        if (ds_exists(global.battle_status_effects, ds_type_map)) ds_map_destroy(global.battle_status_effects);
        if (ds_exists(combatants_all, ds_type_list))          ds_list_destroy(combatants_all);

        global.battle_party         = -1;
        global.battle_enemies       = -1;
        global.battle_status_effects= -1;
        combatants_all              = -1;
        stored_action_data          = undefined;
        selected_target_id          = noone;
        currentActor                = noone;
        global.active_party_member_index = 0;
        global.battle_target        = 0;

        // Return to original room
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
