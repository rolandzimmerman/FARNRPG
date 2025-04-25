/// obj_player :: Step Event
/// Handles overworld movement, animation, interaction, room transitions, random encounters, and PAUSING.

// --- DEBUG LINE: Check if player step is running at the very beginning ---
show_debug_message("Player Step START (Absolute Top Debug)");

// Safely get the game manager instance ID
var _gm = noone;
if (instance_exists(obj_game_manager)) {
    _gm = obj_game_manager;
}

// ONLY proceed with player logic if the game manager exists and is ready
if (_gm != noone && variable_instance_exists(_gm, "game_state")) {

    // --- Safe to access game_state now ---
    show_debug_message("Player Step (After GM check). Instance ID: " + string(id) + " | Game State: " + string(_gm.game_state));

    // Exit immediately if in battle or dialogue
    if (room == rm_battle) exit;
    if (instance_exists(obj_dialog)) exit;

    // Exit if paused
    if (_gm.game_state == "paused") {
        show_debug_message("Player Step: Exiting due to paused state.");
        exit;
    }

    // --- PAUSE INPUT ---
    if (keyboard_check_pressed(vk_escape) || gamepad_button_check_pressed(0, gp_start)) {
        if (_gm.game_state == "playing") {
            _gm.game_state = "paused";
            show_debug_message("Game Paused (via Player)");

            if (!instance_exists(obj_pause_menu)) {
                var _pm = instance_create_layer(0, 0, "Instances", obj_pause_menu);
                instance_deactivate_object(id);
                instance_deactivate_object(obj_npc_parent);
                instance_activate_object(_pm);
            }
            exit;
        }
    }

    // --- MOVEMENT INPUT ---
    var key_x = keyboard_check(ord("D")) - keyboard_check(ord("A"));
    var key_y = keyboard_check(ord("S")) - keyboard_check(ord("W"));
    var joy_x = gamepad_axis_value(0, gp_axislh);
    var joy_y = gamepad_axis_value(0, gp_axislv);
    var deadzone = 0.25;
    if (abs(joy_x) < deadzone) joy_x = 0;
    if (abs(joy_y) < deadzone) joy_y = 0;
    var _hor = key_x != 0 ? key_x : sign(joy_x);
    var _ver = key_y != 0 ? key_y : sign(joy_y);

    // Optional logging
    if ((_hor != 0 || _ver != 0) && variable_instance_exists(id, "tilemap")) {
        if (tilemap == -1) {
            // show_debug_message("WARNING: tilemap is -1 before move_and_collide!");
        }
    }

    // Move & collide
    if (variable_instance_exists(id, "tilemap") && tilemap != -1 && is_real(tilemap)) {
        move_and_collide(_hor * move_speed, _ver * move_speed, tilemap);
    } else {
        x += _hor * move_speed;
        y += _ver * move_speed;
    }

    // Animation
    if (_hor != 0 || _ver != 0) {
        if (_ver > 0)      sprite_index = spr_player_walk_down;
        else if (_ver < 0) sprite_index = spr_player_walk_up;
        else if (_hor > 0) sprite_index = spr_player_walk_right;
        else if (_hor < 0) sprite_index = spr_player_walk_left;
    } else {
        if (sprite_index == spr_player_walk_right) sprite_index = spr_player_idle_right;
        if (sprite_index == spr_player_walk_left)  sprite_index = spr_player_idle_left;
        if (sprite_index == spr_player_walk_up)    sprite_index = spr_player_idle_up;
        if (sprite_index == spr_player_walk_down)  sprite_index = spr_player_idle_down;
    }

    // === Room Transitions ===
    var _exit_margin = 4;
    var _exit_dir = "none";
    if (x <= _exit_margin)                 _exit_dir = "left";
    else if (x >= room_width - _exit_margin)  _exit_dir = "right";
    else if (y <= _exit_margin)             _exit_dir = "above";
    else if (y >= room_height - _exit_margin) _exit_dir = "below";

    if (_exit_dir != "none") {
        if (variable_global_exists("room_map") && ds_exists(global.room_map, ds_type_map)) {
            var conns = ds_map_find_value(global.room_map, room);
            if (ds_exists(conns, ds_type_map)) {
                var dest = ds_map_find_value(conns, _exit_dir);
                if (room_exists(dest)) {
                    global.entry_direction = _exit_dir;
                    room_goto(dest);
                    exit;
                } else {
                    // push back inside bounds
                    if (_exit_dir == "left")      x = _exit_margin + 1;
                    if (_exit_dir == "right")     x = room_width - _exit_margin - 1;
                    if (_exit_dir == "above")     y = _exit_margin + 1;
                    if (_exit_dir == "below")     y = room_height - _exit_margin - 1;
                }
            }
        }
    }

    // --- NPC Interaction ---
    var _npc = instance_place(x, y, obj_npc_parent);
    if (instance_exists(_npc) && _npc.can_talk) {
        if (keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(0, gp_face1)) {
            with (_npc) event_perform(ev_other, ev_user0);
        }
    }

    // --- Random Encounters ---
    if (!variable_global_exists("encounter_timer") || !is_real(global.encounter_timer)) {
        global.encounter_timer = 0;
    }
    if (_hor != 0 || _ver != 0) {
        global.encounter_timer += 1;
    }

    if (global.encounter_timer >= 120) {
        global.encounter_timer = 0;
        if (irandom(99) < 50 && variable_global_exists("encounter_table") && ds_exists(global.encounter_table, ds_type_map)) {
            var list = ds_map_find_value(global.encounter_table, room);
            if (ds_exists(list, ds_type_list) && !ds_list_empty(list)) {
                var idx = irandom(ds_list_size(list) - 1);
                global.battle_formation = ds_list_find_value(list, idx);
                global.original_room   = room;
                global.return_x        = x;
                global.return_y        = y;
                if (room_exists(rm_battle)) {
                    room_goto(rm_battle);
                    exit;
                }
            }
        }
    }

} else {
    // Game manager missing or not ready
    show_debug_message("Player Step: Waiting for Game Manager or correct state.");
}
