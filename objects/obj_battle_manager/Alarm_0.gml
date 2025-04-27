/// obj_battle_manager :: Alarm[0]
/// Handles timed transitions, victory/defeat processing, saving persistent stats individually, and cleaning up status map.

show_debug_message("⏰ BattleManager Alarm[0] Triggered — Current State: " + string(global.battle_state) + " !!!");

switch (global.battle_state) {

    case "waiting_next_enemy": case "waiting_enemy": show_debug_message("   -> Alarm setting state to enemy_turn"); global.battle_state = "enemy_turn"; break;
    case "victory": { /* XP Award, Dialogue */ global.battle_state = "return_to_field"; alarm[0] = 120; } break;
    case "defeat": { /* Dialogue */ global.battle_state = "return_to_field"; alarm[0] = 120; } break;

    case "return_to_field":
        show_debug_message("    Alarm 0: Returning to field map.");
        show_debug_message("    Updating persistent party stats (HP,MP,Level,XP,XP_Req)...");
        if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list) && variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) {
            var _battle_party_size = ds_list_size(global.battle_party);
            for (var i = 0; i < _battle_party_size; i++) {
                var _b_inst = global.battle_party[| i];
                if (instance_exists(_b_inst) && variable_instance_exists(_b_inst, "data") && is_struct(_b_inst.data)) {
                    var _b_data = _b_inst.data; var _char_key = variable_struct_exists(_b_data, "character_key") ? _b_data.character_key : undefined;
                    if (is_string(_char_key)) {
                        var _persistent_stats_target = ds_map_find_value(global.party_current_stats, _char_key);
                        if (is_struct(_persistent_stats_target)) {
                            show_debug_message("        -> Saving stats TO global map for '" + _char_key + "'"); show_debug_message("          -> MAP BEFORE Save: Lvl=" + string(_persistent_stats_target.level ?? "N/A") + ", XP=" + string(_persistent_stats_target.xp ?? "N/A"));
                            // <<< CORRECTED SAVE LOGIC: Update individual fields >>>
                            _persistent_stats_target.hp = max(1, _b_data.hp);
                            _persistent_stats_target.mp = _b_data.mp;
                            _persistent_stats_target.level = _b_data.level;
                            _persistent_stats_target.xp = _b_data.xp;
                            _persistent_stats_target.xp_require = _b_data.xp_require;
                            // Verify Save
                            var _verify_struct = ds_map_find_value(global.party_current_stats, _char_key); if (is_struct(_verify_struct)) { show_debug_message("          -> MAP AFTER Save: Lvl=" + string(_verify_struct.level ?? "N/A") + ", XP=" + string(_verify_struct.xp ?? "N/A") + ", HP=" + string(_verify_struct.hp ?? "N/A")); }
                        }
                    }
                }
            } // End for loop
        }
        // --- Cleanup & Return ---
        if (variable_global_exists("battle_enemies") && ds_exists(global.battle_enemies, ds_type_list)) { ds_list_destroy(global.battle_enemies); global.battle_enemies = -1;}
        if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) { ds_list_destroy(global.battle_party); global.battle_party = -1; }
        if (variable_global_exists("battle_status_effects") && ds_exists(global.battle_status_effects, ds_type_map)) { ds_map_destroy(global.battle_status_effects); global.battle_status_effects = -1; }
        total_xp_from_battle = 0; global.battle_state = undefined; alarm[0] = -1; /* Reset other globals */
        if (variable_global_exists("original_room") && room_exists(global.original_room)) { if (instance_exists(obj_player)) { /* Position player */ } instance_activate_all(); room_goto(global.original_room); } else { instance_destroy(); exit; }
        instance_destroy();
        break;

    default: alarm[0] = -1; break;
} // End Switch