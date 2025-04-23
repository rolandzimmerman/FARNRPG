/// obj_battle_manager :: Alarm[0]
// Handles timed transitions between battle states. Updates persistent stats on return.

show_debug_message("⏰ BattleManager Alarm[0] Triggered — Current State: " + string(global.battle_state) + " !!!");

switch (global.battle_state) {

    case "waiting_next_enemy":
        // show_debug_message("   Alarm 0: waiting_next_enemy -> enemy_turn"); // Optional log
        global.battle_state = "enemy_turn"; // Move to the next enemy's action
    break; // <<< Correct break

    case "waiting_enemy":
        // show_debug_message("   Alarm 0: waiting_enemy -> enemy_turn"); // Optional log
        global.battle_state = "enemy_turn"; // Start the first enemy's action
    break; // <<< Correct break

    case "victory":
        show_debug_message("🏆 Alarm 0: Processing Victory. Total XP: " + string(total_xp_from_battle));
        // --- XP Award (Distribute to all living party members) ---
        if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) {
            var _party_size = ds_list_size(global.battle_party);
            var _living_count = 0;
            // First, count living members
            for (var i = 0; i < _party_size; i++) {
                var p = global.battle_party[| i];
                if (instance_exists(p) && variable_instance_exists(p,"data") && is_struct(p.data) && p.data.hp > 0) {
                    _living_count++;
                }
            }

            // Distribute XP if anyone is alive
            if (_living_count > 0) {
                 var _xp_each = floor(total_xp_from_battle / _living_count);
                 // show_debug_message("   Distributing " + string(_xp_each) + " XP to " + string(_living_count) + " living members."); // Optional log
                 for (var i = 0; i < _party_size; i++) {
                     var p = global.battle_party[| i];
                     // Award XP only to living members
                     if (instance_exists(p) && variable_instance_exists(p,"data") && is_struct(p.data) && p.data.hp > 0) {
                          // Find the corresponding persistent character object or data to add XP
                          if (p.data.character_key == "hero" && instance_exists(obj_player)) {
                               // Use the add_xp method defined on obj_player
                               with (obj_player) {
                                   if (variable_instance_exists(id, "add_xp")) {
                                        add_xp(_xp_each);
                                   }
                               }
                          } else {
                               // --- FIX: Corrected Comment ---
                               // TODO: Implement XP gain and level up logic for other party members
                               // show_debug_message("   TODO: Add XP logic for character: " + p.data.character_key); // Optional log
                               // --- End Fix ---
                          }
                     }
                 } // End XP distribution loop
            } // else { show_debug_message("   No living party members to distribute XP to."); } // Optional log
        } // End check if battle_party exists
        // --- End XP Award ---

        // Victory Dialogue
        if (script_exists(scr_dialogue)) { if (!variable_global_exists("char_colors")) global.char_colors={}; create_dialog([{ name:"Victory!", msg: "You gained " + string(total_xp_from_battle) + " XP!" }]); }
        global.battle_state = "return_to_field"; alarm[0] = 120;
    break; // <<< Correct break

     case "defeat":
         show_debug_message("☠️ Alarm 0: Processing Defeat.");
         if (script_exists(scr_dialogue)) { create_dialog([{ name:"Defeat", msg:"You have been defeated..." }]); }
         global.battle_state = "return_to_field"; alarm[0] = 120;
    break; // <<< Correct break

    case "return_to_field":
        show_debug_message("   Alarm 0: Returning to field map.");
        // --- Update ALL Party Members' Persistent Stats ---
        if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list) && variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) { var _bsize = ds_list_size(global.battle_party); for (var i = 0; i < _bsize; i++) { var _bi = global.battle_party[| i]; if (instance_exists(_bi) && variable_instance_exists(_bi, "data") && is_struct(_bi.data)) { var _bd = _bi.data; var _ck = _bd.character_key; if (_ck == "hero" && instance_exists(obj_player)) { obj_player.hp = max(1, _bd.hp); obj_player.mp = _bd.mp; } else { var _cs = ds_map_find_value(global.party_current_stats, _ck); if (is_struct(_cs)) { _cs.hp = max(1, _bd.hp); _cs.mp = _bd.mp; } else { var _new_entry = { hp: max(1, _bd.hp), mp: _bd.mp, level: _bd.level, xp: _bd.xp }; ds_map_add(global.party_current_stats, _ck, _new_entry); } } } } }
        // --- Cleanup DS Lists & Reset Vars ---
        if (ds_exists(global.battle_enemies, ds_type_list)) ds_list_destroy(global.battle_enemies); global.battle_enemies = -1;
        if (ds_exists(global.battle_party, ds_type_list)) ds_list_destroy(global.battle_party); global.battle_party = -1;
        total_xp_from_battle = 0; global.battle_state = undefined; alarm[0] = -1; global.battle_target = 0; global.enemy_turn_index = 0; stored_action_data = undefined; selected_target_id = noone; global.active_party_member_index = 0;
        // --- Go to room ---
        if (variable_global_exists("original_room") && room_exists(global.original_room)) { if (instance_exists(obj_player) && variable_global_exists("return_x") && variable_global_exists("return_y")) { with(obj_player) { x = global.return_x; y = global.return_y; } } room_goto(global.original_room); }
        else { instance_destroy(); exit; }
        instance_destroy(); // Manager destroys self
    break; // <<< Correct break

    default:
        show_debug_message("   -> Alarm[0] triggered in unhandled state: " + string(global.battle_state) + ". Stopping alarm.");
        alarm[0] = -1; // Stop alarm if state is unexpected
    break; // <<< Correct break for default case
} // End Switch