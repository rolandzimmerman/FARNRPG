// obj_item_visual :: Step Event
// Follows owner and fades / destroys self

// Follow Owner
if (follow_owner && instance_exists(owner_instance)) {
    x = owner_instance.x;
    y = owner_instance.y + y_offset; // Apply offset
    // Match owner's horizontal direction? (Optional)
    // image_xscale = owner_instance.image_xscale;
    // Match owner's alpha? (Optional)
    // image_alpha = owner_instance.image_alpha;
} else {
     // Owner gone? Destroy immediately.
     if (!instance_exists(owner_instance) && owner_instance != noone) {
         instance_destroy();
         exit; // Exit step if destroyed
     }
}

// Countdown lifespan
lifespan -= 1;
if (lifespan <= 0) {
    instance_destroy();
} else {
    // Optional: Fade out effect near the end
     image_alpha = clamp(lifespan / 15, 0, 1); // Fade out over last 15 frames
}