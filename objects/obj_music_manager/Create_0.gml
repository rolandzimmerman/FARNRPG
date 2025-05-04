/// obj_music_manager :: Create Event
/// Manages persistent music playback state. Ensures only one instance exists.

show_debug_message("--- Music Manager Create START ---");

// --- Singleton Check ---
if (instance_number(object_index) > 1) {
    show_debug_message("!!! Duplicate Music Manager found. Destroying self. !!!");
    instance_destroy();
    exit;
}
// --- End Singleton Check ---

persistent = true;
show_debug_message(" -> Music Manager Initialized (Singleton - Instance ID: " + string(id) + ")");

// Initialize Music Tracking Variables
current_music_asset = noone;
current_music_instance = noone;
pre_battle_music_asset = noone;
pre_battle_music_position = 0;
pre_battle_room = noone;

// --- NEW: Variable to track instance fading out ---
instance_fading_out = noone;
fade_time_ms = 500; // Default fade time: 1000ms = 1 second
// --- END NEW VARIABLE ---