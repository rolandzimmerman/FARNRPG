/// obj_player :: Room Start Event
// Positions the player based on how they entered the room.

show_debug_message("Player Room Start: Entered " + room_get_name(room) + ". Entry direction: " + global.entry_direction);

// Check if we entered from a specific direction
if (global.entry_direction != "none") {
    var _entry_margin = 16; // How far from the edge to place player
    var _room_w = room_width;
    var _room_h = room_height;

    switch (global.entry_direction) {
        case "left":  // Entered from the left side (exited previous room right)
            x = _room_w - _entry_margin;
            // Keep current y or center vertically? Centering might be jarring.
            // y = _room_h / 2;
            break;
        case "right": // Entered from the right side (exited previous room left)
            x = _entry_margin;
            // y = _room_h / 2;
            break;
        case "above": // Entered from the top (exited previous room bottom)
            y = _room_h - _entry_margin;
            // x = _room_w / 2;
            break;
        case "below": // Entered from the bottom (exited previous room top)
            y = _entry_margin;
            // x = _room_w / 2;
            break;
    }
    show_debug_message(" > Positioned player at (" + string(x) + ", " + string(y) + ") based on entry direction.");

    // Reset the entry direction flag
    global.entry_direction = "none";
}