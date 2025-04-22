/// obj_player :: Step Event
// Handles overworld movement, animation, interaction, and random encounters.

// Exit check
if (room == rm_battle) exit;
if (instance_exists(obj_dialog)) exit;
if (instance_exists(obj_game_manager) && obj_game_manager.game_state == "paused") exit; // Added pause check

// Input Reading
var key_x = keyboard_check(ord("D")) - keyboard_check(ord("A")); var key_y = keyboard_check(ord("S")) - keyboard_check(ord("W"));
var joy_x = gamepad_axis_value(0, gp_axislh); var joy_y = gamepad_axis_value(0, gp_axislv); var deadzone = 0.25;
if (abs(joy_x) < deadzone) joy_x = 0; if (abs(joy_y) < deadzone) joy_y = 0;
var _hor = key_x != 0 ? key_x : sign(joy_x); var _ver = key_y != 0 ? key_y : sign(joy_y);

// Move & Collide
move_and_collide( _hor * move_speed, _ver * move_speed, tilemap, undefined, undefined, undefined, move_speed, move_speed );

// Animation Swap
if (_hor != 0 || _ver != 0) { if (_ver > 0) sprite_index = spr_player_walk_down; else if (_ver < 0) sprite_index = spr_player_walk_up; else if (_hor > 0) sprite_index = spr_player_walk_right; else if (_hor < 0) sprite_index = spr_player_walk_left; } else { if (sprite_index == spr_player_walk_right) sprite_index = spr_player_idle_right; if (sprite_index == spr_player_walk_left) sprite_index = spr_player_idle_left; if (sprite_index == spr_player_walk_up) sprite_index = spr_player_idle_up; if (sprite_index == spr_player_walk_down) sprite_index = spr_player_idle_down; }

// Interaction Check
var _interact_target = instance_place(x, y, obj_npc_parent);
if (instance_exists(_interact_target)) { if (_interact_target.can_talk) { var _pressed_interact = keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(0, gp_face1); if (_pressed_interact) { with (_interact_target) { event_perform(ev_other, ev_user0); }}}}

// Encounter Timer Init & Increment
if (!variable_global_exists("encounter_timer") || !is_real(global.encounter_timer)) { global.encounter_timer = 0; }
if (_hor != 0 || _ver != 0) { if (is_real(global.encounter_timer)) { global.encounter_timer += 1; } else { global.encounter_timer = 1; }} // Increment if moving

// Random Encounter Check
var encounter_check_threshold = 120; var encounter_chance = 50; // Using higher test rate
if (is_real(global.encounter_timer) && global.encounter_timer >= encounter_check_threshold) {
    var roll = irandom_range(1, 100);
    if (roll <= encounter_chance) {
        global.encounter_timer = 0;
        var _room_name = room_get_name(room);
        show_debug_message("Checking encounter table for room: " + _room_name + " (ID: " + string(room) + ")");
        if (variable_global_exists("encounter_table") && ds_exists(global.encounter_table, ds_type_map)) {
            var formation_list = ds_map_find_value(global.encounter_table, room); // Use current room ID
            if (ds_exists(formation_list, ds_type_list) && !ds_list_empty(formation_list)) {
                var formation_index = irandom(ds_list_size(formation_list) - 1);
                global.battle_formation = ds_list_find_value(formation_list, formation_index); // Get the array
                if (is_array(global.battle_formation)) {
                     // --- ADDED LOG HERE ---
                     show_debug_message("   Picked formation array: " + string(global.battle_formation) + " | Transitioning to battle...");
                     // --- END ADDED LOG ---
                     global.original_room = room; global.return_x = x; global.return_y = y;
                     global.battle_end_triggered = false; global.battle_state = "player_input";
                     if (room_exists(rm_battle)) { room_goto(rm_battle); exit; }
                     else { show_debug_message("ERROR: Battle room rm_battle missing!");}
                } else { show_debug_message("ERROR: Picked formation is not an array!"); }
            } else { show_debug_message("WARNING: No valid formation list found for room " + _room_name); }
        } else { show_debug_message("ERROR: global.encounter_table missing or not a map!"); }
    } else { global.encounter_timer = 0; } // Reset timer on failed roll
}