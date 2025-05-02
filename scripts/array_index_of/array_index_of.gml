/// @function array_index_of(arr, value)
/// @desc Returns the index of `value` in `arr`, or -1 if not found
function array_index_of(arr, value) {
    for (var i = 0; i < array_length(arr); i++) {
        if (arr[i] == value) {
            return i;
        }
    }
    return -1;
}
