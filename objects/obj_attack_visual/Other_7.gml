/// obj_attack_visual :: Animation End Event
// This event triggers when the assigned sprite finishes its animation.

show_debug_message(">>> obj_attack_visual Animation End (Instance: " + string(id) + ", Owner: " + string(owner_instance) + ")");

// Signal the owner instance (the attacker) that the animation is complete
if (instance_exists(owner_instance)) {
    // Check if the owner still expects the signal (might be important if multiple effects overlap)
    if (variable_instance_exists(owner_instance, "attack_animation_finished")) {
         owner_instance.attack_animation_finished = true; 
         show_debug_message("    -> Set attack_animation_finished=true on owner.");
    } else {
         show_debug_message("    -> Owner instance does not have 'attack_animation_finished' variable.");
    }
} else {
     show_debug_message("    -> Owner instance no longer exists.");
}

// Destroy this visual effect instance
instance_destroy();