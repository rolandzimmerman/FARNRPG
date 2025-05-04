/// obj_player :: Step Event

// Get reference to the game manager
var _gm = instance_exists(obj_game_manager) ? obj_game_manager : noone;

// Abort if game manager missing or paused
if (_gm == noone || _gm.game_state != "playing") exit;
if (room == rm_battle) exit;
if (instance_exists(obj_dialog)) exit;

// --- Pause Handling ---
var pause_input = keyboard_check_pressed(vk_escape) || gamepad_button_check_pressed(0, gp_start);
if (pause_input && !instance_exists(obj_pause_menu)) {
    _gm.game_state = "paused";

    var pause_layer = layer_get_id("Instances_GUI");
    if (pause_layer == -1) pause_layer = layer_get_id("Instances");

    var menu = instance_create_layer(0, 0, pause_layer, obj_pause_menu);

    instance_deactivate_object(id);
    instance_deactivate_object(obj_npc_parent);
    instance_activate_object(menu);
    instance_activate_object(obj_game_manager);
    exit;
}

// --- Movement Input ---
var key_x = keyboard_check(ord("D")) - keyboard_check(ord("A"));
var key_y = keyboard_check(ord("S")) - keyboard_check(ord("W"));
var joy_x = gamepad_axis_value(0, gp_axislh);
var joy_y = gamepad_axis_value(0, gp_axislv);
if (abs(joy_x) < 0.25) joy_x = 0;
if (abs(joy_y) < 0.25) joy_y = 0;

var dir_x = (key_x != 0) ? key_x : sign(joy_x);
var dir_y = (key_y != 0) ? key_y : sign(joy_y);

// Movement
if (variable_instance_exists(id, "tilemap") && tilemap != -1) {
    move_and_collide(dir_x * move_speed, dir_y * move_speed, tilemap);
} else {
    x += dir_x * move_speed;
    y += dir_y * move_speed;
}

// --- Animation ---
if (dir_x != 0 || dir_y != 0) {
    if (dir_y > 0)       sprite_index = spr_player_walk_down;
    else if (dir_y < 0)  sprite_index = spr_player_walk_up;
    else if (dir_x > 0)  sprite_index = spr_player_walk_right;
    else if (dir_x < 0)  sprite_index = spr_player_walk_left;
    image_speed = 1;
} else {
    if (sprite_index == spr_player_walk_down)   sprite_index = spr_player_idle_down;
    else if (sprite_index == spr_player_walk_up) sprite_index = spr_player_idle_up;
    else if (sprite_index == spr_player_walk_left) sprite_index = spr_player_idle_left;
    else if (sprite_index == spr_player_walk_right) sprite_index = spr_player_idle_right;
    image_speed = 0;
    image_index = 0;
}

// --- Room Transitions ---
var exit_margin = 4;
var exit_dir = "none";
if (x <= exit_margin) exit_dir = "left";
else if (x >= room_width - exit_margin) exit_dir = "right";
else if (y <= exit_margin) exit_dir = "above";
else if (y >= room_height - exit_margin) exit_dir = "below";

if (exit_dir != "none") {
    if (variable_global_exists("room_map") && ds_exists(global.room_map, ds_type_map)) {
        var conn_map = ds_map_find_value(global.room_map, room);
        if (ds_exists(conn_map, ds_type_map) && ds_map_exists(conn_map, exit_dir)) {
            var dest = ds_map_find_value(conn_map, exit_dir);
            if (room_exists(dest)) {
                global.entry_direction = exit_dir;
                global.return_x = x;
                global.return_y = y;
                room_goto(dest);
                exit;
            }
        }
    }
    if (exit_dir == "left")   x = exit_margin + 1;
    if (exit_dir == "right")  x = room_width - exit_margin - 1;
    if (exit_dir == "above")  y = exit_margin + 1;
    if (exit_dir == "below")  y = room_height - exit_margin - 1;
}

// --- Random Encounter ---
if (!variable_global_exists("encounter_timer")) global.encounter_timer = 0;
if (dir_x != 0 || dir_y != 0) global.encounter_timer++;

var threshold = 100;
var chance = 25;

if (global.encounter_timer >= threshold) {
    global.encounter_timer = 0;

    if (random(100) < chance) {
        if (variable_global_exists("encounter_table") && ds_exists(global.encounter_table, ds_type_map)) {
            audio_play_sound(snd_sfx_encounter, 1, 0);
            var list = ds_map_find_value(global.encounter_table, room);
            if (ds_exists(list, ds_type_list) && !ds_list_empty(list)) {
                var index = irandom(ds_list_size(list) - 1);
                var formation = ds_list_find_value(list, index);

                if (is_array(formation)) {
                    global.battle_formation = formation;
                    global.original_room = room;
                    global.return_x = x;
                    global.return_y = y;
                    room_goto(rm_battle);
                    exit;
                }
            }
        }
    }
}

// --- Interaction ---
var interact = keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(0, gp_face1);
var npc = instance_place(x, y, obj_npc_parent);

if (instance_exists(npc) && variable_instance_exists(npc, "can_talk") && npc.can_talk && interact) {
    with (npc) event_perform(ev_other, ev_user0);
}
