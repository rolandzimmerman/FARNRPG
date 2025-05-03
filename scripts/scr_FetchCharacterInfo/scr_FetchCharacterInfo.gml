/// @function scr_FetchCharacterInfo(_char_key)
/// @description Safely retrieves a DEEP COPY of the base data struct for a given character key.
///              The returned struct already contains `cast_fx_sprite` (from scr_BuildCharacterDB).
/// @param {string} _char_key The unique key of the character (e.g., "hero", "claude").
/// @returns {Struct} A *deep copy* of the character data struct, or undefined if not found or invalid.
function scr_FetchCharacterInfo(_char_key) {
    // 1) Verify the global map exists
    if (!variable_global_exists("character_data") 
     || !ds_exists(global.character_data, ds_type_map)) {
        show_debug_message("❌ ERROR [scr_FetchCharacterInfo]: global.character_data not initialized!");
        return undefined;
    }

    // 2) Retrieve the base struct
    var _orig = ds_map_find_value(global.character_data, _char_key);
    if (!is_struct(_orig)) {
        show_debug_message("❌ ERROR [scr_FetchCharacterInfo]: Invalid or missing data for key '" 
                         + string(_char_key) + "'");
        return undefined;
    }

    // 3) Deep clone
    show_debug_message("🔍 Cloning character_info for key: " + string(_char_key));
    var _copy = variable_clone(_orig, true);
    if (!is_struct(_copy)) {
        show_debug_message("❌ ERROR [scr_FetchCharacterInfo]: Clone failed for key '" 
                         + string(_char_key) + "'");
        return undefined;
    }

    // 4) Return the deep copy (which includes cast_fx_sprite)
    show_debug_message("✅ Character info cloned for: " + string(_char_key)
                     + " | cast_fx_sprite = " 
                     + string(_copy.cast_fx_sprite));
    return _copy;
}
