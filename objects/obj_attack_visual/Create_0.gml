/// obj_attack_visual :: Create Event
show_debug_message(">>> obj_attack_visual Create Event Running (Instance: " + string(id) + ")"); // Debug Log Added
image_speed = 1; // Adjust if needed based on sprite animation speed (e.g., sprite_get_speed(sprite_index) / game_get_speed(gamespeed_fps))
owner_instance = noone; // The instance that created this effect (Set by creator)