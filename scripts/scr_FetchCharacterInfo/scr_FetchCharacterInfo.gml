/// @function scr_FetchCharacterInfo(_char_key)
/// @description Safely retrieves a DEEP COPY of the base data struct for a given character key.
/// @param {string} _char_key The unique key of the character (e.g., "hero", "claude").
/// @returns {Struct} A *deep copy* of the character data struct, or undefined if not found or invalid.
function scr_FetchCharacterInfo(_char_key) {
    // ✅ Corrected global name
    if (!variable_global_exists("character_data") || !ds_exists(global.character_data, ds_type_map)) {
        show_debug_message("❌ ERROR [scr_FetchCharacterInfo]: global.character_data not initialized!");
        return undefined;
    }

    var _original_data = ds_map_find_value(global.character_data, _char_key);

    if (is_undefined(_original_data)) {
        show_debug_message("⚠️ WARNING [scr_FetchCharacterInfo]: Character key '" + string(_char_key) + "' not found in global.character_data");
        return undefined;
    }

    if (!is_struct(_original_data)) {
        show_debug_message("❌ ERROR [scr_FetchCharacterInfo]: Data for key '" + string(_char_key) + "' is not a struct!");
        return undefined;
    }

    // --- Use variable_clone for a proper deep copy ---
    show_debug_message("🔍 Deep cloning struct for key: " + _char_key);
    var _copy_data = variable_clone(_original_data, true); 
    // --- End deep copy ---

    // Optional: Check if clone was successful (variable_clone returns undefined on failure)
    if (is_undefined(_copy_data)) {
         show_debug_message("❌ ERROR [scr_FetchCharacterInfo]: variable_clone failed for key: " + string(_char_key));
         return undefined;
    }

    show_debug_message("✅ Deep clone complete for " + _char_key);
    return _copy_data; // Return the independent deep copy
}