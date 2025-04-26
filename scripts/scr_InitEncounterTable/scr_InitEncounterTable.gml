/// scr_InitEncounterTable()
// Initializes the global encounter data structure.

function scr_InitEncounterTable() {
    // Cleanup existing table (Your existing cleanup logic is good)
    if (variable_global_exists("encounter_table") && ds_exists(global.encounter_table, ds_type_map)) {
        var room_key = ds_map_find_first(global.encounter_table);
        while (!is_undefined(room_key)) { // GMS1/older check for end
            var list_to_destroy = ds_map_find_value(global.encounter_table, room_key);
            if (ds_exists(list_to_destroy, ds_type_list)) {
                 ds_list_destroy(list_to_destroy);
            }
            room_key = ds_map_find_next(global.encounter_table, room_key);
        }
        ds_map_destroy(global.encounter_table);
    }

    // Create the main map
    global.encounter_table = ds_map_create();
    show_debug_message("Initializing Encounter Table Map...");

    // === Define Encounters per Room ===
    // IMPORTANT: Ensure 'Room1' and 'Room2' below are EXACTLY your Room Asset names!

    // === Room 1 Encounters ===
    var list_room1 = ds_list_create();
    ds_list_add(list_room1, [obj_enemy_goblin, obj_enemy_goblin]);
    ds_list_add(list_room1, [obj_enemy_nut_thief, obj_enemy_nut_thief, obj_enemy_goblin]);
    ds_map_add_list(global.encounter_table, Room1, list_room1); // Using Room1 as key
    show_debug_message("  -> Added formations for Room: Room1");

    // === Room 2 Encounters ===
    var list_room2 = ds_list_create();
    ds_list_add(list_room2, [obj_enemy_nut_thief, obj_enemy_nut_thief, obj_enemy_goblin]);
    ds_list_add(list_room2, [obj_enemy_goblin]);
    ds_map_add_list(global.encounter_table, Room2, list_room2); // Using Room2 as key
    show_debug_message("  -> Added formations for Room: Room2");

    // Add other rooms and their formation lists...

    show_debug_message("💾 Encounter Table Initialized. Size: " + string(ds_map_size(global.encounter_table)));

    // IMPORTANT: Remember DS Map/List cleanup on Game End event
}