/// obj_battle_manager :: Alarm[0]
/// Handles timed transitions, victory/defeat processing, saving persistent stats individually, and cleaning up status map.

show_debug_message("⏰ BattleManager Alarm[0] Triggered — Current State: " + string(global.battle_state) + " !!!");

switch (global.battle_state) {

    // --- Enemy-phase timers ---
    case "waiting_next_enemy":
    case "waiting_enemy":
        show_debug_message("   -> Alarm setting state to enemy_turn");
        global.battle_state = "enemy_turn";
        break;


    // --- Victory: award XP, show dialogue, then save XP/Level immediately ---
    case "victory":
    {
        show_debug_message("🏆 Alarm 0: Processing Victory. Total XP Accumulated: " + string(total_xp_from_battle));
        var leveled_up_characters = [];

        // 1) Award XP and level-ups
        if (ds_exists(global.battle_party, ds_type_list) && script_exists(scr_AddXPToCharacter)) {
            var partyCount = ds_list_size(global.battle_party);
            for (var i = 0; i < partyCount; i++) {
                var inst = global.battle_party[| i];
                if (!instance_exists(inst) || !variable_instance_exists(inst, "data") || !is_struct(inst.data) || inst.data.hp <= 0) continue;
                var key = inst.data.character_key;
                var didLevel = scr_AddXPToCharacter(key, total_xp_from_battle);
                if (didLevel) array_push(leveled_up_characters, inst.data.name);
                // Reflect new level & XP back onto the instance for UI/debug
                var pers = ds_map_find_value(global.party_current_stats, key);
                if (is_struct(pers)) {
                    inst.data.level      = pers.level;
                    inst.data.xp         = pers.xp;
                    inst.data.xp_require = pers.xp_require;
                }
            }
        }

        // 2) Build and show victory dialogue
        var messages = [];
        array_push(messages, { name:"Victory!", msg:"Gained " + string(total_xp_from_battle) + " XP!" });
        if (array_length(leveled_up_characters) > 0) {
            var upMsg = "";
            if (array_length(leveled_up_characters) == 1) {
                upMsg = leveled_up_characters[0] + " leveled up!";
            } else {
                for (var j = 0; j < array_length(leveled_up_characters); j++) {
                    upMsg += leveled_up_characters[j];
                    if (j < array_length(leveled_up_characters) - 2) upMsg += ", ";
                    else if (j == array_length(leveled_up_characters) - 2) upMsg += " and ";
                }
                upMsg += " leveled up!";
            }
            array_push(messages, { name:"System", msg:upMsg });
        }
        if (script_exists(scr_dialogue) && script_exists(create_dialog)) {
            var dlgLayer = layer_exists("Instances_GUI") ? "Instances_GUI" : "Instances";
            var dlg = instance_create_layer(0, 0, dlgLayer, obj_dialog);
            dlg.messages = messages;
        }

        // 3) Schedule return and cleanup
        global.battle_state = "return_to_field";
        alarm[0] = 120;
    }
    break;


    // --- Defeat: show dialogue, then return ---
    case "defeat":
    {
        show_debug_message("😭 Alarm 0: Processing Defeat.");
        if (script_exists(scr_dialogue) && script_exists(create_dialog)) {
            var dLayer = layer_exists("Instances_GUI") ? "Instances_GUI" : "Instances";
            var defeatDlg = instance_create_layer(0, 0, dLayer, obj_dialog);
            defeatDlg.messages = [{ name:"Defeat", msg:"You have been defeated..." }];
        }
        global.battle_state = "return_to_field";
        alarm[0] = 120;
    }
    break;


    // --- Return to field: save only HP/MP, then cleanup & go back ---
    case "return_to_field":
    {
        show_debug_message("    Alarm 0: Returning to field map.");
        show_debug_message("    Saving persistent party stats (HP, MP)...");

        if (ds_exists(global.battle_party, ds_type_list) && ds_exists(global.party_current_stats, ds_type_map)) {
            var count = ds_list_size(global.battle_party);
            for (var i = 0; i < count; i++) {
                var inst = global.battle_party[| i];
                if (!instance_exists(inst) || !variable_instance_exists(inst, "data") || !is_struct(inst.data)) continue;
                var key = inst.data.character_key;
                if (!is_string(key) || !ds_map_exists(global.party_current_stats, key)) continue;
                var pers = ds_map_find_value(global.party_current_stats, key);
                show_debug_message("        -> Before Save [" + key + "]: HP=" + string(pers.hp) + ", MP=" + string(pers.mp));
                pers.hp = max(1, inst.data.hp);
                pers.mp = inst.data.mp;
                ds_map_replace(global.party_current_stats, key, pers);
                show_debug_message("        -> After Save  [" + key + "]: HP=" + string(pers.hp) + ", MP=" + string(pers.mp));
            }
        } else {
            show_debug_message("    -> ERROR: Cannot save stats (missing DS structures).");
        }

        // Cleanup battle data structures
        if (ds_exists(global.battle_enemies, ds_type_list)) { ds_list_destroy(global.battle_enemies); global.battle_enemies = -1; }
        if (ds_exists(global.battle_party,   ds_type_list)) { ds_list_destroy(global.battle_party);   global.battle_party   = -1; }
        if (ds_exists(global.battle_status_effects, ds_type_map)) { ds_map_destroy(global.battle_status_effects); global.battle_status_effects = -1; }

        total_xp_from_battle             = 0;
        global.battle_state              = undefined;
        alarm[0]                         = -1;
        global.battle_target             = 0;
        global.enemy_turn_index          = 0;
        stored_action_data               = undefined;
        selected_target_id               = noone;
        global.active_party_member_index = 0;

        // Return to field room
        if (variable_global_exists("original_room") && room_exists(global.original_room)) {
            if (instance_exists(obj_player) && variable_global_exists("return_x") && variable_global_exists("return_y")) {
                with (obj_player) {
                    x = global.return_x;
                    y = global.return_y;
                }
            }
            instance_activate_all();
            room_goto(global.original_room);
        } else {
            show_debug_message("ERROR: Cannot return to field map!");
            instance_destroy();
            exit;
        }
        instance_destroy();
    }
    break;


    // --- Fallback ---
    default:
        show_debug_message("    -> Alarm[0] in unhandled state: " + string(global.battle_state));
        alarm[0] = -1;
        break;
} // End Switch
