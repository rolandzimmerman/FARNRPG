/// @function string_capitalize(str)
/// @description Capitalizes the first character of a string.
/// @param {string} str The input string.
/// @returns {string} The capitalized string.
function string_capitalize(_str) {
    if (!is_string(_str) || string_length(_str) == 0) {
        return _str; // Return as-is if not a string or empty
    }
    // Capitalize the first character and append the rest of the string
    return string_upper(string_copy(_str, 1, 1)) + string_copy(_str, 2, string_length(_str) - 1);
}