/// scr_InitRoomMap()
// Initializes the global room connection map using Room IDs as keys.

function scr_InitRoomMap() {
    // Destroy existing map if necessary
    if (variable_global_exists("room_map") && ds_exists(global.room_map, ds_type_map)) {
        // Need to destroy nested maps first
        var _key = ds_map_find_first(global.room_map);
        while(!is_undefined(_key)) {
            var _nested_map = ds_map_find_value(global.room_map, _key);
            if (ds_exists(_nested_map, ds_type_map)) {
                ds_map_destroy(_nested_map);
            }
            _key = ds_map_find_next(global.room_map, _key);
        }
        ds_map_destroy(global.room_map);
    }

    global.room_map = ds_map_create();
    show_debug_message("Initializing Room Map...");

    // --- Room 1 Connections ---
    // IMPORTANT: Use the actual Room Asset names (Room1, Room2) here
    // but store them using their ID as the key in the main map.
    var _room1_id = Room1; // Get the ID of Room1 asset
    var _map1 = ds_map_create();
    ds_map_add(_map1, "left",  Room2); // Destination is Room2 asset ID
    ds_map_add(_map1, "right", Room2);
    ds_map_add(_map1, "above", Room2);
    ds_map_add(_map1, "below", Room2);
    ds_map_add(global.room_map, _room1_id, _map1); // Use Room1's ID as the key
    show_debug_message("  -> Added connections for Room ID: " + string(_room1_id) + " (Room1)");

    // --- Room 2 Connections ---
    var _room2_id = Room2; // Get the ID of Room2 asset
    var _map2 = ds_map_create();
    ds_map_add(_map2, "left",  Room1); // Example: Go back to Room1
    ds_map_add(_map2, "right", Room1);
    ds_map_add(_map2, "above", Room1);
    ds_map_add(_map2, "below", Room1);
    ds_map_add(global.room_map, _room2_id, _map2); // Use Room2's ID as the key
    show_debug_message("  -> Added connections for Room ID: " + string(_room2_id) + " (Room2)");

    // Add connections for other rooms...

    show_debug_message("Room Map Initialized. Size: " + string(ds_map_size(global.room_map)));
}