//obj_game_manager create

// Initialize load state variables
load_pending = false;
loaded_data = undefined;

// Add this if you don't have a game state variable yet
if (!variable_instance_exists(id, "game_state")) { // Prevent re-init if already exists (e.g., if persistent)
    game_state = "playing"; // Possible states: "playing", "paused", "dialogue", "battle", etc.
}

// Make sure these exist from the save/load setup (redundant if initialized above, but harmless)
if (!variable_instance_exists(id, "load_pending")) { load_pending = false; }
if (!variable_instance_exists(id, "loaded_data")) { loaded_data = undefined; }

// Make sure the manager itself is persistent (Check the box in the Object Editor!)


// Save Trigger (Can be kept for debugging, but rely on menu save eventually)
if (keyboard_check_pressed(vk_f5)) {
    show_debug_message("--- F5 Pressed! Attempting Save ---"); // DEBUG
    var _save_success = scr_save_game("mysave.json"); // Make sure filename matches
    // Log whether the save script reported success or failure
    show_debug_message("--- scr_save_game Result: " + string(_save_success) + " ---"); // DEBUG
}

// Load Trigger (Can be kept for debugging, but rely on menu load eventually)
if (keyboard_check_pressed(vk_f9)) {
    show_debug_message("--- F9 Pressed! Attempting Load ---"); // DEBUG
    var _load_initiated = scr_load_game("mysave.json"); // Make sure filename matches
    // Log whether the load script initiated the process (doesn't mean loading finished)
    show_debug_message("--- scr_load_game Initiated: " + string(_load_initiated) + " ---"); // DEBUG
}