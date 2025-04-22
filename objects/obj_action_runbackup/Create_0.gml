action = function ()
{
    room_goto(obj_battle_switcher.original_room);
}
// Safe return to previous room
if (variable_global_exists("original_room")) {
    room_goto(global.original_room);
}

// Optional: reposition player
var player = instance_find(obj_player, 0);
if (player != noone) {
    player.x = global.return_x;
    player.y = global.return_y;
}
global.original_room = undefined;
global.return_x = undefined;
global.return_y = undefined;
global.current_enemy = undefined;
