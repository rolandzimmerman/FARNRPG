/// obj_init :: Create Event
/// @description Initializes global game variables and systems ONCE at game start.

show_debug_message("!!! obj_init Create Event Running !!! Game Starts / Restarts Only!");

show_debug_message("========================================");
show_debug_message("GAME INITIALIZATION STARTING");
show_debug_message("Current Date & Time: " + string(date_current_datetime()));
show_debug_message("========================================");


// --- Initialize Dialog Colors ---
show_debug_message("Initializing Dialog System...");
global.char_colors = {
    "Congrats" : c_yellow, "Dom" : c_yellow, "Boyo" : c_aqua, "Claude" : c_orange,
    "Hero" : c_white, "System" : c_yellow, "Victory!" : c_lime, "Defeat" : c_red,
    "Goblin" : c_green, "Slime" : c_aqua, "Level Up!": c_fuchsia // Added Level Up
    // Add other names...
};
show_debug_message("   -> global.char_colors initialized.");


// --- Initialize Encounter Table ---
show_debug_message("Initializing Encounter System...");
if (script_exists(scr_InitEncounterTable)) {
    scr_InitEncounterTable(); // Call the script to set up encounters
    show_debug_message("   -> Encounter Table initialized via scr_InitEncounterTable().");
} else {
    show_debug_message("   -> ⚠️ scr_InitEncounterTable script not found! Encounters may not work.");
    global.encounter_table = ds_map_create(); // Create empty map as fallback
}


// --- Initialize Item Database ---
show_debug_message("Initializing Item Database...");
if (script_exists(scr_ItemDatabase)) {
    // Check if it already exists (e.g., if init runs multiple times)
    if (variable_global_exists("item_database") && ds_exists(global.item_database, ds_type_map)) {
        ds_map_destroy(global.item_database); // Destroy old one first
    }
    global.item_database = scr_ItemDatabase(); // Create and store the database map
    show_debug_message("  -> Global item database created.");
} else {
    show_debug_message("  -> WARNING: scr_ItemDatabase script not found! Items will not work.");
    global.item_database = ds_map_create(); // Create empty map as fallback
}


// --- Other Initializations ---
randomise(); // Seed random number generator

show_debug_message("========================================");
show_debug_message("GAME INITIALIZATION COMPLETE");
show_debug_message("========================================");

// Optional: Destroy self if only used for init
// instance_destroy();