/// obj_battle_player :: Draw Event

// Draw the base sprite
draw_self();

// Draw status indicator if affected
if (variable_instance_exists(id, "data") && is_struct(data)) {
    if (variable_struct_exists(data, "status") && data.status == "poison") {
        // Option 1: Tint the sprite purple
        draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, c_purple, 0.5); // Draw semi-transparent purple overlay

        // Option 2: Draw a small poison icon above the head
        // if (sprite_exists(spr_status_poison)) {
        //     draw_sprite(spr_status_poison, 0, x, bbox_top - 10);
        // }
    }
    // Add checks for other statuses here...
}