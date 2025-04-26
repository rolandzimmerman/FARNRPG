/// @description ResumePauseMenu()
// This event is called by sub-menus (like equipment) to tell the pause menu to resume its normal operation.

show_debug_message("obj_pause_menu User Event 2 (ResumePauseMenu) triggered."); // ADD THIS
// Set the internal 'active' flag back to true
active = true;
show_debug_message("obj_pause_menu internal active flag set to true. Instance ID: " + string(id) + ", Object: " + object_get_name(object_index)); // ADD THIS

// The pause menu's Step event will now run fully because 'active' is true.
// Its check 'if (_gm.game_state != "paused") { instance_destroy(); }'
// will ensure it stays active only if the game state is still "paused".
// We don't need to change game_state or activate/deactivate other instances here;
// the pause menu's existing logic handles that based on the game_state.