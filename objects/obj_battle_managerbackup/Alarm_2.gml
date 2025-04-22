room_goto(global.original_room);

// Optional: store and restore player position
var player = instance_find(obj_player, 0);
if (player != noone) {
    player.x = global.return_x;
    player.y = global.return_y;
}

if (variable_global_exists("original_room")) {
    room_goto(global.original_room);
} else {
    // fallback
    room_goto(Room1);
}
