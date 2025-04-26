/// obj_pause_menu :: Step Event
/// Handles navigation and actions within the main pause menu.

// — only run if this menu is active —
// Ensure 'active' is initialized to true in Create Event
if (!variable_instance_exists(id, "active") || !active) return;

// --- SAFETY CHECK: Ensure game is actually paused ---
// Find game manager instance ONCE per step if needed multiple times
var _gm = instance_exists(obj_game_manager) ? obj_game_manager : noone;
if (_gm == noone || !variable_instance_exists(_gm, "game_state") || _gm.game_state != "paused")
{
    show_debug_message("Pause Menu Step: Game not paused or GM missing. Destroying self.");
    // Attempt to reactivate everything just in case something went wrong
    instance_activate_all();
    instance_destroy();
    exit;
}

// --- INPUT (Directly or via obj_input if you fix it later) ---
var device = 0;
var up      = keyboard_check_pressed(vk_up)    || gamepad_button_check_pressed(device, gp_padu);
var down    = keyboard_check_pressed(vk_down)  || gamepad_button_check_pressed(device, gp_padd);
var confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(device, gp_face1);
var back    = keyboard_check_pressed(vk_escape)|| gamepad_button_check_pressed(device, gp_face2)|| gamepad_button_check_pressed(device, gp_start); // Allow Start to resume

// --- Initialize menu variables if they don't exist ---
if (!variable_instance_exists(id, "menu_options"))    menu_options = ["Resume", "Equipment", "Save Game", "Load Game", "Quit"]; // Example options
if (!variable_instance_exists(id, "menu_item_count")) menu_item_count = array_length(menu_options);
if (!variable_instance_exists(id, "menu_index"))      menu_index = 0;


// --- NAVIGATION ————————————————————————————————————————————
if (up) {
    menu_index = (menu_index - 1 + menu_item_count) mod menu_item_count;
    // audio_play_sound(snd_menu_cursor, 1, false); // Optional sound
}
if (down) {
    menu_index = (menu_index + 1) mod menu_item_count;
    // audio_play_sound(snd_menu_cursor, 1, false); // Optional sound
}


// --- RESUME / CLOSE PAUSE MENU (Back button or Resume selection) ——————————
if (back || (confirm && menu_options[menu_index] == "Resume")) {
    // audio_play_sound(snd_menu_cancel, 1, false); // Or a resume sound

    // 1) Un-pause game state
    _gm.game_state = "playing"; // Use the _gm variable found earlier
    show_debug_message("Game Resumed (via Pause Menu)");

    // 2) Reactivate ALL previously deactivated gameplay objects
    //    This is CRUCIAL for making the player movable again and NPCs active.
    instance_activate_all();
    show_debug_message("Called instance_activate_all()");

    // 3) Destroy this pause menu instance
    instance_destroy();
    exit; // Important: exit step event after destroying self
}


// --- CONFIRM ACTIONS (Other Menu Options) —————————————————————————————
if (confirm) { // This block only runs if 'Resume' was NOT the selected option
    var opt = menu_options[menu_index];
    // audio_play_sound(snd_menu_select, 1, false); // Optional select sound

    switch (opt) {
        case "Save Game":
            // NOTE: instance_activate_all() was called when resuming,
            // so objects needed for saving *should* be active if the game wasn't in a strange state.
            // If save needs specific active states different from normal play, handle activation here.
            show_debug_message("Pause Menu: Save Game selected.");
            // Make sure objects needed for saving (like obj_player) are active
            // instance_activate_object(obj_player); // Probably not needed if resume logic works
            if (script_exists(scr_save_game)) {
                scr_save_game("mysave.json"); // Make sure the save script works correctly
                 show_debug_message(" -> Save attempt finished.");
            } else {
                 show_debug_message(" -> ERROR: scr_save_game script not found!");
            }
            // If you specifically activated objects just for saving, deactivate them again
            // instance_deactivate_object(obj_player);
            break;

        case "Load Game":
            show_debug_message("Pause Menu: Load Game selected.");
             // Ensure everything is active before loading, just in case
             instance_activate_all();
             if (script_exists(scr_load_game)) {
                 // Load script should handle room changes & destroying this menu if needed
                 scr_load_game("mysave.json");
                 show_debug_message(" -> Load attempt finished (Load script handles transition).");
                 // Typically, you might not destroy the menu here if scr_load_game changes room
                 // instance_destroy();
             } else {
                  show_debug_message(" -> ERROR: scr_load_game script not found!");
             }
            break;

        case "Quit":
            show_debug_message("Pause Menu: Quit selected.");
            game_end(); // End the game
            break;

        case "Equipment":
            show_debug_message("Pause Menu: Equipment selected.");
            // Open equipment submenu only if one doesn't already exist
            if (!instance_exists(obj_equipment_menu)) {
                // Find a suitable layer
                var layer_id = layer_get_id("Instances_GUI");
                if (layer_id == -1) layer_id = layer_get_id("Instances"); // Fallback
                if (layer_id == -1) {
                    show_debug_message("ERROR: Cannot find layer 'Instances_GUI' or 'Instances' for equipment menu!");
                    break; // Don't create if layer is missing
                }

                // Create the equipment menu instance
                var em = instance_create_layer(0, 0, layer_id, obj_equipment_menu);

                if (instance_exists(em)) { // Check if creation succeeded
                    // --- Pass control ---
                    em.calling_menu = id; // <<< Set the calling_menu variable on the equipment menu
                    show_debug_message(" -> Created obj_equipment_menu (ID: " + string(em) + "), setting calling_menu to " + string(id));

                    // Make the equipment menu active (it should handle its own 'active' state)
                    instance_activate_object(em); // Ensure it's active

                    // --- Deactivate this pause menu ---
                    active = false; // Use the flag to stop this menu's processing
                    show_debug_message(" -> Pause menu 'active' flag set to false.");

                } else {
                     show_debug_message(" -> ERROR: Failed to create obj_equipment_menu instance!");
                }
            } else {
                 show_debug_message(" -> WARNING: Equipment menu already exists!");
            }
            break; // Break from the switch case
    } // End Switch
} // End if(confirm)