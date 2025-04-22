/// @function scr_save_game(filename)
/// @description Saves the current game state to a file using JSON.
/// @param {string} filename The name of the file to save to (e.g., "mysave.json")
function scr_save_game(filename) {
    show_debug_message("Attempting to save game to: " + filename);

    // --- 1. Gather Data into a Struct ---
    var _save_data = {}; // Create an empty struct (local variable)

    // Player Data (Make sure obj_player exists!)
    if (instance_exists(obj_player)) {
        _save_data.player_data = {
            x : obj_player.x,
            y : obj_player.y,
            room : room // Store the current room ID
            // Add other player stats here if needed, e.g.:
            // hp : obj_player.hp,
            // mp : obj_player.mp,
            // sprite_index : obj_player.sprite_index
        };
        show_debug_message(" > Player data gathered.");
    } else {
        show_debug_message("WARNING: obj_player not found during save! Player data NOT saved.");
        // return false; // Optional: Fail save if player doesn't exist
    }

    // Global Game Data (Add any important global vars)
    _save_data.global_data = {};
    if (variable_global_exists("quest_stage")) { // Example global variable
         _save_data.global_data.quest_stage = global.quest_stage;
    }
    // Add other global variables as needed


    // --- NPC State Data (Scalable Method using Unique IDs) ---
    _save_data.npc_states = {}; // Using a struct to store states, keyed by unique ID

    show_debug_message(" > Scanning for NPCs with unique IDs to save...");
    // Loop through all active instances of the parent NPC type and its children
    with (obj_npc_parent)
    {
        // Check if this specific instance has a unique ID assigned to it
        if (variable_instance_exists(id, "unique_npc_id"))
        {
            var _id_string = unique_npc_id;
            var _state_to_save = {};

            // Add variables common to ALL saved NPCs
            if (variable_instance_exists(id, "has_spoken_to")) {
                 _state_to_save.has_spoken_to = has_spoken_to;
            }
            // Add other common variables if needed (e.g., position)

            // Optional: Add variables specific to CHILD types
            // if (object_index == obj_npc_1) { /* save obj_npc_1 specific stuff */ }

            // Store this NPC's state struct in the main save data
            // Access the script's local _save_data directly
            _save_data.npc_states[$ _id_string] = _state_to_save;
        }
    } // End 'with (obj_npc_parent)'

    // --- Get the count using older functions for compatibility ---
    var _npc_state_keys = variable_struct_get_names(_save_data.npc_states);
    show_debug_message(" > Finished scanning NPCs. Saved state for " + string(array_length(_npc_state_keys)) + " unique NPCs."); // <<< FIX APPLIED HERE


    // --- 2. Convert Struct to JSON String ---
    var _json_string = json_stringify(_save_data);

    if (_json_string == "") {
        show_debug_message("ERROR: Failed to stringify save data!");
        return false;
    }
    show_debug_message(" > Save data stringified.");


    // --- 3. Write JSON String to File ---
    var _file = file_text_open_write(filename);
    if (_file < 0) {
        show_debug_message("ERROR: Failed to open file for writing: " + filename);
        return false;
    }

    file_text_write_string(_file, _json_string);
    file_text_close(_file);

    show_debug_message("SUCCESS: Game saved to " + filename);
    return true;
}