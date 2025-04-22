/// obj_battle_enemy :: Create Event

var switcher = instance_find(obj_battle_switcher, 0);

if (switcher != noone && variable_instance_exists(switcher, "enemy_data")) {
    data = switcher.enemy_data;
} else {
    data = {
        hp: 30,
        hp_total: 30,
        atk: 5,
        def: 2,
        sprite_index: spr_enemy1
    };
}

if (!variable_struct_exists(data, "hp_total")) data.hp_total = data.hp;

sprite_index = data.sprite_index;
