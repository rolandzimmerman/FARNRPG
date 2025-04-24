/// @function scr_FetchCharacterInfo(_char_key)
/// @description Safely retrieves the base data struct for a given character key using manual copy.
/// @param {string} _char_key The unique key of the character (e.g., "hero", "claude").
/// @returns {Struct} A *copy* of the character data struct, or undefined if not found.
function scr_FetchCharacterInfo(_char_key) {
    // ✅ Corrected global name
    if (!variable_global_exists("character_data") || !ds_exists(global.character_data, ds_type_map)) {
        show_debug_message("❌ ERROR [scr_FetchCharacterInfo]: global.character_data not initialized!");
        return undefined;
    }

    var _original_data = ds_map_find_value(global.character_data, _char_key);

    if (is_undefined(_original_data)) {
        show_debug_message("⚠️ WARNING: Character key '" + string(_char_key) + "' not found in global.character_data");
        return undefined;
    }

    if (!is_struct(_original_data)) {
        show_debug_message("❌ ERROR: Data for key '" + string(_char_key) + "' is not a struct!");
        return undefined;
    }

    // Manual deep copy
    show_debug_message("🔍 Copying struct for key: " + _char_key);
    var _copy_data = {};
    var _variable_names = variable_struct_get_names(_original_data);
    var _num_vars = array_length(_variable_names);

    for (var i = 0; i < _num_vars; i++) {
        var _name = _variable_names[i];
        var _value = variable_struct_get(_original_data, _name);
        variable_struct_set(_copy_data, _name, _value);
    }

    show_debug_message("✅ Manual struct copy complete for " + _char_key);
    return _copy_data;
}
