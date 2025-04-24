/// obj_battle_manager :: Alarm[0]
// Handles timed transitions between battle states, enemy actions, and updates persistent stats on return.

show_debug_message("⏰ BattleManager Alarm[0] Triggered — Current State: " + string(global.battle_state) + " !!!");

switch (global.battle_state) {

    case "waiting_next_enemy":
        global.battle_state = "enemy_turn";
    break; // <<< Correct break

    case "waiting_enemy":
        global.battle_state = "enemy_turn";
    break; // <<< Correct break

    case "victory":
        show_debug_message("🏆 Alarm 0: Processing Victory. Total XP: " + string(total_xp_from_battle));

        var leveled_up_characters = []; // List to store names

        // --- XP Award (Grant FULL amount to all living party members) ---
        if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) {
            var _party_size = ds_list_size(global.battle_party);
            var _living_count = 0;
            for (var i = 0; i < _party_size; i++) { var p = global.battle_party[| i]; if (instance_exists(p) && variable_instance_exists(p,"data") && is_struct(p.data) && p.data.hp > 0) { _living_count++; } }

            if (_living_count > 0 && variable_instance_exists(id, "total_xp_from_battle") && total_xp_from_battle > 0) { // Added check for total_xp_from_battle variable
                 var _xp_to_grant = total_xp_from_battle;
                 show_debug_message("   Granting " + string(_xp_to_grant) + " XP to " + string(_living_count) + " living members.");
                 for (var i = 0; i < _party_size; i++) {
                     var p_inst = global.battle_party[| i];
                     if (instance_exists(p_inst) && variable_instance_exists(p_inst,"data") && is_struct(p_inst.data) && p_inst.data.hp > 0) {
                          var p_data = p_inst.data; // The battle instance's data struct
                          var p_key = p_data.character_key;
                          var p_name = p_data.name;

                          if (script_exists(scr_AddXPToCharacter)) {
                               var did_level_up = scr_AddXPToCharacter(p_key, _xp_to_grant); // Modifies persistent source
                               if (did_level_up) {
                                   array_push(leveled_up_characters, p_name);
                               }

                               // --- Update the battle instance data (p_data) with ONLY the stats changed by leveling ---
                               var _persistent_stats_source = undefined;
                               if (p_key == "hero" && instance_exists(obj_player)) { _persistent_stats_source = obj_player; }
                               else { _persistent_stats_source = ds_map_find_value(global.party_current_stats, p_key); }

                               if (!is_undefined(_persistent_stats_source) && (is_struct(_persistent_stats_source) || instance_exists(_persistent_stats_source))) {
                                    show_debug_message("     Updating battle instance level/xp/stats for " + p_key + " after XP gain...");
                                    p_data.level = _persistent_stats_source.level;
                                    p_data.xp = _persistent_stats_source.xp;
                                    p_data.xp_require = _persistent_stats_source.xp_require;
                                    p_data.maxhp = _persistent_stats_source.hp_total;
                                    p_data.maxmp = _persistent_stats_source.mp_total;
                                    p_data.atk = _persistent_stats_source.atk;
                                    p_data.def = _persistent_stats_source.def;
                                    p_data.matk = _persistent_stats_source.matk;
                                    p_data.mdef = _persistent_stats_source.mdef;
                                    p_data.spd = _persistent_stats_source.spd;
                                    p_data.luk = _persistent_stats_source.luk;
                                    // DO NOT update p_data.hp or p_data.mp here! Leave them as the end-of-battle values.
                                    show_debug_message("       -> Battle Instance Level: " + string(p_data.level) + ", XP: " + string(p_data.xp) + "/" + string(p_data.xp_require));
                               }
                               // --- End Update Battle Instance Data ---
                          }
                     }
                 }
            } else { /* No living or no XP */ }
        }
        // --- End XP Award ---

        // --- Build Dialogue Messages ---
        var dialogue_messages = [];
        array_push(dialogue_messages, { name:"Victory!", msg: "You gained " + string(total_xp_from_battle) + " XP!" });
        var num_leveled_up = array_length(leveled_up_characters);
        if (num_leveled_up > 0) {
            var level_up_msg = "";
            if (num_leveled_up == 1) { level_up_msg = leveled_up_characters[0] + " leveled up!"; }
            else { for (var j = 0; j < num_leveled_up; j++) { level_up_msg += leveled_up_characters[j]; if (j < num_leveled_up - 2) { level_up_msg += ", "; } else if (j == num_leveled_up - 2) { level_up_msg += " and "; } } level_up_msg += " leveled up!"; }
            array_push(dialogue_messages, { name:"System", msg: level_up_msg });
        }
        // --- End Build Dialogue ---

        if (script_exists(scr_dialogue)) { if (!variable_global_exists("char_colors")) global.char_colors={}; create_dialog(dialogue_messages); }
        global.battle_state = "return_to_field"; alarm[0] = 120; // Wait for dialogue
    break; // <<< End Victory Case

     case "defeat":
         if (script_exists(scr_dialogue)) { create_dialog([{ name:"Defeat", msg:"You have been defeated..." }]); }
         global.battle_state = "return_to_field"; alarm[0] = 120;
    break; // <<< End Defeat Case

    case "return_to_field":
        show_debug_message("   Alarm 0: Returning to field map.");
        // --- Update ALL Party Members' Persistent Stats ---
        show_debug_message("   Updating persistent party stats...");
        if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list) &&
            variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map))
        {
            var _battle_party_size = ds_list_size(global.battle_party);
            for (var i = 0; i < _battle_party_size; i++) {
                var _b_inst = global.battle_party[| i];
                if (instance_exists(_b_inst) && variable_instance_exists(_b_inst, "data") && is_struct(_b_inst.data)) {
                    var _b_data = _b_inst.data; // Data FROM the battle instance
                    var _char_key = _b_data.character_key;

                    show_debug_message("     [ReturnToField] Processing save for: " + _char_key + " | Battle HP: " + string(_b_data.hp) + " | Battle Lvl: " + string(_b_data.level) + " | Battle XP: " + string(_b_data.xp));

                    if (_char_key == "hero") {
                        if (instance_exists(obj_player)) {
                            show_debug_message("       -> Saving stats TO obj_player instance (ID: " + string(obj_player.id) + ")");
                            // Save ALL stats from _b_data back to obj_player
                            // _b_data.hp and _b_data.mp should now have the correct end-of-battle values
                            obj_player.hp = max(1, _b_data.hp);
                            obj_player.mp = _b_data.mp;
                            obj_player.level = _b_data.level;
                            obj_player.xp = _b_data.xp;
                            obj_player.xp_require = _b_data.xp_require;
                            obj_player.hp_total = _b_data.maxhp;
                            obj_player.mp_total = _b_data.maxmp;
                            obj_player.atk = _b_data.atk;
                            obj_player.def = _b_data.def;
                            obj_player.matk = _b_data.matk;
                            obj_player.mdef = _b_data.mdef;
                            obj_player.spd = _b_data.spd;
                            obj_player.luk = _b_data.luk;
                            show_debug_message("         -> Saved HP: " + string(obj_player.hp) + ", Level: " + string(obj_player.level) + ", XP: " + string(obj_player.xp) + "/" + string(obj_player.xp_require));
                        } else { /* Warning */ }
                    } else { // For other characters
                        var _persistent_stats_target = ds_map_find_value(global.party_current_stats, _char_key);
                        if (is_struct(_persistent_stats_target)) {
                            show_debug_message("       -> Saving stats TO global map for '" + _char_key + "'");
                            // Save ALL stats from _b_data back to the map struct
                            _persistent_stats_target.hp = max(1, _b_data.hp);
                            _persistent_stats_target.mp = _b_data.mp;
                            _persistent_stats_target.level = _b_data.level;
                            _persistent_stats_target.xp = _b_data.xp;
                            _persistent_stats_target.xp_require = _b_data.xp_require;
                            _persistent_stats_target.hp_total = _b_data.maxhp;
                            _persistent_stats_target.mp_total = _b_data.maxmp;
                            _persistent_stats_target.atk = _b_data.atk;
                            _persistent_stats_target.def = _b_data.def;
                            _persistent_stats_target.matk = _b_data.matk;
                            _persistent_stats_target.mdef = _b_data.mdef;
                            _persistent_stats_target.spd = _b_data.spd;
                            _persistent_stats_target.luk = _b_data.luk;
                             show_debug_message("         -> Saved HP: " + string(_persistent_stats_target.hp) + ", Level: " + string(_persistent_stats_target.level) + ", XP: " + string(_persistent_stats_target.xp) + "/" + string(_persistent_stats_target.xp_require));
                        } else { /* Warning */ }
                    }
                }
            } // End for loop
        } else { /* Warning */ }
        // --- End Stat Update ---

        // --- Cleanup DS Lists & Reset Vars ---
        if (variable_global_exists("battle_enemies") && ds_exists(global.battle_enemies, ds_type_list)) { ds_list_destroy(global.battle_enemies); global.battle_enemies = -1;}
        if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) { ds_list_destroy(global.battle_party); global.battle_party = -1; }
        total_xp_from_battle = 0; global.battle_state = undefined; alarm[0] = -1; global.battle_target = 0; global.enemy_turn_index = 0; stored_action_data = undefined; selected_target_id = noone; global.active_party_member_index = 0;

        // --- Go to room ---
        if (variable_global_exists("original_room") && room_exists(global.original_room)) { if (instance_exists(obj_player) && variable_global_exists("return_x") && variable_global_exists("return_y")) { with(obj_player) { x = global.return_x; y = global.return_y; } } room_goto(global.original_room); }
        else { instance_destroy(); exit; }

        instance_destroy(); // Manager destroys self
    break; // <<< End return_to_field Case

    default:
        show_debug_message("   -> Alarm[0] triggered in unhandled state: " + string(global.battle_state) + ". Stopping alarm.");
        alarm[0] = -1;
    break;
} // End Switch