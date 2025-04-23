/// obj_init :: Create Event
/// @description Initializes global game variables and systems ONCE at game start.

show_debug_message("!!! obj_init Create Event Running !!! Game Starts / Restarts Only!");
show_debug_message("========================================");
show_debug_message("GAME INITIALIZATION STARTING");
show_debug_message("========================================");

// --- Initialize Dialog Colors ---
show_debug_message("Initializing Dialog System...");
global.char_colors = { /* ... Your color definitions ... */ };
show_debug_message("   -> global.char_colors initialized.");

// --- Initialize Encounter Table ---
show_debug_message("Initializing Encounter System...");
if (script_exists(scr_InitEncounterTable)) { scr_InitEncounterTable(); } else { global.encounter_table = ds_map_create(); }

// --- Initialize Item Database ---
show_debug_message("Initializing Item Database...");
if (script_exists(scr_ItemDatabase)) { if (variable_global_exists("item_database") && ds_exists(global.item_database, ds_type_map)) { ds_map_destroy(global.item_database); } global.item_database = scr_ItemDatabase(); } else { global.item_database = ds_map_create(); }

// --- Initialize Character Database ---
show_debug_message("Initializing Character Database...");
// --- FIX: Call the RENAMED function ---
if (script_exists(scr_BuildCharacterDB)) { // Check for the new script name
    if (variable_global_exists("character_database") && ds_exists(global.character_database, ds_type_map)) {
        ds_map_destroy(global.character_database);
    }
    global.character_database = scr_BuildCharacterDB(); // Call the new function name
    show_debug_message("  -> Global character database created via scr_BuildCharacterDB.");
} else {
    show_debug_message("  -> WARNING: scr_BuildCharacterDB script not found!");
    global.character_database = ds_map_create();
}
// --- End Fix --- 
    
/// /// obj_init :: Create Event
// ... (after other initializations) ...

// --- Initialize Global Party CURRENT Stats ---
show_debug_message("Initializing Global Party Current Stats...");
global.party_current_stats = ds_map_create();
show_debug_message("  -> Global party current stats map created.");

// --- Other Initializations ---
// ...

// --- Initialize Global Party List ---
show_debug_message("Initializing Global Party List...");
global.party_members = [];
show_debug_message("  -> Global party list created.");

// --- Other Initializations ---
global.entry_direction = "none";
randomise();

show_debug_message("========================================");
show_debug_message("GAME INITIALIZATION COMPLETE");
show_debug_message("========================================");