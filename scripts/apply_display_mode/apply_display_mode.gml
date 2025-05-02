/// @function apply_display_mode(mode)
function apply_display_mode(mode) {
    var res = global.resolution_options[global.resolution_index];

    if (mode == "Windowed") {
        window_set_fullscreen(false);
        apply_resolution(res[0], res[1]);
    }
    else if (mode == "Fullscreen") {
        window_set_fullscreen(true);
    }
    else if (mode == "Borderless") {
        window_set_fullscreen(false);
        var w = display_get_width();
        var h = display_get_height();
        window_set_size(w, h);
        window_set_position(0, 0);
    }
}
