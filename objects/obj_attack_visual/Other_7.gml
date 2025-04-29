/// Signal owner and destroy self when animation finishes

// <<< ADDED LOG >>>
show_debug_message(">>> obj_attack_visual Animation End Event Triggered (Instance: " + string(id) + ", Owner: " + string(owner_instance) + ")");
// <<< END LOG >>>

// Signal the owner instance that the animation is done
if (instance_exists(owner_instance)) {
    if (variable_instance_exists(owner_instance, "attack_animation_finished")) {
         owner_instance.attack_animation_finished = true;
         show_debug_message("    -> Set attack_animation_finished=true on owner.");
    } else { show_debug_message("    -> Owner instance missing 'attack_animation_finished' var."); }
} else { show_debug_message("    -> Owner instance no longer exists."); }

// Destroy the visual effect instance
instance_destroy();