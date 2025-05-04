/// obj_battle_enemy :: Create Event (Example Parent)
// Initializes variables that DO NOT depend on the 'data' struct.
// 'data' struct and data-dependent variables (sprite, stats, fx) are assigned
// by obj_battle_manager AFTER this event runs.

show_debug_message("--- Enemy Parent Create Start (Instance: " + string(id) + ", Object: " + object_get_name(object_index) + ") ---");

// Initialize turn counter (manager calculates actual value later)
turnCounter = 0; 

// Initialize Combat State Machine variables
combat_state = "idle"; 
origin_x = x; // Store initial position
origin_y = y;
target_for_attack = noone; 
attack_fx_sprite = spr_pow;  // Default, manager might override based on data
attack_fx_sound = snd_punch; // Default, manager might override based on data
attack_animation_finished = false; 
death_anim_speed = 1; // or whatever you like
death_started    = false;


// **REMOVED from here:** Code accessing 'data' like:
// sprite_index = data.sprite_index ?? -1; 
// image_speed = ...
// attack_fx_sprite = data.attack_sprite ?? spr_pow; 
// attack_fx_sound = data.attack_sound ?? snd_punch; 

// Add any other non-data-dependent initializations here.