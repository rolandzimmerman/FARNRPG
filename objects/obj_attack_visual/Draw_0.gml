/// obj_attack_visual :: Draw Event
// 1) draw the FX on the target
draw_self();

// 2) draw the item’s icon over the caster’s hand (with scale)
if (item_icon >= 0 && instance_exists(owner_instance)) {
    draw_sprite_ext(
        item_icon,                   // the inventory/potion icon
        0,                           // frame 0
        owner_instance.x + hand_offset_x,
        owner_instance.y + hand_offset_y,
        owner_instance.image_xscale * item_icon_scale,
        owner_instance.image_yscale * item_icon_scale,
        owner_instance.image_angle,
        c_white,
        1                            // full opacity
    );
}
