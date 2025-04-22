/// scr_InitRoomMap()
function scr_InitRoomMap() {
    global.room_map = ds_map_create();

    var m = ds_map_create();
    ds_map_add(m, "left",  undefined);
    ds_map_add(m, "right", Room2);
    ds_map_add(m, "above", undefined);
    ds_map_add(m, "below", undefined);
    ds_map_add(global.room_map, Room1, m);
    
    
}
