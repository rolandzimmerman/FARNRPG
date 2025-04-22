/// obj_npc_parent :: User Event 1
// Dialog Definition Event - Parent Version (Fallback)
// This event is called by the Parent Create Event.
// Child NPCs should override this event to define their specific dialog arrays.

show_debug_message("⚠️ Parent User Event 1 Ran: Child object '" + object_get_name(object_index) + "' (ID: " + string(id) + ") did not override User Event 1 to define its dialog!");

// Optionally set truly empty defaults here if needed, though 'undefined' is often better for checks.
// dialog_initial = [];
// dialog_repeat = [];