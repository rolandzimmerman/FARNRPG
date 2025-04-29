/// obj_attack_visual :: Create Event
/// Initialize visual effect & handle single-frame sprites

owner_instance = noone; // Set by the creator instance
image_speed = 1; // Default speed, creator WILL override if needed
image_index = 0;

show_debug_message(">>> obj_attack_visual Create Event Running (Instance: " + string(id) + ", Sprite: " + sprite_get_name(sprite_index) + ", Speed: " + string(image_speed) + ")");

// --- <<< NEW: Handle Single-Frame Sprites >>> ---
// If the assigned sprite has 1 or 0 frames, it won't trigger Animation End.
// Signal completion immediately and destroy self.
if (sprite_exists(sprite_index) && sprite_get_number(sprite_index) <= 1) {
    show_debug_message("    -> FX Sprite '" + sprite_get_name(sprite_index) + "' is single-frame. Finishing immediately.");
    
    // Signal the owner instance that the animation is done
    if (instance_exists(owner_instance)) {
        if (variable_instance_exists(owner_instance, "attack_animation_finished")) {
             owner_instance.attack_animation_finished = true;
             show_debug_message("        -> Set attack_animation_finished=true on owner.");
        } else { show_debug_message("        -> Owner instance missing 'attack_animation_finished' var."); }
    } else { show_debug_message("        -> Owner instance no longer exists."); }

    // Destroy self immediately
    instance_destroy(); 
    exit; // Stop rest of create event if destroying
}
// --- <<< END: Handle Single-Frame Sprites >>> ---

// (Any other Create event logic would go here)