/// obj_battle_player :: Create Event
persistent = false; // Players are recreated by the manager in the battle room
sprite_assigned = false; 
turnCounter = 0; // Initialized by manager after data is set

// --- Combat Animation State Variables ---
combat_state = "idle"; // Controls animation/movement ("idle", "attack_start", "attack_waiting", "attack_return", "dying")
origin_x = x;
origin_y = y;
target_for_attack = noone; // Instance ID of the target for the current action
attack_fx_sprite = spr_pow; // Sprite for the visual effect (default)
attack_fx_sound = snd_punch; // Sound effect for the attack (default)
attack_animation_finished = false; // Flag set by obj_attack_visual
stored_action_for_anim = undefined; // Holds the action struct/string ("Attack") for the state machine to use