/// @function scr_DeepCopyArrayOfStructs(_source_array)
/// @description Creates a deep copy of an array potentially containing SIMPLE structs.
/// @param {Array<Struct>} _source_array The array to copy.
/// @returns {Array<Struct>} A new array with deep copies of the structs.
function scr_DeepCopyArrayOfStructs(_source_array) {
    if (!is_array(_source_array)) {
        show_debug_message("ERROR [scr_DeepCopyArrayOfStructs]: Input is not an array! Provided: " + string(_source_array));
        return []; // Return empty array if input is bad
    }
    
    var _new_array = []; // Initialize an empty array to push into
    var _len = array_length(_source_array);
    
    show_debug_message(" -> [scr_DeepCopyArrayOfStructs] Attempting manual copy of array length: " + string(_len));
    
    for (var i = 0; i < _len; i++) {
        var _original_element = _source_array[i];
        
        // If the element is a struct, copy it field by field
        if (is_struct(_original_element)) {
            var _copied_struct = {}; // Create a new empty struct
            var _keys = variable_struct_get_names(_original_element);
            var _key_count = array_length(_keys);
            // show_debug_message("    -> Copying struct at index " + string(i) + " with " + string(_key_count) + " keys."); // Optional verbose log

            for (var j = 0; j < _key_count; j++) {
                 var _key = _keys[j];
                 var _value = variable_struct_get(_original_element, _key);
                 // Directly set the value - This creates a shallow copy for nested data, 
                 // but skill structs seem simple enough for this to be okay.
                 // If skill structs ever contain nested arrays/structs, this needs variable_clone(_value, true)
                 variable_struct_set(_copied_struct, _key, _value); 
            }
            array_push(_new_array, _copied_struct); // Add the newly copied struct to the array

        } 
        // If it's a nested array, use variable_clone (less likely for skills, but for robustness)
        else if (is_array(_original_element)) {
            show_debug_message("    -> Cloning nested array at index " + string(i));
             array_push(_new_array, variable_clone(_original_element, true)); 
        } 
        // Otherwise (primitive like number, string), copy directly
        else {
             array_push(_new_array, _original_element); 
        }
    }
    
    show_debug_message(" -> [scr_DeepCopyArrayOfStructs] Finished manual copy. New array length: " + string(array_length(_new_array)));
    // Make absolutely sure we return the array we pushed elements into
    return _new_array; 
}