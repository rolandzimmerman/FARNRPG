/// obj_battle_enemy :: Create Event

// Log creation with instance ID
// Note: 'data' is assigned AFTER Create by obj_battle_manager, so it won't exist here yet.
// We should check for data in events that run later, like Step or Draw.
show_debug_message("Enemy Create: Instance ID " + string(id) + " at (" + string(x) + "," + string(y) + ")");

// Initialize basic properties if needed, but sprite/stats depend on 'data'
sprite_index = -1; // Default to no sprite initially
image_speed = 0;
visible = true; // Assume visible unless data says otherwise later? Or set in manager.

// Example: Placeholder initialization (data will override this later)
// data = { name: "TEMP", hp: 1, maxhp: 1, atk: 1, def: 1, xp: 0, sprite_index: -1 };

// The actual data assignment happens in obj_battle_manager Create event *after* this.