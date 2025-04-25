/// obj_init :: Create Event
/// @description Initializes global game variables and systems ONCE at game start.

show_debug_message("!!! obj_init Create Event Running !!!");
show_debug_message("========================================");
show_debug_message("GAME INITIALIZATION STARTING");
show_debug_message("========================================");

// --- Dialog Colors ---
show_debug_message("Initializing Dialog System...");
global.char_colors = {
    "System": c_white,
    "Hero":   c_aqua,
    "Claude": c_lime
    // …add others…
};
show_debug_message("   -> global.char_colors initialized.");

// --- Encounter Table ---
show_debug_message("Initializing Encounter System...");
if (script_exists(scr_InitEncounterTable)) {
    if (variable_global_exists("encounter_table") && ds_exists(global.encounter_table, ds_type_map))
        ds_map_destroy(global.encounter_table);
    scr_InitEncounterTable();
    show_debug_message("   -> encounter_table initialized.");
} else {
    show_debug_message("   -> WARNING: scr_InitEncounterTable not found.");
    global.encounter_table = ds_map_create();
}

// --- Item Database ---
show_debug_message("Initializing Item Database...");
if (script_exists(scr_ItemDatabase)) {
    if (variable_global_exists("item_database") && ds_exists(global.item_database, ds_type_map))
        ds_map_destroy(global.item_database);
    global.item_database = scr_ItemDatabase();
    show_debug_message("   -> item_database created.");
} else {
    show_debug_message("   -> WARNING: scr_ItemDatabase not found.");
    global.item_database = ds_map_create();
}

// --- Character Database ---
show_debug_message("Initializing Character Database...");
if (script_exists(scr_BuildCharacterDB)) {
    if (variable_global_exists("character_data") && ds_exists(global.character_data, ds_type_map))
        ds_map_destroy(global.character_data);
    global.character_data = scr_BuildCharacterDB();
    show_debug_message("   -> character_data created.");
} else {
    show_debug_message("   -> WARNING: scr_BuildCharacterDB not found.");
    global.character_data = ds_map_create();
}

// --- Spell Database ---
show_debug_message("Initializing Spell Database...");
if (script_exists(scr_BuildSpellDB)) {
    global.spell_db = scr_BuildSpellDB();
    show_debug_message("   -> spell_db initialized.");
} else {
    show_debug_message("   -> WARNING: scr_BuildSpellDB not found.");
    global.spell_db = {};
}

// --- Party Current Stats Map ---
show_debug_message("Initializing Party Current Stats...");
if (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map))
    ds_map_destroy(global.party_current_stats);
global.party_current_stats = ds_map_create();
show_debug_message("   -> party_current_stats map created.");

// --- Party Members List ---
show_debug_message("Initializing Party Members List...");
global.party_members = [];  // e.g. ["hero", "claude", …]
show_debug_message("   -> party_members array created.");

// --- Miscellaneous ---
global.entry_direction = "none";
randomise();

show_debug_message("========================================");
show_debug_message("GAME INITIALIZATION COMPLETE");
show_debug_message("========================================");
