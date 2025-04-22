/// scr_GetEnemyDataFromName

function scr_GetEnemyDataFromName(_obj) {
    switch (_obj) {
        case obj_enemy_goblin:
            return {
                name: "Goblin",
                hp: 30,
                maxhp: 30,
                atk: 6,
                def: 2,
                xp: 20,
                sprite_index: spr_enemy_goblin
            };
        case obj_enemy_slime:
            return {
                name: "Slime",
                hp: 20,
                maxhp: 20,
                atk: 4,
                def: 1,
                xp: 15,
                sprite_index: spr_enemy_slime
            };
        default:
            return {
                name: "???",
                hp: 10,
                maxhp: 10,
                atk: 2,
                def: 1,
                xp: 20,
                sprite_index: spr_enemy_slime
            };
    }
}
