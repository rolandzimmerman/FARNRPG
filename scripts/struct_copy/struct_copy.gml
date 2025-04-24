/// @function struct_copy(original_struct)
/// @description Returns a shallow copy of a struct.
/// @param {Struct} original_struct
/// @returns {Struct} A new struct with the same fields and values

function struct_copy(_s) {
    var _new = {};
    var _keys = variable_struct_get_names(_s);
    for (var i = 0; i < array_length(_keys); i++) {
        var _k = _keys[i];
        variable_struct_set(_new, _k, variable_struct_get(_s, _k));
    }
    return _new;
}
