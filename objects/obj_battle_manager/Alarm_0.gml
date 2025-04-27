/// obj_battle_manager :: Alarm[0]
/// Handles timed transitions, victory/defeat processing, saving persistent stats individually, and cleaning up status map.

show_debug_message("⏰ BattleManager Alarm[0] Triggered — Current State: " + string(global.battle_state) + " !!!");

switch (global.battle_state) {

    case "waiting_next_enemy":
    case "waiting_enemy":
        show_debug_message("   -> Alarm setting state to enemy_turn"); // Log state change
        global.battle_state = "enemy_turn";
        // Step event will now immediately process enemy turn
        break;

    case "victory":
        show_debug_message("🏆 Alarm 0: Processing Victory. Total XP Accumulated: " + string(total_xp_from_battle));
        var leveled_up_characters = [];

        // --- XP Award ---
        if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) {
            var _party_size = ds_list_size(global.battle_party);
            var _living_count = 0;
            // Count living members first
            for (var i = 0; i < _party_size; i++) {
                var p = global.battle_party[| i];
                if (instance_exists(p) && variable_instance_exists(p,"data") && is_struct(p.data) && variable_struct_exists(p.data,"hp") && p.data.hp > 0) {
                     _living_count++;
                 }
            }

            if (_living_count > 0 && variable_instance_exists(id, "total_xp_from_battle") && total_xp_from_battle > 0) {
                 var _xp_to_grant = total_xp_from_battle;
                 show_debug_message("    Granting " + string(_xp_to_grant) + " XP to " + string(_living_count) + " living members.");
                 for (var i = 0; i < _party_size; i++) {
                     var p_inst = global.battle_party[| i];
                     // Check if instance is valid and alive
                     if (instance_exists(p_inst) && variable_instance_exists(p_inst,"data") && is_struct(p_inst.data) && p_inst.data.hp > 0) {
                         var p_data = p_inst.data; // Battle instance data
                         var p_key = p_data.character_key;
                         var p_name = p_data.name;

                         if (script_exists(scr_AddXPToCharacter)) {
                             var did_level_up = scr_AddXPToCharacter(p_key, _xp_to_grant); // Modifies persistent map entry directly
                             if (did_level_up) { array_push(leveled_up_characters, p_name); }

                             // Update the battle instance's data struct (p_data) AFTER potential level up
                             var _persistent_stats_source = ds_map_find_value(global.party_current_stats, p_key);
                             if (is_struct(_persistent_stats_source)) {
                                 p_data.level = variable_struct_exists(_persistent_stats_source, "level") ? _persistent_stats_source.level : p_data.level;
                                 p_data.xp = variable_struct_exists(_persistent_stats_source, "xp") ? _persistent_stats_source.xp : p_data.xp;
                                 p_data.xp_require = variable_struct_exists(_persistent_stats_source, "xp_require") ? _persistent_stats_source.xp_require : p_data.xp_require;
                                 p_data.maxhp = variable_struct_exists(_persistent_stats_source, "hp_total") ? _persistent_stats_source.hp_total : (variable_struct_exists(_persistent_stats_source, "maxhp") ? _persistent_stats_source.maxhp : p_data.maxhp);
                                 p_data.maxmp = variable_struct_exists(_persistent_stats_source, "mp_total") ? _persistent_stats_source.mp_total : (variable_struct_exists(_persistent_stats_source, "maxmp") ? _persistent_stats_source.maxmp : p_data.maxmp);
                                 p_data.atk = variable_struct_exists(_persistent_stats_source, "atk") ? _persistent_stats_source.atk : p_data.atk;
                                 p_data.def = variable_struct_exists(_persistent_stats_source, "def") ? _persistent_stats_source.def : p_data.def;
                                 p_data.matk = variable_struct_exists(_persistent_stats_source, "matk") ? _persistent_stats_source.matk : p_data.matk;
                                 p_data.mdef = variable_struct_exists(_persistent_stats_source, "mdef") ? _persistent_stats_source.mdef : p_data.mdef;
                                 p_data.spd = variable_struct_exists(_persistent_stats_source, "spd") ? _persistent_stats_source.spd : p_data.spd;
                                 p_data.luk = variable_struct_exists(_persistent_stats_source, "luk") ? _persistent_stats_source.luk : p_data.luk;
                                 if (variable_struct_exists(_persistent_stats_source,"skills")) { p_data.skills = _persistent_stats_source.skills; }
                             }
                         } else { show_debug_message("ERROR: scr_AddXPToCharacter script missing!"); }
                     } // End if instance valid & alive
                 } // End for loop granting XP
            } else {
                  show_debug_message("    -> XP Award SKIPPED (No living members or total_xp_from_battle is zero/missing)");
            }
        } else { show_debug_message("ERROR: Battle party list missing during XP Award!"); }
        // --- End XP Award ---

        // --- Build Dialogue Messages ---
        var dialogue_messages = []; array_push(dialogue_messages, { name:"Victory!", msg: "Gained " + string(total_xp_from_battle) + " XP!" }); var num_leveled_up = array_length(leveled_up_characters); if (num_leveled_up > 0) { var level_up_msg = ""; if (num_leveled_up == 1) { level_up_msg = leveled_up_characters[0] + " leveled up!"; } else { for (var j = 0; j < num_leveled_up; j++) { level_up_msg += leveled_up_characters[j]; if (j < num_leveled_up - 2) { level_up_msg += ", "; } else if (j == num_leveled_up - 2) { level_up_msg += " and "; } } level_up_msg += " leveled up!"; } array_push(dialogue_messages, { name:"System", msg: level_up_msg }); }
        // --- Create Dialogue Box ---
        if (script_exists(scr_dialogue) && script_exists(create_dialog)) { if (!variable_global_exists("char_colors")) global.char_colors={}; var _layer_name = "Instances_GUI"; if (!layer_exists(_layer_name)) _layer_name = "Instances"; if (layer_exists(_layer_name)) { instance_create_layer(0, 0, _layer_name, obj_dialog).messages = dialogue_messages; } else { show_debug_message("ERROR [BattleManager Alarm]: Could not find layer for victory dialog!"); } } else { show_debug_message("ERROR [BattleManager Alarm]: scr_dialogue or create_dialog script missing!"); }

        global.battle_state = "return_to_field"; alarm[0] = 120;
        break;

     case "defeat":
        show_debug_message("😭 Alarm 0: Processing Defeat."); if (script_exists(scr_dialogue) && script_exists(create_dialog)) { var _layer_name = "Instances_GUI"; if (!layer_exists(_layer_name)) _layer_name = "Instances"; if (layer_exists(_layer_name)) { instance_create_layer(0, 0, _layer_name, obj_dialog).messages = [{ name:"Defeat", msg:"You have been defeated..." }]; } else { show_debug_message("ERROR [BattleManager Alarm]: Could not find layer for defeat dialog!"); } } else { show_debug_message("ERROR [BattleManager Alarm]: scr_dialogue or create_dialog script missing!"); }
        global.battle_state = "return_to_field"; alarm[0] = 120;
        break;

    case "return_to_field":
        show_debug_message("    Alarm 0: Returning to field map.");
        // --- Update ALL Party Members' Persistent Stats in the MAP ---
        show_debug_message("    Updating persistent party stats (HP,MP,Level,XP,XP_Req)...");
        if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list) && variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) {
            var _battle_party_size = ds_list_size(global.battle_party);
            for (var i = 0; i < _battle_party_size; i++) {
                var _b_inst = global.battle_party[| i];
                if (instance_exists(_b_inst) && variable_instance_exists(_b_inst, "data") && is_struct(_b_inst.data)) {
                    var _b_data = _b_inst.data; var _char_key = variable_struct_exists(_b_data, "character_key") ? _b_data.character_key : undefined;
                    if (is_string(_char_key)) {
                        // <<< REVERTED SAVE METHOD: Find persistent struct and update fields >>>
                        var _persistent_stats_target = ds_map_find_value(global.party_current_stats, _char_key);
                        if (is_struct(_persistent_stats_target)) {
                            show_debug_message("        -> Saving stats TO global map for '" + _char_key + "'");
                            show_debug_message("          -> MAP BEFORE Save: Lvl=" + string(_persistent_stats_target.level ?? "N/A") + ", XP=" + string(_persistent_stats_target.xp ?? "N/A") + ", HP=" + string(_persistent_stats_target.hp ?? "N/A"));

                            // Update persistent struct fields from the final battle instance data
                            _persistent_stats_target.hp = max(1, _b_data.hp);        // Current HP
                            _persistent_stats_target.mp = _b_data.mp;                // Current MP
                            _persistent_stats_target.level = _b_data.level;            // Final Level
                            _persistent_stats_target.xp = _b_data.xp;                  // Final XP
                            _persistent_stats_target.xp_require = _b_data.xp_require;  // Final XP Req

                            // Verify Save by reading back from the map struct reference immediately
                            show_debug_message("          -> MAP AFTER Save: Lvl=" + string(_persistent_stats_target.level ?? "N/A") + ", XP=" + string(_persistent_stats_target.xp ?? "N/A") + ", HP=" + string(_persistent_stats_target.hp ?? "N/A"));
                        } else { show_debug_message("        -> ERROR: Persistent struct not found in map for '" + _char_key + "' during save!"); }
                    } else { show_debug_message("       -> ERROR: Invalid character key found in battle instance data for index " + string(i)); }
                } else { show_debug_message("       -> ERROR: Invalid battle instance or data for index " + string(i)); }
            } // End for loop
        } else { show_debug_message("    -> ERROR: Battle party list or stats map missing during save!"); }

        // --- Cleanup DS Lists & Reset Vars ---
        show_debug_message("    -> Cleaning up battle resources...");
        if (variable_global_exists("battle_enemies") && ds_exists(global.battle_enemies, ds_type_list)) { ds_list_destroy(global.battle_enemies); global.battle_enemies = -1; show_debug_message("      -> Destroyed battle_enemies list."); }
        if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) { ds_list_destroy(global.battle_party); global.battle_party = -1; show_debug_message("      -> Destroyed battle_party list."); }
        if (variable_global_exists("battle_status_effects") && ds_exists(global.battle_status_effects, ds_type_map)) { ds_map_destroy(global.battle_status_effects); global.battle_status_effects = -1; show_debug_message("      -> Destroyed battle_status_effects map.");}
        total_xp_from_battle = 0; global.battle_state = undefined; alarm[0] = -1; global.battle_target = 0; global.enemy_turn_index = 0; stored_action_data = undefined; selected_target_id = noone; global.active_party_member_index = 0;
        show_debug_message("    -> Battle variables reset.");

        // --- Go back to field map ---
        show_debug_message("    -> Returning to room: " + string(global.original_room ?? "UNDEFINED"));
        if (variable_global_exists("original_room") && room_exists(global.original_room)) { if (instance_exists(obj_player)) { if (variable_global_exists("return_x") && variable_global_exists("return_y")) { with(obj_player) { x = global.return_x; y = global.return_y; } show_debug_message("      -> Player position set."); } } instance_activate_all(); room_goto(global.original_room); }
        else { show_debug_message("ERROR: Cannot return to field map!"); instance_destroy(); exit; }
        instance_destroy(); // Manager destroys self AFTER initiating room change
        break;

    default:
        show_debug_message("    -> Alarm[0] triggered in unhandled state: " + string(global.battle_state) + ". Stopping alarm.");
        alarm[0] = -1;
        break;
} // End Switch