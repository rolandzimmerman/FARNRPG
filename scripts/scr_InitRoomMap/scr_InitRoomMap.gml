/// @function scr_InitRoomMap()
/// @description Initializes the global room connection map using Room IDs as keys.
function scr_InitRoomMap() {
    // Destroy existing map (and its nested maps) if necessary
    if (variable_global_exists("room_map") && ds_exists(global.room_map, ds_type_map)) {
        var key = ds_map_find_first(global.room_map);
        while (!is_undefined(key)) {
            var nested = ds_map_find_value(global.room_map, key);
            if (ds_exists(nested, ds_type_map)) {
                ds_map_destroy(nested);
            }
            key = ds_map_find_next(global.room_map, key);
        }
        ds_map_destroy(global.room_map);
    }

    // Create fresh map
    global.room_map = ds_map_create();
    show_debug_message("Initializing Room Map...");

    // Room1 connections
    var r1 = Room1;
    var m1 = ds_map_create();
    ds_map_add(m1, "left",  Room2);
    ds_map_add(m1, "right", rm_debug_1);
    ds_map_add(m1, "above", rm_debug);
    ds_map_add(m1, "below", noone);
    ds_map_add(global.room_map, r1, m1);

    // Room2 connections
    var r2 = Room2;
    var m2 = ds_map_create();
    ds_map_add(m2, "left",  noone);
    ds_map_add(m2, "right", Room1);
    ds_map_add(m2, "above", noone);
    ds_map_add(m2, "below", noone);
    ds_map_add(global.room_map, r2, m2);
    
    var r3 = rm_debug;
    var m3 = ds_map_create();
    ds_map_add(m3, "left",  noone);
    ds_map_add(m3, "right", noone);
    ds_map_add(m3, "above", noone);
    ds_map_add(m3, "below", Room1);
    ds_map_add(global.room_map, r3, m3);
    
        var r4 = rm_debug_1;
    var m4 = ds_map_create();
    ds_map_add(m4, "left",  Room1);
    ds_map_add(m4, "right", noone);
    ds_map_add(m4, "above", noone);
    ds_map_add(m4, "below", noone);
    ds_map_add(global.room_map, r4, m4);

    // …add more rooms here…

    show_debug_message("Room Map Initialized. Rooms: " + string(ds_map_size(global.room_map)));
}
// Layout coordinates for minimap display (example layout)
global.room_coords = ds_map_create();
ds_map_add(global.room_coords, Room1, {x: 1, y: 1});
ds_map_add(global.room_coords, Room2, {x: 0, y: 1});
// Add more as needed
