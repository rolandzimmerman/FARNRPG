/// obj_attack_visual :: Create Event
owner_instance     = noone;   // set by creator
image_speed        = 1;       // override as needed
image_index        = 0;
image_alpha        = 0.7;
depth              = -10;

// Built-in hand offsets
hand_offset_x      = 70;
hand_offset_y      = -48;

// The item icon to draw (set by creator)
item_icon          = -1;

// <<< NEW: scale factor for the item icon >>>
item_icon_scale    = .75 ;       // 1 = normal size, 0.5 = half, 2 = double, etc.

show_debug_message(
    ">>> obj_attack_visual Create ("
  + string(id)
  + ") FX Sprite: "
  + sprite_get_name(sprite_index)
  + " Speed: "
  + string(image_speed)
);

// If this FX sprite has ≤1 frames, finish immediately:
if (sprite_exists(sprite_index) && sprite_get_number(sprite_index) <= 1) {
    if (instance_exists(owner_instance)
     && variable_instance_exists(owner_instance, "attack_animation_finished")) {
        owner_instance.attack_animation_finished = true;
    }
    instance_destroy();
    exit;
}
