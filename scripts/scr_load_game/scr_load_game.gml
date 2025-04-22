/// @function scr_load_game(filename)
/// @description Reads save data from a file and prepares for loading state.
/// @param {string} filename The name of the file to load from (e.g., "savegame.json")
/// @returns {Bool} True if file read and parsed successfully, false otherwise.
function scr_load_game(filename) {
    show_debug_message("Attempting to load game from: " + filename);

    // --- 1. Check if File Exists ---
    if (!file_exists(filename)) {
        show_debug_message("ERROR: Save file not found: " + filename);
        return false;
    }

    // --- 2. Read JSON String from File ---
    var _file = file_text_open_read(filename);
    if (_file < 0) {
        show_debug_message("ERROR: Failed to open file for reading: " + filename);
        return false;
    }

    var _json_string = "";
    while (!file_text_eof(_file)) { // Read potentially multiple lines
        _json_string += file_text_readln(_file);
    }
    file_text_close(_file);

    if (_json_string == "") {
        show_debug_message("ERROR: Save file is empty: " + filename);
        return false;
    }
    show_debug_message(" > Save file read.");

    // --- 3. Parse JSON String into Struct ---
    var _load_data = json_parse(_json_string);

    if (!is_struct(_load_data)) {
        show_debug_message("ERROR: Failed to parse save data or data is not a struct!");
        // Clean up potentially invalid parsed data
        if (is_array(_load_data) || is_map(_load_data)) { try { ds_destroy(_load_data); } catch(_e){} }
        _load_data = undefined;
        return false;
    }
    show_debug_message(" > Save data parsed successfully.");


    // --- 4. Store Data in Persistent Manager & Trigger Load ---
    // Ensure obj_game_manager exists and is persistent!
    if (!instance_exists(obj_game_manager)) {
         show_debug_message("CRITICAL ERROR: obj_game_manager instance not found! Cannot proceed with load.");
         // Clean up parsed data if necessary
         // try { struct_delete(_load_data); } catch(_e){} // Not a built-in function, structs garbage collect
         _load_data = undefined; // Allow garbage collection
         return false;
    }

    // Store the loaded data temporarily in the manager
    obj_game_manager.loaded_data = _load_data;
    obj_game_manager.load_pending = true; // Flag that we need to apply data after room change

    // --- 5. Go to the Saved Room ---
    // Important: Check if the target room exists
    var _target_room = _load_data.player_data.room;
    if (!room_exists(_target_room)) {
        show_debug_message("ERROR: Room specified in save file does not exist: " + string(_target_room));
        obj_game_manager.loaded_data = undefined; // Clear pending load
        obj_game_manager.load_pending = false;
        return false;
    }

    show_debug_message(" > Stored loaded data in manager. Transitioning to room: " + room_get_name(_target_room));
    room_goto(_target_room);

    // We don't return true here immediately because the actual application happens after room_goto
    // But the reading/parsing part was successful up to triggering the room change.
    // The manager object will handle the rest.
    // Returning true might be misleading if the post-load application fails.
    // The function essentially 'succeeds' if it initiates the room change.
    return true; // Indicate that the load *process* has started.
}