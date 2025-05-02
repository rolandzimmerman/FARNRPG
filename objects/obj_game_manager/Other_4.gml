/// obj_game_manager :: Room Start Event

show_debug_message("Game Manager: Room Start Event for room: " + room_get_name(room));

var _player = instance_find(obj_player, 0);

// ========================
// === Load From Save ===
// ========================
if (variable_instance_exists(id, "load_pending") && load_pending && variable_instance_exists(id, "loaded_data") && is_struct(loaded_data)) {
    show_debug_message(" > Applying loaded data (Load Pending is TRUE)...");

    if (instance_exists(_player)) {
        if (variable_struct_exists(loaded_data, "player_data")) {
            var _p_data = loaded_data.player_data;
            if (variable_struct_exists(_p_data, "x")) _player.x = _p_data.x;
            if (variable_struct_exists(_p_data, "y")) _player.y = _p_data.y;
            if (variable_struct_exists(_p_data, "hp")) _player.hp = _p_data.hp;
            if (variable_struct_exists(_p_data, "mp")) _player.mp = _p_data.mp;
            if (variable_struct_exists(_p_data, "level")) _player.level = _p_data.level;
            if (variable_struct_exists(_p_data, "xp")) _player.xp = _p_data.xp;
            if (variable_struct_exists(_p_data, "xp_require")) _player.xp_require = _p_data.xp_require;
        }
    }

    if (variable_struct_exists(loaded_data, "global_data")) {
        var _g_data = loaded_data.global_data;
    }

    if (variable_struct_exists(loaded_data, "npc_states")) {
        var _npc_states = loaded_data.npc_states;
        with (obj_npc_parent) {
            if (variable_instance_exists(id, "unique_npc_id")) {
                var _id_string = unique_npc_id;
                if (variable_struct_exists(_npc_states, _id_string)) {
                    var _state = _npc_states[$ _id_string];
                    if (variable_struct_exists(_state, "has_spoken_to")) has_spoken_to = _state.has_spoken_to;
                }
            }
        }
    }

    load_pending = false;
    loaded_data = undefined;

    if (variable_global_exists("entry_direction")) global.entry_direction = "none";
}

// =================================
// === Battle Return Handling ===
// =================================
else if (variable_global_exists("original_room") && room == global.original_room && variable_global_exists("return_x") && variable_global_exists("return_y")) {
    if (instance_exists(_player)) {
        _player.x = global.return_x;
        _player.y = global.return_y;
        show_debug_message(" -> Player returned from battle. Set position to return_x, return_y.");
    } else {
        show_debug_message(" -> WARNING: Return from battle but player not found.");
    }

    // Clear once used
    global.original_room = undefined;
    global.return_x = undefined;
    global.return_y = undefined;
}

// =====================================
// === Standard Entry Spawn (Start) ===
// =====================================
else {
    show_debug_message(" > Handling normal room entry spawn (Load Pending is FALSE)...");

    if (!instance_exists(_player)) {
        show_debug_message(" >> WARNING: Player instance not found at start of normal spawn logic!");
    }

    if (instance_exists(_player)) {
        var _entry_dir = (variable_global_exists("entry_direction")) ? global.entry_direction : "none";
        var _target_spawn_id = "default";

        switch (_entry_dir) {
            case "left":  _target_spawn_id = "entry_from_left"; break;
            case "right": _target_spawn_id = "entry_from_right"; break;
            case "above": _target_spawn_id = "entry_from_above"; break;
            case "below": _target_spawn_id = "entry_from_below"; break;
            default: _target_spawn_id = "default"; break;
        }

        var _spawn = noone;
        if (object_exists(obj_spawn_point)) {
            var _count = instance_number(obj_spawn_point);
            for (var i = 0; i < _count; i++) {
                var inst = instance_find(obj_spawn_point, i);
                if (instance_exists(inst) && inst.spawn_id == _target_spawn_id) {
                    _spawn = inst;
                    break;
                }
            }

            if (_spawn == noone && _target_spawn_id != "default") {
                for (var i = 0; i < _count; i++) {
                    var inst = instance_find(obj_spawn_point, i);
                    if (instance_exists(inst) && inst.spawn_id == "default") {
                        _spawn = inst;
                        break;
                    }
                }
            }

            if (_spawn == noone && _count > 0) {
                _spawn = instance_find(obj_spawn_point, 0);
            }
        }

        if (_spawn != noone) {
            _player.x = _spawn.x;
            _player.y = _spawn.y;
            show_debug_message(" >> Positioned player using spawn point: " + string(_spawn));
        } else {
            show_debug_message(" >> WARNING: No valid spawn point found for entry.");
        }

        global.entry_direction = "none";
    }
}

show_debug_message("Game Manager: End of Room Start Event.");
