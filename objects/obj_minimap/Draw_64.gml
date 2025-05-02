if (!visible) exit;

// ░░░ DRAW THE BORDER FIRST (box1)
draw_sprite_stretched(spr_box1, 0, frame_x, frame_y, frame_width, frame_height);

// ░░░ DRAW BACKGROUND IMAGE
draw_sprite_stretched(spr_minimap, 0, frame_x, frame_y, frame_width, frame_height);

// ░░░ DRAW ROOMS
var map_margin = 32;
var content_x = frame_x + map_margin;
var content_y = frame_y + map_margin;

var key = ds_map_find_first(global.room_coords);
while (!is_undefined(key)) {
    var coord = global.room_coords[? key];
    var map_xpos = content_x + coord.x * scale;
    var map_ypos = content_y + coord.y * scale;

    draw_set_color(c_white);
    draw_rectangle(map_xpos, map_ypos, map_xpos + scale, map_ypos + scale, false);

    if (room == key) {
        draw_set_color(c_red);
        draw_rectangle(map_xpos + 2, map_ypos + 2, map_xpos + scale - 2, map_ypos + scale - 2, false);
    }

    key = ds_map_find_next(global.room_coords, key);
}

draw_set_color(c_white);
