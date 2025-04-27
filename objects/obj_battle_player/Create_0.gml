/// obj_battle_player :: Create Event
// Initializes battle player state. Status effects are now handled globally.

show_debug_message("--- obj_battle_player Create Start (Instance: " + string(id) + ") ---");

// Initialize 'data' struct - holds persistent/calculated stats
data = {};

// status_effect   = "none"; // REMOVED Instance Variable
// status_duration = 0;      // REMOVED Instance Variable

// Flag for sprite assignment
sprite_assigned = false;

// List for usable items (populated by Step event)
battle_usable_items = [];