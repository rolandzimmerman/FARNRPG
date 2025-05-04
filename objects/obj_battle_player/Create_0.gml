/// obj_battle_player :: Create Event
/// Initializes player combat variables. Data is assigned by obj_battle_manager.

show_debug_message("--- obj_battle_player Create START (Instance: " + string(id) + ") ---");

// --- References & Data ---
character_key = "unknown"; 
data = {};                 
party_slot_index = -1;     

// --- State Machine & Animation ---
combat_state = "idle"; 
origin_x = x; origin_y = y;
target_for_attack = noone; 
attack_animation_finished = false; 
stored_action_for_anim = undefined; 

// --- Sprite Handling ---
sprite_assigned = false;    
idle_sprite = sprite_index; 
attack_sprite_asset = -1;   
casting_sprite_asset = -1; 
item_sprite_asset = -1; // <<< ADDED: To store item usage sprite
sprite_before_attack = sprite_index; 
original_scale = 1.0; 

// --- Attack Animation Speed ---
attack_anim_speed = 0.5; 
show_debug_message(" -> Player Create: attack_anim_speed initialized to: " + string(attack_anim_speed));

// --- Movement Animation (Not used) ---
target_move_x = x;          
target_move_y = y;

// Turn Counter - Initialized by Manager
turnCounter = 0;            

// --- FX Info (Defaults, may be overridden) ---
attack_fx_sprite = spr_pow;  
attack_fx_sound = snd_punch; 

// --- ITEM DRAW OFFSETS (tweak once here) ---
item_offset_x = 16;
item_offset_y = -8;
death_anim_speed = 0.2; // or whatever feels right
death_started    = false;

show_debug_message("--- obj_battle_player Create END ---");