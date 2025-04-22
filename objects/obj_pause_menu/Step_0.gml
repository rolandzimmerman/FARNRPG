/// @description Handle navigation and selection within the pause menu

// --- Safety Check ---
// Ensure game is actually paused. If not, destroy self.
// (Helps prevent issues if menu is created at wrong time)
if (!instance_exists(obj_game_manager) || obj_game_manager.game_state != "paused") {
     instance_destroy();
     exit;
}

// --- Input Reading ---
var _up_pressed = keyboard_check_pressed(vk_up) || gamepad_button_check_pressed(0, gp_padu);
var _down_pressed = keyboard_check_pressed(vk_down) || gamepad_button_check_pressed(0, gp_padd);
var _confirm_pressed = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(0, gp_face1); // A button
var _cancel_pressed = keyboard_check_pressed(vk_escape) || gamepad_button_check_pressed(0, gp_face2) || gamepad_button_check_pressed(0, gp_start); // B button or Start

// --- Navigation ---
if (_down_pressed) {
    menu_index = (menu_index + 1) % menu_item_count;
    // if (audio_exists(snd_cursor)) audio_play_sound(snd_cursor, 0, false);
}
if (_up_pressed) {
    menu_index = (menu_index - 1 + menu_item_count) % menu_item_count;
    // if (audio_exists(snd_cursor)) audio_play_sound(snd_cursor, 0, false);
}

// --- Action Handling ---
// Unpause if Cancel/Start/Escape pressed OR Resume selected
if (_cancel_pressed || (_confirm_pressed && menu_options[menu_index] == "Resume")) {
    // if (audio_exists(snd_cancel)) audio_play_sound(snd_cancel, 0, false);
    // Signal manager to handle unpausing
    if (instance_exists(obj_game_manager)) {
        obj_game_manager.game_state = "playing";
    }
    instance_activate_all(); // Reactivate gameplay objects
    instance_destroy(); // Destroy the menu
    exit; // Stop processing step event for the menu
}

// Handle Confirm press for other options
if (_confirm_pressed) {
    var _selected_option = menu_options[menu_index];
    // if (audio_exists(snd_select)) audio_play_sound(snd_select, 0, false);

    switch (_selected_option) {
case "Save Game":
                    show_debug_message("Pause Menu: Activating objects for save..."); // DEBUG

                    // --- Temporarily Reactivate Objects Needed for Saving ---
                    // Reactivate any object types whose instances you need to access in scr_save_game
                    instance_activate_object(obj_player);       // If saving player data
                    instance_activate_object(obj_npc_parent);   // This reactivates parent AND its children (like obj_npc_dom)
                    // Add instance_activate_object() calls for any other specific object types you save data from

                    // --- Call the save function ---
                    // It should now be able to find the reactivated instances
                    show_debug_message("Pause Menu: Calling scr_save_game..."); // DEBUG
                    var _save_success = scr_save_game("mysave.json"); // Use your filename
                    show_debug_message("Pause Menu: scr_save_game result: " + string(_save_success)); // DEBUG

                    // --- Deactivate Objects Again (VERY IMPORTANT!) ---
                    // Put the objects back into hibernation to maintain the paused state
                    show_debug_message("Pause Menu: Deactivating objects post-save..."); // DEBUG
                    instance_deactivate_object(obj_player);
                    instance_deactivate_object(obj_npc_parent);
                    // Add instance_deactivate_object() calls for any others you reactivated above

                    // --- Optional: Provide feedback to the player ---
                    if (_save_success) {
                        // e.g., Create a temporary feedback object: instance_create_layer(x, y, layer, obj_save_feedback);
                        show_debug_message("Game Saved!"); // Simple feedback
                    } else {
                        // e.g., Create feedback: instance_create_layer(x, y, layer, obj_save_failed_feedback);
                        show_debug_message("Save Failed!"); // Simple feedback
                    }
                    break; // End of Save Game case

         case "Load Game":
             show_debug_message("Pause Menu: Calling scr_load_game...");
             // Optional: Add a confirmation prompt here ("Are you sure?")
             instance_activate_all(); // Reactivate objects BEFORE attempting room change
             var _load_initiated = scr_load_game("mysave.json"); // Use your filename
             if (!_load_initiated) {
                 // Load failed immediately (e.g., file not found)
                 show_debug_message("Load failed to initiate.");
                 // Deactivate again if load fails? Depends on desired flow.
                 // instance_deactivate_object(obj_player);
                 // instance_deactivate_object(obj_npc_parent);
             }
             // If load initiated, menu will be destroyed by room change.
             break;

        case "Quit":
            show_debug_message("Pause Menu: Quitting game...");
            game_end(); // Close the game application
            break;
    }
}