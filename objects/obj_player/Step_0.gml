/// obj_player :: Step Event
/// Handles overworld movement, animation, interaction, room transitions, random encounters, and PAUSING.

// --- DEBUG LINE: Check if player step is running at the very beginning ---
// show_debug_message("Player Step START (Absolute Top Debug)");

// Safely get the game manager instance ID
var _gm = instance_exists(obj_game_manager) ? obj_game_manager : noone;

// ONLY proceed with player logic if the game manager exists and is ready
if (_gm != noone && variable_instance_exists(_gm, "game_state")) {

    // --- Safe to access game_state now ---
    // show_debug_message("Player Step (After GM check). Instance ID: " + string(id) + " | Game State: " + string(_gm.game_state));

    // Exit immediately if in battle or dialogue
    // Note: If obj_dialog exists, the player object should generally not run its step event.
    // This can be handled by deactivating the player when dialog starts, or checking here.
    if (room == rm_battle) exit;
    if (instance_exists(obj_dialog)) exit; // Assumes dialog pauses the game or deactivates player

    // Exit step immediately if game state is paused (prevents movement etc.)
    if (_gm.game_state == "paused") {
        // show_debug_message("Player Step: Exiting due to paused state.");
        exit;
    }

    // --- PAUSE INPUT ---
    // Check for pause button press only when the game is 'playing'
    var _pause_pressed = (keyboard_check_pressed(vk_escape) || gamepad_button_check_pressed(0, gp_start));

    if (_pause_pressed && _gm.game_state == "playing") {
        // Ensure pause menu doesn't already exist to prevent duplicates
        if (!instance_exists(obj_pause_menu)) {
            _gm.game_state = "paused"; // Set state FIRST
            show_debug_message("Game Paused (via Player)");

            // Find a suitable layer (GUI layer is often best for menus)
            var layer_id = layer_get_id("Instances_GUI");
            if (layer_id == -1) layer_id = layer_get_id("Instances"); // Fallback
            if (layer_id == -1) {
                 show_debug_message("CRITICAL: Cannot find Instances_GUI or Instances layer for pause menu!");
            } else {
                 // Create the pause menu
                 var _pm = instance_create_layer(0, 0, layer_id, obj_pause_menu);
                 show_debug_message("Created pause menu instance: " + string(_pm));

                 // --- Deactivation ---
                 // Deactivate things that should NOT run while paused
                 instance_deactivate_object(id); // Deactivate self (the player instance) - IMPORTANT
                 instance_deactivate_object(obj_npc_parent); // Deactivate NPCs (use parent object if applicable)
                 // Add other objects to deactivate if needed (e.g., moving hazards, timers)
                 // instance_deactivate_object(obj_enemy_spawner);

                 // --- Activation ---
                 // Ensure the pause menu ITSELF is active
                 instance_activate_object(_pm);
                 // Keep essential managers active (Game Manager is usually deactivated by default unless specified)
                 instance_activate_object(obj_game_manager);
                 // Activate input object IF you use one and it was deactivated
                 // if (instance_exists(obj_input)) instance_activate_object(obj_input);

                 show_debug_message("Player and NPCs deactivated, Pause Menu and Game Manager activated.");
            }
            // Do NOT exit player step here - allow pause menu to take over immediately
            // exit; // REMOVED - Let pause menu handle input on the same frame if possible
        } else {
            // This case shouldn't happen if logic is correct, but log if it does
             show_debug_message("WARNING: Pause input pressed, but pause menu already exists!");
        }
         // Exit the player's step processing for this frame AFTER handling pause
         // to prevent movement/actions on the same frame pause is initiated.
         exit;
    } // End Pause Input Handling


    // --- MOVEMENT INPUT (Only runs if game_state is 'playing') ---
    var key_x = keyboard_check(ord("D")) - keyboard_check(ord("A"));
    var key_y = keyboard_check(ord("S")) - keyboard_check(ord("W"));
    var joy_x = gamepad_axis_value(0, gp_axislh);
    var joy_y = gamepad_axis_value(0, gp_axislv);
    var deadzone = 0.25;
    if (abs(joy_x) < deadzone) joy_x = 0;
    if (abs(joy_y) < deadzone) joy_y = 0;
    var _hor = key_x != 0 ? key_x : sign(joy_x);
    var _ver = key_y != 0 ? key_y : sign(joy_y);

    // --- Move & Collide ---
    // Ensure tilemap variable exists and is valid before using
    if (variable_instance_exists(id, "tilemap") && tilemap != -1 && is_real(tilemap)) {
        // Use your preferred collision function (move_and_collide shown)
        move_and_collide(_hor * move_speed, _ver * move_speed, tilemap);
    } else {
        // Fallback basic movement if no tilemap found
        x += _hor * move_speed;
        y += _ver * move_speed;
        if (!variable_instance_exists(id,"tilemap")) show_debug_message("Warning: obj_player missing 'tilemap' variable.");
        else if (tilemap == -1 || !is_real(tilemap)) show_debug_message("Warning: obj_player 'tilemap' variable is invalid.");
    }

    // --- Animation ---
    if (_hor != 0 || _ver != 0) { // Moving
        // Choose walk sprite based on direction
        if (_ver > 0)       sprite_index = spr_player_walk_down;
        else if (_ver < 0)  sprite_index = spr_player_walk_up;
        else if (_hor > 0)  sprite_index = spr_player_walk_right;
        else if (_hor < 0)  sprite_index = spr_player_walk_left;
        // Ensure image speed is appropriate for animation
        image_speed = 1; // Or your desired walk animation speed
    } else { // Idle
         // Change to corresponding idle sprite based on the *last* walk sprite
         // Check sprite *names* not just indices if multiple idle/walk sprites exist per direction
        if (sprite_index == spr_player_walk_right) sprite_index = spr_player_idle_right;
        else if (sprite_index == spr_player_walk_left)  sprite_index = spr_player_idle_left;
        else if (sprite_index == spr_player_walk_up)    sprite_index = spr_player_idle_up;
        else if (sprite_index == spr_player_walk_down)  sprite_index = spr_player_idle_down;
        // Stop animation on idle frames
        image_speed = 0;
        image_index = 0; // Reset to first frame of idle animation
    }

    // === Room Transitions ===
    var _exit_margin = 4; // How close to edge triggers transition
    var _exit_dir = "none";
    if (x <= _exit_margin)                  _exit_dir = "left";
    else if (x >= room_width - _exit_margin) _exit_dir = "right";
    else if (y <= _exit_margin)              _exit_dir = "above";
    else if (y >= room_height - _exit_margin)_exit_dir = "below";

    if (_exit_dir != "none") {
        // Check room connections (assuming global.room_map exists and is structured correctly)
        if (variable_global_exists("room_map") && ds_exists(global.room_map, ds_type_map)) {
            var conns = ds_map_find_value(global.room_map, room); // 'room' is the current room ID
            if (ds_exists(conns, ds_type_map)) {
                var dest = ds_map_find_value(conns, _exit_dir); // Find destination room for that direction
                if (!is_undefined(dest) && room_exists(dest)) {
                    show_debug_message("Transitioning room via exit: " + _exit_dir + " to room: " + room_get_name(dest));
                    global.entry_direction = _exit_dir; // Store direction for entry point in next room
                    room_goto(dest);
                    exit; // Exit step event after room change
                } else {
                    // No valid room connection in that direction, push player back slightly
                    if (_exit_dir == "left")    x = _exit_margin + 1;
                    if (_exit_dir == "right")   x = room_width - _exit_margin - 1;
                    if (_exit_dir == "above")   y = _exit_margin + 1;
                    if (_exit_dir == "below")   y = room_height - _exit_margin - 1;
                }
            }
        }
    }

    // --- NPC Interaction ---
    // Check slightly ahead in the direction player is facing or just at player's position
    var _interact_check_x = x; // Simple check at current pos
    var _interact_check_y = y;
    // More complex: var _interact_check_x = x + lengthdir_x(8, image_angle); // Check 8 pixels ahead
    // More complex: var _interact_check_y = y + lengthdir_y(8, image_angle);

    var _npc = instance_place(_interact_check_x, _interact_check_y, obj_npc_parent);
    var _interact_pressed = keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(0, gp_face1); // Use Confirm button

    if (instance_exists(_npc) && variable_instance_exists(_npc, "can_talk") && _npc.can_talk) {
        if (_interact_pressed) {
            show_debug_message("Interacting with NPC: " + string(_npc));
            // Tell the NPC to perform its interaction event (e.g., User Event 0)
            with (_npc) {
                event_perform(ev_other, ev_user0);
            }
            // Potentially change player state to 'dialogue' or let the NPC handle it
            // _gm.game_state = "dialogue"; // If interaction always pauses player
        }
    }
// === Room Transitions ===
var exit_margin = 4;
var exit_dir    = "none";
if (x <= exit_margin)                    exit_dir = "left";
else if (x >= room_width - exit_margin)  exit_dir = "right";
else if (y <= exit_margin)               exit_dir = "above";
else if (y >= room_height - exit_margin) exit_dir = "below";

if (exit_dir != "none") {
    if (variable_global_exists("room_map") && ds_exists(global.room_map, ds_type_map)) {
        var connMap = ds_map_find_value(global.room_map, room);
        if (ds_exists(connMap, ds_type_map) && ds_map_exists(connMap, exit_dir)) {
            var dest = ds_map_find_value(connMap, exit_dir);
            if (room_exists(dest)) {
                show_debug_message("Leaving " + room_get_name(room) + " → " + room_get_name(dest) + " via " + exit_dir);
                global.entry_direction = exit_dir;
                global.return_x = x;
                global.return_y = y;
                room_goto(dest);
                exit; // end this Step
            }
        }
    }
    // No valid exit—push back inside bounds
    if (exit_dir == "left")   x = exit_margin + 1;
    if (exit_dir == "right")  x = room_width - exit_margin - 1;
    if (exit_dir == "above")  y = exit_margin + 1;
    if (exit_dir == "below")  y = room_height - exit_margin - 1;
}
    // --- Random Encounters ---
    // Initialize timer if it doesn't exist
    if (!variable_global_exists("encounter_timer")) {
        global.encounter_timer = 0;
    }
    // Increment timer only when moving
    if (_hor != 0 || _ver != 0) {
        // Safety check if timer somehow became non-real
        if (!is_real(global.encounter_timer)) global.encounter_timer = 0;
        global.encounter_timer += 1;
    }

    // Check for encounter after timer reaches threshold
    var encounter_threshold = 100; // Steps needed for a check (adjust as needed)
    var encounter_chance = 25; // Percent chance (0-100) per check
    if (global.encounter_timer >= encounter_threshold) {
        global.encounter_timer = 0; // Reset timer after check

        // Roll for encounter
        if (random(100) < encounter_chance) {
            show_debug_message("Random encounter triggered!");
            // Check encounter table for the current room
            if (variable_global_exists("encounter_table") && ds_exists(global.encounter_table, ds_type_map)) {
                var list = ds_map_find_value(global.encounter_table, room);
                if (ds_exists(list, ds_type_list) && !ds_list_empty(list)) {
                    // Select a random formation from the list
                    var idx = irandom(ds_list_size(list) - 1);
                    var selected_formation = ds_list_find_value(list, idx);

                    // Check if formation data is valid (needs structure defined by your battle system)
                    if (is_array(selected_formation)) { // Example check: is it an array?
                         global.battle_formation = selected_formation;
                         global.original_room    = room;
                         global.return_x         = x;
                         global.return_y         = y;

                         // Go to battle room
                         if (room_exists(rm_battle)) {
                             show_debug_message("Starting battle with formation: " + string(global.battle_formation));
                             room_goto(rm_battle);
                             exit; // Exit step event
                         } else {
                              show_debug_message("ERROR: Battle room 'rm_battle' does not exist!");
                         }
                    } else {
                         show_debug_message("WARNING: Invalid battle formation data found for room " + room_get_name(room));
                    }
                } else {
                     // No encounter list found for this room
                     // show_debug_message("No encounter list for room " + room_get_name(room));
                }
            } else {
                 show_debug_message("WARNING: global.encounter_table not found or invalid.");
            }
        }
    }

} else {
    // Game manager missing or not ready
    // Log less frequently to avoid spam
    if (get_timer() mod 60 == 0) { // Log once per second
         show_debug_message("Player Step: Waiting for Game Manager or correct state. Current state: " + (instance_exists(_gm) ? string(_gm.game_state) : "GM Missing"));
    }
}