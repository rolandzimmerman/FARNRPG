/// obj_battle_player :: Draw Event
/// Draw self, then if in item animation, draw the item icon over the hand

// 1. Draw the character’s current sprite + animation
draw_self();

// 2. If we’re in an item‐use pose, overlay the item’s inventory icon
if (combat_state == "item_start" || combat_state == "item_return") {
    // stored_action_for_anim was set to the item_data struct in your animation code
    var d = stored_action_for_anim;
    if (is_struct(d)
     && variable_struct_exists(d, "sprite_index")
     && sprite_exists(d.sprite_index)) {
        
        // Draw the item’s inventory icon (subimage 0) at (x + offset, y + offset)
        draw_sprite_ext(
            d.sprite_index,       // inventory icon sprite
            0,                    // use frame 0
            x + item_offset_x,    // offset into the hand
            y + item_offset_y,
            image_xscale,         // match your current scale
            image_yscale,
            image_angle,          // match facing
            c_white,
            1                     // full opacity
        );
    }
}
