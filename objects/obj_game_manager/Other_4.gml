/// obj_game_manager :: Room Start Event
// Handles applying loaded data after a room change triggered by scr_load_game.

show_debug_message("Game Manager: Room Start Event for room: " + room_get_name(room));

// --- UI Layer Initialization REMOVED ---


// --- Check if we just loaded and need to apply data ---
if (variable_instance_exists(id, "load_pending") && load_pending && variable_instance_exists(id, "loaded_data") && is_struct(loaded_data)) {
    show_debug_message(" > Applying loaded data...");

    // --- Apply Player Data ---
    var _player = instance_find(obj_player, 0);
    if (instance_exists(_player)) {
        if (variable_struct_exists(loaded_data, "player_data")) {
            var _p_data = loaded_data.player_data;
            if (variable_struct_exists(_p_data, "x")) { _player.x = _p_data.x; }
            if (variable_struct_exists(_p_data, "y")) { _player.y = _p_data.y; }
            if (variable_struct_exists(_p_data, "hp")) { _player.hp = _p_data.hp; }
            if (variable_struct_exists(_p_data, "mp")) { _player.mp = _p_data.mp; }
            if (variable_struct_exists(_p_data, "hp_total")) { _player.hp_total = _p_data.hp_total; }
            if (variable_struct_exists(_p_data, "mp_total")) { _player.mp_total = _p_data.mp_total; }
            if (variable_struct_exists(_p_data, "atk")) { _player.atk = _p_data.atk; }
            if (variable_struct_exists(_p_data, "def")) { _player.def = _p_data.def; }
            if (variable_struct_exists(_p_data, "level")) { _player.level = _p_data.level; }
            if (variable_struct_exists(_p_data, "xp")) { _player.xp = _p_data.xp; }
            if (variable_struct_exists(_p_data, "xp_require")) { _player.xp_require = _p_data.xp_require; }
            show_debug_message(" >> Player data applied.");
        } else { show_debug_message(" >> WARNING: No player_data struct found in loaded data."); }
    } else { show_debug_message(" >> WARNING: Player instance not found in room after load to apply data."); }

    // --- Apply Global Data ---
    if (variable_struct_exists(loaded_data, "global_data")) {
         var _g_data = loaded_data.global_data;
         // Apply globals...
         show_debug_message(" >> Global data applied.");
    } else { show_debug_message(" >> WARNING: No global_data struct found in loaded data."); }

    // --- Apply NPC Data ---
    if (variable_struct_exists(loaded_data, "npc_states")) {
        var _npc_states_loaded = loaded_data.npc_states;
        var _npc_state_keys = variable_struct_get_names(_npc_states_loaded);
        show_debug_message(" >> Applying saved NPC states (" + string(array_length(_npc_state_keys)) + " entries)...");
        with (obj_npc_parent) {
            if (variable_instance_exists(id, "unique_npc_id")) {
                var _id_string = unique_npc_id;
                if (variable_struct_exists(_npc_states_loaded, _id_string)) {
                    var _saved_state = _npc_states_loaded[$ _id_string];
                    if (variable_struct_exists(_saved_state, "has_spoken_to")) { has_spoken_to = _saved_state.has_spoken_to; }
                }
            }
        }
    } else { show_debug_message(" >> No 'npc_states' struct found in loaded data."); }

    // --- Clean up ---
    show_debug_message(" > Finished applying loaded data.");
    load_pending = false;
    loaded_data = undefined;

} else if (variable_instance_exists(id, "load_pending") && load_pending) {
    show_debug_message("ERROR: Load was pending, but loaded_data was invalid! Clearing flag.");
    load_pending = false;
    loaded_data = undefined;
}

// --- Any other Room Start logic ---
