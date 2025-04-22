/// @description Handle proximity, state, and interaction readiness.

// --- Add this block at the very top ---
if (instance_exists(obj_game_manager) && obj_game_manager.game_state == "paused") {
    exit; // Stop processing if game is paused
}
// --- End Add ---

// If this object itself inherits from another parent object...
// event_inherited();
// ... rest of step event ...

/// obj_npc_parent :: Step Event
/// @description Handle proximity, state, and interaction readiness.

// If this object itself inherits from another parent object that has Step logic,
// you might need to uncomment the line below. Usually not needed for a base parent like this.
// event_inherited();

// === 1. Find Player and Calculate Distance ===
var _player = instance_find(obj_player, 0); // Find the first active player instance
var _player_exists = instance_exists(_player);
var _dist = -1; // Default distance if player doesn't exist

if (_player_exists) {
    // Calculate distance from this NPC's origin to the player's origin
    _dist = distance_to_point(_player.x, _player.y);
}

// === 2. Determine Interaction Readiness (Set 'can_talk') ===
var _can_currently_talk = false; // Start assuming cannot talk this step

// Check if player exists, distance is valid, and required NPC variables exist
if (_player_exists && _dist != -1 && variable_instance_exists(id, "activation_radius") && !is_undefined(activation_radius)) {
    // Safely check the 'is_busy' state, defaulting to 'false' if the variable isn't defined/set
    var _current_is_busy = (variable_instance_exists(id, "is_busy") && !is_undefined(is_busy)) ? is_busy : false;

    // --- Core Logic ---
    // Player must be close enough (within activation_radius) AND the NPC must not be busy
    // Add any other conditions needed (e.g., && required_quest_stage_met)
    if (_dist < activation_radius && !_current_is_busy /* && other_conditions */ ) {
        // All conditions met
        _can_currently_talk = true;
    }
}

// Update the instance variable 'can_talk' based on the checks above
// This variable is used by the Player's interaction check and this NPC's Draw event (for the icon)
can_talk = _can_currently_talk;

// === 3. Optional: Other NPC Logic ===
// Add any other logic the parent NPC needs to run every step,
// such as managing its own animations (if any), checking timers, etc.
// For example:
// if (is_busy) {
//     // Handle behavior while busy...
// }

// Note: Any actual movement logic (like pathfinding or simple patrols)
// would typically go here or in separate state-driven scripts,
// likely using different variables than the player's 'move_speed'.