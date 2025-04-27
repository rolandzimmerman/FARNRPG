/// obj_battle_enemy :: Create Event

// Log creation with instance ID
// Note: 'data' is assigned AFTER Create by obj_battle_manager, so it won't exist here yet.
// We should check for data in events that run later, like Step or Draw.
show_debug_message("Enemy Create: Instance ID " + string(id) + " at (" + string(x) + "," + string(y) + ")");

// Initialize basic properties if needed, but sprite/stats depend on 'data'
sprite_index = -1; // Default to no sprite initially
image_speed = 0;
visible = true; // Assume visible unless data says otherwise later? Or set in manager.

/// obj_battle_enemy :: Create Event (Example)
// Initializes base enemy stats. Status effects are now handled globally.

// event_inherited(); // Inherit if using parent

show_debug_message("--- Enemy Create Start (Instance: " + string(id) + ", Object: " + object_get_name(object_index) + ") ---");

// Get stats
if (script_exists(scr_GetEnemyDataFromName)) {
    data = scr_GetEnemyDataFromName(object_index);
     if (!is_struct(data)) {
         show_debug_message("!!! CRITICAL ERROR: Failed to get enemy data for " + object_get_name(object_index) + " !!!");
         data = { name: "ERR_ENEMY", hp: 1, maxhp: 1, atk: 1, def: 1, xp_value: 0 }; // Minimal fallback data
     }
} else {
     show_debug_message("!!! CRITICAL ERROR: scr_GetEnemyDataFromName missing !!!");
      data = { name: "ERR_ENEMY", hp: 1, maxhp: 1, atk: 1, def: 1, xp_value: 0 };
}

// status_effect   = "none"; // REMOVED Instance Variable
// status_duration = 0;      // REMOVED Instance Variable

// Set sprite based on data if needed
// sprite_index = data.sprite ?? spr_enemy_default;