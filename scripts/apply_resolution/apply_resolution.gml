/// @function apply_resolution(w, h)
function apply_resolution(w, h) {
    if (global.display_mode == "Windowed" || global.display_mode == "Borderless") {
        window_set_fullscreen(false);
        window_set_size(w, h);
        if (global.display_mode == "Borderless") {
            window_set_position(0, 0);
        }
    }
}
