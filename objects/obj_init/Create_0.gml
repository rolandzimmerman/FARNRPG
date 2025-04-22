/// obj_init :: Create Event
/// @description Initializes global game variables and systems ONCE at game start.

show_debug_message("!!! obj_init Create Event Running !!! Game Starts / Restarts Only!"); // For verifying it runs once

show_debug_message("========================================");
show_debug_message("GAME INITIALIZATION STARTING");
// --- FIX: Added string() conversion ---
show_debug_message("Current Date & Time: " + string(date_current_datetime()));
// --- End Fix ---
show_debug_message("========================================");


// --- Initialize Dialog Colors ---
show_debug_message("Initializing Dialog System...");
// Initialize Dialog Colors Struct and assign to GLOBAL variable
global.char_colors = {
    // Add ALL names used in your dialogs and system messages
    "Congrats" : c_yellow,
    "Dom"      : c_yellow,
    "Boyo"     : c_aqua,
    "Claude"   : c_orange,
    "Hero"     : c_white,    // Assuming default player name
    "System"   : c_yellow,   // For system messages like "Not enough MP"
    "Victory!" : c_lime,     // For the battle victory message
    "Defeat"   : c_red,      // For potential battle defeat message
    "Goblin"   : c_green,    // Example enemy name
    "Slime"    : c_aqua,     // Example enemy name
    // Add any other character names used in your game...
};
show_debug_message("   -> global.char_colors initialized.");
show_debug_message("      Example Color Check - Victory!: " + string(global.char_colors[$ "Victory!"])); // Debug check


// --- Initialize Encounter Table ---
show_debug_message("Initializing Encounter System...");
// Always try to destroy first (if variable exists), then always create new.
if (variable_global_exists("encounter_table")) {
    if (ds_exists(global.encounter_table, ds_type_map)) {
        // IMPORTANT: Need to destroy nested lists before destroying the map
        var room_key = ds_map_find_first(global.encounter_table);
        while (!is_undefined(room_key)) { // GMS1/older check for end
            var list_to_destroy = ds_map_find_value(global.encounter_table, room_key);
            if (ds_exists(list_to_destroy, ds_type_list)) {
                 ds_list_destroy(list_to_destroy);
            }
            room_key = ds_map_find_next(global.encounter_table, room_key);
        }
        ds_map_destroy(global.encounter_table);
        show_debug_message("   -> Destroyed existing global.encounter_table.");
    }
}
// Check if script exists before calling
if (script_exists(scr_InitEncounterTable)) {
    scr_InitEncounterTable(); // Call the script to set up encounters
    show_debug_message("   -> Encounter Table initialized via scr_InitEncounterTable().");
} else {
    show_debug_message("   -> ⚠️ scr_InitEncounterTable script not found! Creating empty table.");
    global.encounter_table = ds_map_create(); // Create empty map as fallback
}


// --- Add any other game-wide initializations here ---
randomise(); // Seed the random number generator (Good practice to call once)


show_debug_message("========================================");
show_debug_message("GAME INITIALIZATION COMPLETE");
show_debug_message("========================================");


// Optional: Destroy self if only used for init
// instance_destroy();