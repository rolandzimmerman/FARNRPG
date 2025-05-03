// obj_item_visual :: Create Event
owner_instance = noone; // Instance ID of the player using the item
image_speed = 0;      // Item icon usually doesn't animate
image_index = 0;
sprite_index = -1;     // Will be set by creator (player)
lifespan = 40;        // How long the item sprite appears (frames, ~2/3 second at 60fps)
y_offset = -48;       // How far above the owner's origin to appear (adjust as needed)
follow_owner = true;  // Should it stick to the owner?

show_debug_message(">>> obj_item_visual Create (Instance: " + string(id) + ")");