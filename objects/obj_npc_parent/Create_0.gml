/// obj_npc_parent :: Create Event
// Parent object for common NPC behaviors. Initializes variables and triggers dialog definition.

show_debug_message("Parent NPC Create: Instance ID " + string(id) + ", Object: " + object_get_name(object_index));

// --- Dialog Variables ---
// These will typically be defined by the child NPC in User Event 1
dialog_initial = undefined;
dialog_repeat = undefined;

// --- State Variables ---
has_spoken_to = false;  // Has the player completed the initial dialogue?
can_talk = false;       // Is the player currently close enough and conditions met to talk? (Set by Step Event)
is_busy = false;        // Is the NPC currently busy (e.g., walking, performing action)? (FIX: Added initialization)

// --- Other common NPC properties ---
activation_radius = 64; // How close player must be to interact. (FIX: Renamed from interaction_distance and removed 'var')
input_key = vk_space;   // Default interaction key (can be overridden by child or changed globally)

//show_debug_message("   -> Parent Create finished. Initializing: activation_radius=" + string(activation_radius) + ", is_busy=" + string(is_busy));
//show_debug_message("   -> Triggering User Event 1 for dialog definition...");

// --- Trigger Dialog Definition Event ---
// This calls User Event 1 in the child object (or this parent if the child doesn't have one).
// User Event 1 is expected to set the 'dialog_initial' and 'dialog_repeat' variables.
event_perform(ev_other, ev_user1);

//show_debug_message("   -> Returned from User Event 1 call.");

// You can add further checks here if needed, e.g., warn if dialog variables are still undefined after User Event 1.
// if (is_undefined(dialog_initial)) { show_debug_message("   -> WARNING: dialog_initial was not set by User Event 1."); }
// if (is_undefined(dialog_repeat)) { show_debug_message("   -> WARNING: dialog_repeat was not set by User Event 1."); }