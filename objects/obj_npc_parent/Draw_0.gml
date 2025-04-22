/// obj_npc_parent :: Draw Event
// Handles drawing the NPC sprite and the interaction indicator.

// 1. Draw the NPC itself first
if (sprite_exists(sprite_index)) {
    draw_self();
} else {
    draw_set_color(c_red);
    draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, false);
    draw_set_color(c_white);
}

// 2. Draw the animated "Talk" indicator if applicable
if (can_talk && !instance_exists(obj_dialog)) {
    if (sprite_exists(spr_talk)) {
        // Calculate position above NPC's head (adjust offset as needed)
        var _indicator_x = x + 24;
        var _indicator_y = bbox_top - 32; // Increased offset for 192px tall sprite
        
        // Get and update animation frame
        if (!variable_instance_exists(id, "talk_anim_frame")) {
            talk_anim_frame = 0;
            talk_anim_speed = 0.05; // Animation speed (adjust as needed)
        }
        
        // Draw current frame
        draw_sprite(spr_talk, floor(talk_anim_frame), _indicator_x, _indicator_y);
        
        // Advance animation (loop if needed)
        talk_anim_frame += talk_anim_speed;
        if (talk_anim_frame >= sprite_get_number(spr_talk)) {
            talk_anim_frame = 0;
        }
    } else {
        if (!variable_instance_exists(id, "_warned_spr_talk")) {
            show_debug_message("WARNING: Missing 'spr_talk' sprite for " + object_get_name(object_index));
            _warned_spr_talk = true;
        }
    }
}