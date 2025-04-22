if (instance_exists(obj_dialog)) exit;

var _hor = clamp(target_x - x, -1, 1);
var _ver = clamp(target_y - y, -1, 1);

move_and_collide(_hor * move_speed, _ver * move_speed, [tilemap, obj_enemy_parent]);

if (hp <=0)
{
    instance_destroy();
    
    obj_player.add_xp(xp_value);
}