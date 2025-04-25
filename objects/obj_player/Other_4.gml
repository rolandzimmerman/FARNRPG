/// obj_player :: Step Event
// Handles overworld movement, animation, interaction, room transitions, and random encounters.

// Exit check
if (room == rm_battle) exit;
if (instance_exists(obj_dialog)) exit;
if (instance_exists(obj_game_manager) && obj_game_manager.game_state == "paused") {
    show_debug_message("Player Step: Exiting due to paused state."); // <-- DEBUG LINE: See if player step stops when paused
    exit; // <-- Exit the step event here if paused
}


// Input Reading
var key_x = keyboard_check(ord("D")) - keyboard_check(ord("A"));
var key_y = keyboard_check(ord("S")) - keyboard_check(ord("W"));
var joy_x = gamepad_axis_value(0, gp_axislh);
var joy_y = gamepad_axis_value(0, gp_axislv);
var deadzone = 0.25;
if (abs(joy_x) < deadzone) joy_x = 0;
if (abs(joy_y) < deadzone) joy_y = 0;
var _hor = key_x != 0 ? key_x : sign(joy_x);
var _ver = key_y != 0 ? key_y : sign(joy_y);


// --- Logging Before Movement (Keep these if they are useful for you, but they aren't directly related to the menu issue) ---
if ((_hor != 0 || _ver != 0) && instance_exists(id)) {
     if (variable_instance_exists(id, "tilemap")) {
          // --- CORRECTED CHECK: Only check for -1 ---
          if (tilemap == -1) {
               show_debug_message("    WARNING: 'tilemap' variable is -1 (invalid) before move_and_collide!");
          } else {
               // Optional: Log the valid ID being used
               // show_debug_message("Player Step: Attempting move_and_collide using tilemap ID: " + string(tilemap));
          }
          // --- END CORRECTED CHECK ---
     } else {
          show_debug_message("    ERROR: 'tilemap' variable does not exist on obj_player instance!");
     }
}

// Move & Collide
// Also check ID is valid before using it
if (variable_instance_exists(id, "tilemap") && tilemap != -1 && is_real(tilemap)) {
    move_and_collide( _hor * move_speed, _ver * move_speed, tilemap, undefined, undefined, undefined, move_speed, move_speed );
} else {
    // Fallback movement if tilemap missing/invalid
    x += _hor * move_speed;
    y += _ver * move_speed;
}


// Animation Swap
if (_hor != 0 || _ver != 0) {
    if (_ver > 0) sprite_index = spr_player_walk_down;
    else if (_ver < 0) sprite_index = spr_player_walk_up;
    else if (_hor > 0) sprite_index = spr_player_walk_right;
    else if (_hor < 0) sprite_index = spr_player_walk_left;
} else {
    if (sprite_index == spr_player_walk_right) sprite_index = spr_player_idle_right;
    if (sprite_index == spr_player_walk_left) sprite_index = spr_player_idle_left;
    if (sprite_index == spr_player_walk_up) sprite_index = spr_player_idle_up;
    if (sprite_index == spr_player_walk_down) sprite_index = spr_player_idle_down;
}

// === Room Transition Check ===
var _exit_margin = 4;
var _room_w = room_width;
var _room_h = room_height;
var _exit_direction = "none";
var _destination_room = noone;

if (x <= _exit_margin) _exit_direction = "left";
else if (x >= _room_w - _exit_margin) _exit_direction = "right";
else if (y <= _exit_margin) _exit_direction = "above";
else if (y >= _room_h - _exit_margin) _exit_direction = "below";

if (_exit_direction != "none") {
    if (variable_global_exists("room_map") && ds_exists(global.room_map, ds_type_map)) {
        var _current_room_connections = ds_map_find_value(global.room_map, room);
        if (ds_exists(_current_room_connections, ds_type_map)) {
            _destination_room = ds_map_find_value(_current_room_connections, _exit_direction);
            if (!is_undefined(_destination_room) && room_exists(_destination_room)) {
                global.entry_direction = _exit_direction;
                room_goto(_destination_room);
                exit; // Exit step after room transition
            } else {
                 // Prevent player from getting stuck if no valid exit
                 if (_exit_direction == "left") x = _exit_margin + 1;
                 if (_exit_direction == "right") x = _room_w - _exit_margin - 1;
                 if (_exit_direction == "above") y = _exit_margin + 1;
                 if (_exit_direction == "below") y = _room_h - _exit_margin - 1;
            }
        }
    }
}
// === End Room Transition Check ===


// Interaction Check
var _interact_target = instance_place(x, y, obj_npc_parent);
if (instance_exists(_interact_target)) {
    if (_interact_target.can_talk) {
        var _pressed_interact = keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(0, gp_face1);
        if (_pressed_interact) {
            with (_interact_target) {
                event_perform(ev_other, ev_user0); // Trigger NPC's interaction event
            }
        }
    }
}

// Encounter Timer Init & Increment
if (!variable_global_exists("encounter_timer") || !is_real(global.encounter_timer)) {
    global.encounter_timer = 0;
}
if (_hor != 0 || _ver != 0) {
    if (is_real(global.encounter_timer)) {
        global.encounter_timer += 1;
    } else {
        global.encounter_timer = 1; // Reset if somehow not real
    }
}

// Random Encounter Check
var encounter_check_threshold = 120;
var encounter_chance = 50; // Percentage chance per check

if (is_real(global.encounter_timer) && global.encounter_timer >= encounter_check_threshold) {
    var roll = irandom_range(1, 100);
    if (roll <= encounter_chance) {
        global.encounter_timer = 0; // Reset timer after a check
        if (variable_global_exists("encounter_table") && ds_exists(global.encounter_table, ds_type_map)) {
            var formation_list = ds_map_find_value(global.encounter_table, room);
            if (ds_exists(formation_list, ds_type_list) && !ds_list_empty(formation_list)) {
                var formation_index = irandom(ds_list_size(formation_list) - 1);
                global.battle_formation = ds_list_find_value(formation_list, formation_index);

                // Ensure the retrieved formation is valid before starting battle
                if (is_array(global.battle_formation)) {
                     global.original_room = room;
                     global.return_x = x;
                     global.return_y = y;
                     global.battle_end_triggered = false; // Flag to manage battle end
                     global.battle_state = "player_input"; // Initial battle state

                     if (room_exists(rm_battle)) {
                         room_goto(rm_battle);
                         exit; // Exit step after starting battle
                     } else {
                          show_debug_message("ERROR: Battle room 'rm_battle' does not exist!");
                          // Handle gracefully, maybe reset timer or show message
                     }
                } else {
                     show_debug_message("WARNING: Encounter found but formation data is invalid for room " + room_get_name(room));
                     // Reset timer or handle appropriately if formation data is bad
                }
            } else {
                 // No formations for this room, just reset timer
                 show_debug_message("No encounter formations defined for room " + room_get_name(room));
            }
        } else {
             show_debug_message("ERROR: Global encounter_table not initialized or invalid!");
             // Reset timer or handle appropriately if encounter table is missing
        }
    } else {
        global.encounter_timer = 0; // Reset timer even if roll fails
    }
}