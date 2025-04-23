/// obj_battle_player :: Create Event
// Minimal initialization. Data and sprite assigned later in Step Event.

show_debug_message("--- obj_battle_player Create Start (Instance: " + string(id) + ") ---");
// The 'data' variable is assigned by obj_battle_manager AFTER this event.
// Sprite will be set in the Step event once data is available.
sprite_assigned = false; // Flag to ensure sprite is set only once