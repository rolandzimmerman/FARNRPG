/// @function scr_FetchCharacterInfo(_char_key)
/// @description Safely retrieves the base data struct for a given character key using manual copy.
/// @param {string} _char_key The unique key of the character (e.g., "hero", "claude").
/// @returns {Struct} A *copy* of the character data struct, or undefined if not found.
function scr_FetchCharacterInfo(_char_key) {
    // Ensure the global database exists and is the correct type
    if (!variable_global_exists("character_database") || !ds_exists(global.character_database, ds_type_map)) {
        show_debug_message("ERROR [scr_FetchCharacterInfo]: Global character database not initialized!");
        return undefined;
    }

    // Find the data associated with the character key
    var _original_data = ds_map_find_value(global.character_database, _char_key);

    // Check if data was found
    if (is_undefined(_original_data)) {
         show_debug_message("WARNING [scr_FetchCharacterInfo]: Character key '" + string(_char_key) + "' not found in database.");
         return undefined;
    }

    // Ensure the found data is actually a struct
    if (!is_struct(_original_data)) {
        show_debug_message("ERROR [scr_FetchCharacterInfo]: Data found for key '" + string(_char_key) + "' is not a struct!");
        return undefined;
    }

    // --- ALTERNATIVE: Manual Struct Copy ---
    show_debug_message("DIAGNOSTIC [scr_FetchCharacterInfo]: Manually copying struct for key: " + _char_key);
    var _copy_data = {}; // Create a new empty struct

    // Get the names of all variables within the original struct
    var _variable_names = variable_struct_get_names(_original_data);
    var _num_vars = array_length(_variable_names);

    // Loop through each variable name
    for (var i = 0; i < _num_vars; i++) {
        var _name = _variable_names[i];
        var _value = variable_struct_get(_original_data, _name);
        // Assign the value to the new struct using the same name
        variable_struct_set(_copy_data, _name, _value);
    }
    show_debug_message("DIAGNOSTIC [scr_FetchCharacterInfo]: Manual copy complete.");
    return _copy_data; // Return the newly created copy
    // --- End Manual Struct Copy ---

    // Original line (commented out):
    // return struct_clone(_original_data);
}