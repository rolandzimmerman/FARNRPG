/// obj_battle_player :: Draw Event
// Draws the player instance using its current sprite.

draw_self(); 

// You can add drawing for status icons, health bars, etc., here later if desired.
// Example: 
// if (variable_instance_exists(id,"data") && is_struct(data) && data.hp > 0) {
//     draw_healthbar(bbox_left, bbox_top - 10, bbox_right, bbox_top - 5, 100 * (data.hp / data.maxhp), c_black, c_red, c_lime, 0, true, true);
// }