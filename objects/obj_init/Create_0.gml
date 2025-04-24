/// obj_init :: Create Event
/// @description Initializes global game variables and systems ONCE at game start.

show_debug_message("!!! obj_init Create Event Running !!! Game Starts / Restarts Only!");
show_debug_message("========================================");
show_debug_message("GAME INITIALIZATION STARTING");
show_debug_message("========================================");

// --- Initialize Dialog Colors ---
show_debug_message("Initializing Dialog System...");
global.char_colors = {
    "System": c_white,
    "Hero": c_aqua,
    "Claude": c_lime,
    // Add other character colors
};
show_debug_message("   -> global.char_colors initialized.");

// --- Initialize Encounter Table ---
show_debug_message("Initializing Encounter System...");
if (script_exists(scr_InitEncounterTable)) {
    if (variable_global_exists("encounter_table") && ds_exists(global.encounter_table, ds_type_map)) {
        ds_map_destroy(global.encounter_table);
    }
    scr_InitEncounterTable();
    show_debug_message("   -> Global encounter table initialized.");
} else {
    show_debug_message("   -> WARNING: scr_InitEncounterTable script not found!");
    global.encounter_table = ds_map_create();
}

// --- Initialize Item Database ---
show_debug_message("Initializing Item Database...");
if (script_exists(scr_ItemDatabase)) {
    if (variable_global_exists("item_database") && ds_exists(global.item_database, ds_type_map)) {
        ds_map_destroy(global.item_database);
    }
    global.item_database = scr_ItemDatabase();
    show_debug_message("   -> Global item database initialized via scr_ItemDatabase.");
} else {
    show_debug_message("   -> WARNING: scr_ItemDatabase script not found!");
    global.item_database = ds_map_create();
}

// --- Initialize Character Database (IMPORTANT FIX HERE) ---
show_debug_message("Initializing Character Database...");
if (script_exists(scr_BuildCharacterDB)) {
    if (variable_global_exists("character_data") && ds_exists(global.character_data, ds_type_map)) {
        ds_map_destroy(global.character_data);
    }
    global.character_data = scr_BuildCharacterDB(); // <--- FIXED NAME
    show_debug_message("   -> Global character database created via scr_BuildCharacterDB.");
} else {
    show_debug_message("   -> WARNING: scr_BuildCharacterDB script not found!");
    global.character_data = ds_map_create();
}

// --- Initialize Spell Database ---
show_debug_message("Initializing Spell Database...");
if (script_exists(scr_BuildSpellDB)) {
    if (variable_global_exists("spell_db") && is_struct(global.spell_db)) {
        show_debug_message("   -> Existing global.spell_db struct found, overwriting.");
    }
    global.spell_db = scr_BuildSpellDB();
    show_debug_message("   -> Global spell database initialized via scr_BuildSpellDB.");
} else {
    show_debug_message("   -> WARNING: scr_BuildSpellDB script not found!");
    global.spell_db = {}; // fallback
}

// --- Initialize Global Party Stats ---
show_debug_message("Initializing Global Party Current Stats...");
if (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) {
    ds_map_destroy(global.party_current_stats);
}
global.party_current_stats = ds_map_create();
show_debug_message("   -> Global party current stats map created.");

// --- Initialize Party List (Order) ---
show_debug_message("Initializing Global Party List...");
global.party_members = []; // This array stores character keys like ["hero", "claude"]
show_debug_message("   -> Global party list created.");

// --- Misc ---
global.entry_direction = "none";
randomise();

show_debug_message("========================================");
show_debug_message("GAME INITIALIZATION COMPLETE");
show_debug_message("========================================");
