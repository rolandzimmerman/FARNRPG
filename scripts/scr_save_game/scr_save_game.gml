/// @function scr_save_game(filename)
/// @description Saves the current game state to a file using JSON.
/// @param {string} filename The name of the file to save to (e.g., "mysave.json")
function scr_save_game(filename) {
    show_debug_message("Attempting to save game to: " + filename);

    // --- 1. Gather Data into a Struct ---
    var _save_data = {}; 

    // Player Position/Room Data
    if (instance_exists(obj_player)) {
        _save_data.player_data = {
            x : obj_player.x,
            y : obj_player.y,
            room : room // Store the current room ID
        };
        show_debug_message(" > Player pos/room data gathered.");
    } else {
        show_debug_message("WARNING: obj_player not found during save! Player pos/room NOT saved.");
        // Decide if save should fail entirely if player doesn't exist
        // return false; 
    }

    // Global Game Data (Example)
    _save_data.global_data = {};
    if (variable_global_exists("quest_stage")) { _save_data.global_data.quest_stage = global.quest_stage; }
    // Add other essential global variables here

    // NPC State Data
    _save_data.npc_states = {}; 
    /* ... existing logic to loop through obj_npc_parent and save states ... */
    var _npc_state_keys = variable_struct_get_names(_save_data.npc_states);
    show_debug_message(" > Saved state for " + string(array_length(_npc_state_keys)) + " unique NPCs.");

    // --- <<< NEW: SAVE PARTY DATA >>> ---
    // Save Party Members Array
    if (variable_global_exists("party_members") && is_array(global.party_members)) {
        _save_data.party_members_list = global.party_members; // Arrays are directly saveable in JSON
        show_debug_message(" > Party members list gathered.");
    } else {
         show_debug_message(" > WARNING: global.party_members missing or not an array during save.");
         _save_data.party_members_list = []; // Save empty array
    }
    
    // Save Party Inventory Array
     if (variable_global_exists("party_inventory") && is_array(global.party_inventory)) {
        _save_data.party_inventory_list = global.party_inventory; // Array of structs is directly saveable in JSON
         show_debug_message(" > Party inventory list gathered.");
    } else {
         show_debug_message(" > WARNING: global.party_inventory missing or not an array during save.");
         _save_data.party_inventory_list = []; // Save empty array
    }

    // Save Party Stats Map (Convert DS Map to String)
    if (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) {
         _save_data.party_stats_map_string = ds_map_write(global.party_current_stats); // Convert map to string
         show_debug_message(" > Party stats map string generated.");
    } else {
          show_debug_message(" > WARNING: global.party_current_stats missing or not a DS Map during save.");
          _save_data.party_stats_map_string = ""; // Save empty string
    }
    // --- <<< END SAVE PARTY DATA >>> ---


    // --- 2. Convert TOP LEVEL Struct to JSON String ---
    var _json_string = json_stringify(_save_data);

    if (_json_string == "" || is_undefined(_json_string)) { // Added undefined check
        show_debug_message("ERROR: Failed to stringify save data! Data: " + string(_save_data));
        return false;
    }
    show_debug_message(" > Save data stringified.");
    // show_debug_message("Save JSON: " + _json_string); // Optional: Log the JSON itself


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