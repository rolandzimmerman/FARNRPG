// obj_battle_player :: Create Event

var switcher = instance_find(obj_battle_switcher, 0);
if (switcher != noone && variable_instance_exists(switcher, "player_data")) {
    data = switcher.player_data;
} else {
    data = {
        hp: 20,
        hp_total:20,
        atk: 5,
        def: 2,
        charge: 0
    };
}


//data = obj_battle_switcher.player_data;