// Initialize load state variables
load_pending = false;
loaded_data = undefined;

// Add this if you don't have a game state variable yet
if (!variable_instance_exists(id, "game_state")) { // Prevent re-init if already exists
    game_state = "playing"; // Possible states: "playing", "paused", "dialogue", "battle", etc.
}

// Make sure these exist from the save/load setup
if (!variable_instance_exists(id, "load_pending")) { load_pending = false; }
if (!variable_instance_exists(id, "loaded_data")) { loaded_data = undefined; }

// Make sure the manager itself is persistent (Check the box in the Object Editor!)
