/// obj_game_manager :: Step Event
/// @description Handle global game state, pause triggering, etc.

// The initial pause trigger (input detection, state change, menu creation, instance deactivation)
// is now handled in the Player Step (or another dedicated input object).
// This block below is commented out because that logic has been moved.
/*
var _pause_pressed = keyboard_check_pressed(vk_escape) || gamepad_button_check_pressed(0, gp_start);

if (_pause_pressed) {
    if (game_state == "playing") {
        // PAUSE THE GAME - This logic is now in the Player object or dedicated input handler
        // game_state = "paused";
        // show_debug_message("Game Paused (via Game Manager)");
        // instance_create_layer...
        // instance_deactivate_object...
        // instance_activate_object(id);
    }
    // --- Unpause Logic ---
    // This block is for handling unpausing initiated BY THE MANAGER ITSELF.
    // It's safer to let the pause menu's step handle unpausing inputs when it's active.
    // This block is commented out assuming the Pause Menu handles unpausing when it's closed.
    else if (game_state == "paused") {
         // This logic should ideally be handled in the pause menu's step
         // if (!instance_exists(obj_pause_menu)) { // Only unpause if the menu instance is gone
         //     game_state = "playing";
         //     show_debug_message("Game Resumed (via Game Manager)");
         //     instance_activate_all();
         // }
    }
} // End if pause pressed
*/


// --- Optional: Prevent other manager logic while not in 'playing' state ---
// If the manager does things every step that shouldn't happen while paused, in dialogue, battle, etc.
// This check IS useful to stop other manager logic.
// Keep save/load triggers ABOVE this if you want them to work while paused/in menus
// Remove save/load triggers below if they should only work while playing
if (game_state == "paused" || game_state == "dialogue" || game_state == "battle") {
    // Assuming you have other states where manager logic should stop
    exit; // Stop processing the rest of the manager's Step event
}


// --- Other Manager Logic (Runs only when game_state is NOT paused/dialogue/battle) ---
// Place code here that manages game-wide systems ONLY when the game is actively playing or in non-paused/dialogue/battle states.
// (Keep your F5/F9 save/load triggers here IF you want them ONLY while playing - they are in CREATE above)

/*
// Debug Save Trigger (Moved to CREATE or kept here depending on desired behavior)
if (keyboard_check_pressed(vk_f5)) {
    show_debug_message("--- F5 Pressed! Attempting Save ---");
    var _save_success = scr_save_game("mysave.json");
    show_debug_message("--- scr_save_game Result: " + string(_save_success) + " ---");
}

// Debug Load Trigger (Moved to CREATE or kept here depending on desired behavior)
if (keyboard_check_pressed(vk_f9)) {
    show_debug_message("--- F9 Pressed! Attempting Load ---");
    var _load_initiated = scr_load_game("mysave.json");
    show_debug_message("--- scr_load_game Initiated: " + string(_load_initiated) + " ---");
}
*/