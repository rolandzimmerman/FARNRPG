// obj_game_manager :: Room Start Event
show_debug_message("Game Manager: Room Start Event for room: " + room_get_name(room));

// Attempt to find the player instance early on
var _player = instance_find(obj_player, 0); // Use instance_find to handle potential non-existence

// --- Check if we just loaded and need to apply data ---
// The load logic takes priority for positioning the player
if (variable_instance_exists(id, "load_pending") && load_pending && variable_instance_exists(id, "loaded_data") && is_struct(loaded_data)) {
    show_debug_message(" > Applying loaded data (Load Pending is TRUE)...");

    // --- Apply Player Data (Including Position) ---
    if (instance_exists(_player)) { // Check if player exists before applying data
        if (variable_struct_exists(loaded_data, "player_data")) {
            var _p_data = loaded_data.player_data;
            // Position from save data takes precedence
            if (variable_struct_exists(_p_data, "x")) { _player.x = _p_data.x; }
            if (variable_struct_exists(_p_data, "y")) { _player.y = _p_data.y; }
            // Apply other stats...
            if (variable_struct_exists(_p_data, "hp")) { _player.hp = _p_data.hp; }
            if (variable_struct_exists(_p_data, "mp")) { _player.mp = _p_data.mp; }
            if (variable_struct_exists(_p_data, "hp_total")) { _player.hp_total = _p_data.hp_total; }
            if (variable_struct_exists(_p_data, "mp_total")) { _player.mp_total = _p_data.mp_total; }
            if (variable_struct_exists(_p_data, "atk")) { _player.atk = _p_data.atk; }
            if (variable_struct_exists(_p_data, "def")) { _player.def = _p_data.def; }
            if (variable_struct_exists(_p_data, "level")) { _player.level = _p_data.level; }
            if (variable_struct_exists(_p_data, "xp")) { _player.xp = _p_data.xp; }
            if (variable_struct_exists(_p_data, "xp_require")) { _player.xp_require = _p_data.xp_require; }
            show_debug_message(" >> Player data applied (including position from save).");
        } else { show_debug_message(" >> WARNING: No player_data struct found in loaded data."); }
    } else { show_debug_message(" >> WARNING: Player instance not found in room after load to apply data."); }

    // --- Apply Global Data ---
    if (variable_struct_exists(loaded_data, "global_data")) {
        var _g_data = loaded_data.global_data;
        // Apply globals... (Add your specific global variable loading here if needed)
        show_debug_message(" >> Global data applied.");
    } else { show_debug_message(" >> WARNING: No global_data struct found in loaded data."); }

    // --- Apply NPC Data ---
    if (variable_struct_exists(loaded_data, "npc_states")) {
        var _npc_states_loaded = loaded_data.npc_states;
        var _npc_state_keys = variable_struct_get_names(_npc_states_loaded);
        show_debug_message(" >> Applying saved NPC states (" + string(array_length(_npc_state_keys)) + " entries)...");
        // Using 'obj_npc_parent' assumes all NPCs inherit from it and have unique_npc_id
        with (obj_npc_parent) {
            if (variable_instance_exists(id, "unique_npc_id")) {
                var _id_string = unique_npc_id;
                // Use struct accessor $ for safety with potentially non-standard keys
                if (variable_struct_exists(_npc_states_loaded, _id_string)) {
                    var _saved_state = _npc_states_loaded[$ _id_string];
                    // Apply specific saved states
                    if (variable_struct_exists(_saved_state, "has_spoken_to")) { has_spoken_to = _saved_state.has_spoken_to; }
                    // Add other NPC state variables here...
                }
            }
        }
    } else { show_debug_message(" >> No 'npc_states' struct found in loaded data."); }

    // --- Clean up Load Flags ---
    show_debug_message(" > Finished applying loaded data.");
    load_pending = false;
    loaded_data = undefined;
    // Also clear entry direction if we loaded, as saved position overrides it
    if (variable_global_exists("entry_direction")) {
        global.entry_direction = "none";
    }

}
// --- ELSE: Handle Normal Room Entry Spawn Logic (Not Loading) ---
else {
    show_debug_message(" > Handling normal room entry spawn (Load Pending is FALSE)...");

    // Check if player instance exists (might be persistent or created by room)
    if (!instance_exists(_player)) {
        show_debug_message(" >> WARNING: Player instance not found at start of normal spawn logic!");
        // If player should be created here if missing (and not persistent), add:
        // _player = instance_create_layer(0, 0, "Instances", obj_player); // Create at temporary spot
        // show_debug_message(" >> Created player instance: " + string(_player));
    }

    // Proceed only if player instance is valid
    if (instance_exists(_player)) {
        var _entry_dir = variable_global_exists("entry_direction") ? global.entry_direction : "none";
        var _target_spawn_id = "default"; // Default spawn ID

        show_debug_message(" >> Entry direction from previous room was: '" + _entry_dir + "'");

        // Determine the required spawn ID based on the direction the player EXITED the previous room
        switch (_entry_dir) {
            case "left":  _target_spawn_id = "entry_from_left"; break;  // Exited Left -> Arrive on Right edge -> Use "entry_from_left" marker
            case "right": _target_spawn_id = "entry_from_right"; break; // Exited Right -> Arrive on Left edge -> Use "entry_from_right" marker
            case "above": _target_spawn_id = "entry_from_above"; break; // Exited Top -> Arrive on Bottom edge -> Use "entry_from_above" marker
            case "below": _target_spawn_id = "entry_from_below"; break; // Exited Bottom -> Arrive on Top edge -> Use "entry_from_below" marker
            case "none":  // Fallthrough (Game Start, potentially returning from battle where direction wasn't set)
            default:
                _target_spawn_id = "default";
                show_debug_message(" >> No valid entry direction or game start, using default spawn ID.");
            break;
        }
        show_debug_message(" >> Required spawn ID in this room: '" + _target_spawn_id + "'");

        // --- Find Spawn Marker Instance ---
        var _spawn_inst = noone;
        // Ensure the spawn point object actually exists before searching
        if (object_exists(obj_spawn_point)) {
            var _instance_count = instance_number(obj_spawn_point);
            show_debug_message(" >> Searching for spawn point with ID: '" + _target_spawn_id + "' among " + string(_instance_count) + " obj_spawn_point instances.");

            // --- Initial search loop ---
            for (var i = 0; i < _instance_count; i++;) {
                var _inst = instance_find(obj_spawn_point, i);
                 // Add extra safety check
                 if (!instance_exists(_inst)) {
                      show_debug_message(" ---> Warning: instance_find returned invalid instance at index " + string(i) + " in initial search.");
                      continue; // Skip to next iteration
                 }

                // Safely get the spawn_id variable (Older GMS Compatible)
                var _inst_spawn_id = "no_id_found";
                if (variable_instance_exists(_inst, "spawn_id")) {
                    _inst_spawn_id = _inst.spawn_id;
                }

                show_debug_message(" ---> Checking instance " + string(_inst) + ", found spawn_id: '" + _inst_spawn_id + "'");

                // Check the retrieved ID
                if (_inst_spawn_id == _target_spawn_id) {
                    _spawn_inst = _inst;
                    show_debug_message(" ---> Found matching instance: " + string(_spawn_inst));
                    break; // Exit loop once found
                }
            } // --- End initial search loop ---

            // --- Fallback logic (if specific ID wasn't found) ---
            if (_spawn_inst == noone && _target_spawn_id != "default") { // Only fallback if we weren't already looking for default
                show_debug_message(" ---> Specific spawn ID '" + _target_spawn_id + "' not found. Trying fallback 'default'...");
                var _fallback_target_id = "default"; // Use a different variable name for clarity inside fallback search
                // --- Fallback search loop ---
                for (var i = 0; i < _instance_count; i++;) {
                     var _inst = instance_find(obj_spawn_point, i);
                     // Add extra safety check
                     if (!instance_exists(_inst)) {
                          show_debug_message(" ---> Warning: instance_find returned invalid instance at index " + string(i) + " in fallback search.");
                          continue; // Skip to next iteration
                     }

                     // Safely get the spawn_id variable (Older GMS Compatible) - FIXED HERE previously
                     var _inst_spawn_id = "no_id_found"; // Default value
                     if (variable_instance_exists(_inst, "spawn_id")) {
                         _inst_spawn_id = _inst.spawn_id; // Get value if variable exists
                     }

                     show_debug_message(" ---> Fallback checking instance " + string(_inst) + ", found spawn_id: '" + _inst_spawn_id + "'");

                     if (_inst_spawn_id == _fallback_target_id) { // Looking for "default"
                         _spawn_inst = _inst;
                         show_debug_message(" ---> Found fallback 'default' instance: " + string(_spawn_inst));
                         break; // Exit fallback loop
                     }
                 } // --- End fallback search loop ---
            } // --- End 'if (_spawn_inst == noone && _target_spawn_id != "default")' ---

            // --- Last resort fallback (if still noone, including if default failed) ---
             if (_spawn_inst == noone && _instance_count > 0) {
                 _spawn_inst = instance_find(obj_spawn_point, 0); // Grab the very first one found
                  // Ensure the fallback instance is valid before logging/using
                  if (instance_exists(_spawn_inst)){
                     show_debug_message(" ---> Using first available spawn point instance as final fallback: " + string(_spawn_inst));
                  } else {
                     _spawn_inst = noone; // Ensure it's noone if find failed
                      show_debug_message(" ---> CRITICAL: Could not find *any* valid spawn point instances.");
                  }
             }
             // --- End Fallback Logic ---

        } else {
             show_debug_message(" >> WARNING: obj_spawn_point object does not exist! Cannot find spawn points.");
        } // --- End 'if (object_exists(obj_spawn_point))' ---


        // --- Position Player ---
        if (_spawn_inst != noone) {
            // Ensure player still exists before positioning (e.g., wasn't destroyed by another script)
            if (instance_exists(_player)) {
                 _player.x = _spawn_inst.x;
                 _player.y = _spawn_inst.y;
                 // *** FIXED Log message below - removed the problematic function call ***
                 show_debug_message(" >> Player positioned at spawn point instance " + string(_spawn_inst) + " (" + string(_player.x) + ", " + string(_player.y) + ")");
            } else {
                 show_debug_message(" >> WARNING: Player instance destroyed before positioning could occur!");
            }
        } else {
            // Only log warning if player actually exists but couldn't be positioned
            if (instance_exists(_player)) {
                 show_debug_message(" >> WARNING: No valid spawn point instance found! Player position may be incorrect.");
                 // Optional: Move player to center as an absolute fallback?
                 // _player.x = room_width / 2;
                 // _player.y = room_height / 2;
            } else {
                 show_debug_message(" >> WARNING: Player instance not found and no valid spawn point instance found!");
            }
        }

        // --- Reset entry direction after use ---
        if (variable_global_exists("entry_direction")) {
            global.entry_direction = "none"; // Reset for next transition
        }

    } else { // --- End 'if (instance_exists(_player))' ---
        show_debug_message(" >> CRITICAL WARNING: Player instance is invalid, cannot execute spawn positioning!");
    }

} // --- End else (not loading) ---


// --- Any other Room Start logic ---
show_debug_message("Game Manager: End of Room Start Event.");