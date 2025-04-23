/// obj_battle_manager :: Alarm[0]
// Handles timed transitions between battle states. Updates persistent stats on return.

show_debug_message("⏰ BattleManager Alarm[0] Triggered — Current State: " + string(global.battle_state) + " !!!");

switch (global.battle_state) {

    case "waiting_next_enemy": global.battle_state = "enemy_turn"; break;
    case "waiting_enemy":      global.battle_state = "enemy_turn"; break;

    case "victory":
        show_debug_message("🏆 Alarm 0: Processing Victory. Total XP: " + string(total_xp_from_battle));
        // --- XP Award ---
        if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) {
            var _party_size = ds_list_size(global.battle_party);
            var _living_count = 0;
            for (var i = 0; i < _party_size; i++) { var p = global.battle_party[| i]; if (instance_exists(p) && p.data.hp > 0) _living_count++; }
            if (_living_count > 0 && total_xp_from_battle > 0) {
                 var _xp_each = floor(total_xp_from_battle / _living_count);
                 for (var i = 0; i < _party_size; i++) {
                     var p = global.battle_party[| i];
                     if (instance_exists(p) && p.data.hp > 0) {
                          if (script_exists(scr_AddXPToCharacter)) { scr_AddXPToCharacter(p.data.character_key, _xp_each); }
                     }
                 }
            }
        }
        // --- End XP Award ---
        if (script_exists(scr_dialogue)) { if (!variable_global_exists("char_colors")) global.char_colors={}; create_dialog([{ name:"Victory!", msg: "You gained " + string(total_xp_from_battle) + " XP!" }]); }
        global.battle_state = "return_to_field"; alarm[0] = 120;
    break;

     case "defeat":
         if (script_exists(scr_dialogue)) { create_dialog([{ name:"Defeat", msg:"You have been defeated..." }]); }
         global.battle_state = "return_to_field"; alarm[0] = 120;
    break;

    case "return_to_field":
        show_debug_message("   Alarm 0: Returning to field map.");
        // --- Update ALL Party Members' Persistent Stats ---
        show_debug_message("   Updating persistent party stats...");
        if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list) &&
            variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map))
        {
            var _battle_party_size = ds_list_size(global.battle_party);
            for (var i = 0; i < _battle_party_size; i++) {
                var _b_inst = global.battle_party[| i];
                if (instance_exists(_b_inst) && variable_instance_exists(_b_inst, "data") && is_struct(_b_inst.data)) {
                    var _b_data = _b_inst.data; // Data from the battle instance (reflects end-of-battle state including level ups)
                    var _char_key = _b_data.character_key;

                    show_debug_message("     [ReturnToField] Processing save for: " + _char_key);

                    // --- FIX: Separate logic for Hero (obj_player) and others (map) ---
                    if (_char_key == "hero") {
                        if (instance_exists(obj_player)) {
                            show_debug_message("       -> Saving stats to obj_player instance.");
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
                            show_debug_message("         -> Saved HP: " + string(obj_player.hp) + ", Level: " + string(obj_player.level) + ", XP: " + string(obj_player.xp) + "/" + string(obj_player.xp_require));
                        } else {
                             show_debug_message("     [ReturnToField] WARNING: obj_player instance missing! Cannot save Hero stats.");
                        }
                    } else { // For other characters like Claude
                        var _persistent_stats_target = ds_map_find_value(global.party_current_stats, _char_key);
                        if (is_struct(_persistent_stats_target)) {
                            show_debug_message("       -> Saving stats to global map for '" + _char_key + "'");
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
                             show_debug_message("         -> Saved HP: " + string(_persistent_stats_target.hp) + ", Level: " + string(_persistent_stats_target.level) + ", XP: " + string(_persistent_stats_target.xp) + "/" + string(_persistent_stats_target.xp_require));
                        } else {
                            show_debug_message("     [ReturnToField] WARNING: Could not find persistent stats struct for " + _char_key + " in map!");
                        }
                    }
                    // --- END FIX ---
                }
            }
        } else { show_debug_message("   WARNING: Cannot update party stats - battle_party list or party_current_stats map missing/invalid!"); }
        // --- End Stat Update ---

        // --- Cleanup DS Lists & Reset Vars ---
        if (variable_global_exists("battle_enemies") && ds_exists(global.battle_enemies, ds_type_list)) { ds_list_destroy(global.battle_enemies); global.battle_enemies = -1;}
        if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) { ds_list_destroy(global.battle_party); global.battle_party = -1; }
        total_xp_from_battle = 0; global.battle_state = undefined; alarm[0] = -1; global.battle_target = 0; global.enemy_turn_index = 0; stored_action_data = undefined; selected_target_id = noone; global.active_party_member_index = 0;

        // --- Go to room ---
        if (variable_global_exists("original_room") && room_exists(global.original_room)) { if (instance_exists(obj_player) && variable_global_exists("return_x") && variable_global_exists("return_y")) { with(obj_player) { x = global.return_x; y = global.return_y; } } room_goto(global.original_room); }
        else { instance_destroy(); exit; }

        instance_destroy(); // Manager destroys self
    break;

    default:
        show_debug_message("   -> Alarm[0] triggered in unhandled state: " + string(global.battle_state) + ". Stopping alarm.");
        alarm[0] = -1;
    break;
} // End Switch
