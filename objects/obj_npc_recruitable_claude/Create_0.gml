/// obj_npc_recruitable_claude :: Create Event

// --- Inherit Parent Variables & Logic FIRST ---
event_inherited(); // Runs obj_npc_parent's Create Event

// --- Define Child-Specific Variables AFTER inheriting ---
unique_npc_id = "claude_recruit_location_1"; // Unique ID for saving state if needed
can_recruit = true;                          // <<< Initialize the recruitment flag
character_key = "claude";                    // Key matching the entry in scr_CharacterDatabase

// Initial dialogue before recruitment
dialogue_data = [
    { name: "Claude", msg: "Looking for adventure? Maybe we should team up!" }
];

show_debug_message("Created recruitable NPC: Claude (ID: " + string(id) + ")"); // Optional debug