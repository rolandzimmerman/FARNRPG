// Save Trigger
if (keyboard_check_pressed(vk_f5)) {
    show_debug_message("--- F5 Pressed! Attempting Save ---"); // DEBUG
    var _save_success = scr_save_game("mysave.json"); // Make sure filename matches
    // Log whether the save script reported success or failure
    show_debug_message("--- scr_save_game Result: " + string(_save_success) + " ---"); // DEBUG
}

// Load Trigger
if (keyboard_check_pressed(vk_f9)) {
    show_debug_message("--- F9 Pressed! Attempting Load ---"); // DEBUG
    var _load_initiated = scr_load_game("mysave.json"); // Make sure filename matches
    // Log whether the load script initiated the process (doesn't mean loading finished)
    show_debug_message("--- scr_load_game Initiated: " + string(_load_initiated) + " ---"); // DEBUG
}

/// @description Handle global game state, pause triggering, etc.

// --- Pause Input Check ---
// Use Escape on keyboard or Start button on gamepad
var _pause_pressed = keyboard_check_pressed(vk_escape) || gamepad_button_check_pressed(0, gp_start);

if (_pause_pressed) {
    if (game_state == "playing") {
        // --- PAUSE THE GAME ---
        game_state = "paused";
        show_debug_message("Game Paused");

        // Create the pause menu instance
        // Ensure you have a layer named "Instances_UI" or similar for menus, adjust if needed
        if (!instance_exists(obj_pause_menu)) { // Create only if it doesn't exist
             instance_create_layer(0, 0, "Instances", obj_pause_menu); // Create on a suitable UI layer
        }

        // Deactivate instances that should not run during pause
        // This prevents their Step and Draw events from running
        instance_deactivate_object(obj_player);
        instance_deactivate_object(obj_npc_parent); // Deactivates parent AND children like obj_npc_1
        // Add other objects to deactivate (e.g., enemies if any on overworld, particle systems)
        // instance_deactivate_object(obj_some_other_gameplay_object);

        // IMPORTANT: Keep obj_game_manager active so it can detect the unpause button!

    } else if (game_state == "paused") {
        // --- UNPAUSE THE GAME ---
        game_state = "playing";
        show_debug_message("Game Resumed");

        // Destroy the pause menu instance
        instance_destroy(obj_pause_menu); // Destroys all instances of the menu

        // Reactivate everything that was deactivated.
        // instance_activate_all() is simple but might activate unwanted things.
        // instance_activate_all();
        // More controlled reactivation:
        instance_activate_object(obj_player);
        instance_activate_object(obj_npc_parent); // Activates parent AND children
        // instance_activate_object(obj_some_other_gameplay_object);

    }
} // End if pause pressed


// --- Optional: Prevent other manager logic while paused ---
// If the manager does things every step that shouldn't happen while paused, add this:
// if (game_state == "paused") {
//     exit; // Stop processing the rest of the manager's Step event
// }


// --- Other Manager Logic ---
// (Keep your F5/F9 save/load triggers here if you still want them for debug,
//  or rely solely on the pause menu now)

/*
// Debug Save Trigger (Can be removed if using menu exclusively)
if (keyboard_check_pressed(vk_f5)) {
    show_debug_message("--- F5 Pressed! Attempting Save ---");
    var _save_success = scr_save_game("mysave.json");
    show_debug_message("--- scr_save_game Result: " + string(_save_success) + " ---");
}

// Debug Load Trigger (Can be removed if using menu exclusively)
if (keyboard_check_pressed(vk_f9)) {
    show_debug_message("--- F9 Pressed! Attempting Load ---");
    var _load_initiated = scr_load_game("mysave.json");
    show_debug_message("--- scr_load_game Initiated: " + string(_load_initiated) + " ---");
}
*/