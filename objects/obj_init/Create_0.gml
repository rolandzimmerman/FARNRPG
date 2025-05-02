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

// --- Party Members List ---
show_debug_message("Initializing Party Members List...");
if (!variable_global_exists("party_members") || !is_array(global.party_members)) { // Prevent duplicates if init runs again
    global.party_members = [];  // e.g. ["hero", "claude", …]
    show_debug_message("  -> global.party_members array created.");
} else {
     show_debug_message("  -> global.party_members already exists.");
}


// --- SHARED PARTY INVENTORY ---  <<<< NEW SECTION
show_debug_message("Initializing Shared Party Inventory...");
if (!variable_global_exists("party_inventory") || !is_array(global.party_inventory)) { // Prevent re-init
    global.party_inventory = [
        { item_key: "potion", quantity: 5 }, // Start with some items
        { item_key: "bomb", quantity: 3 },
        { item_key: "antidote", quantity: 2 },
        { item_key: "bronze_sword", quantity: 1 },
        { item_key: "leather_armor", quantity: 1 }, // Added example armor
        {item_key: "wooden_staff", quantity: 1 },
        { item_key: "iron_dagger", quantity: 1 },
        {item_key: "thief_gloves", quantity: 1 },
        { item_key: "lucky_charm", quantity: 1 }
    ];
     show_debug_message("  -> global.party_inventory created with starting items: " + string(global.party_inventory));
} else {
      show_debug_message("  -> global.party_inventory already exists.");
}
// --- END SHARED PARTY INVENTORY ---

// --- Miscellaneous ---
global.entry_direction = "none";
randomise();

show_debug_message("========================================");
show_debug_message("GAME INITIALIZATION COMPLETE");
show_debug_message("========================================");

// (Make sure obj_init runs *before* obj_player is created, typically by room order or creation code)

//if (!instance_exists(obj_minimap)) {
//    instance_create_layer(0, 0, "Instances", obj_minimap);
//}
