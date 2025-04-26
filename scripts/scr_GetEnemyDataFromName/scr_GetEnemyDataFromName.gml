/// @function scr_GetEnemyDataFromName(_obj)
/// @description Returns a data struct for a given enemy object type.
function scr_GetEnemyDataFromName(_obj) {
    switch (_obj) {
        case obj_enemy_goblin:
            return {
                name: "Nut Thief Chief", hp: 30, maxhp: 30,
                atk: 6, def: 2, matk: 1, mdef: 1, spd: 5, luk: 3, // Added stats
                xp: 50, sprite_index: spr_enemy_goblin, status: "none"
            };
        case obj_enemy_slime:
            return {
                name: "Slime", hp: 20, maxhp: 20,
                atk: 4, def: 1, matk: 3, mdef: 5, spd: 3, luk: 1, // Added stats
                xp: 30, sprite_index: spr_enemy_slime, status: "none"
            };
        case obj_enemy_nut_thief:
            return {
                name: "Nut Thief", hp: 20, maxhp: 20,
                atk: 4, def: 1, matk: 3, mdef: 5, spd: 3, luk: 1, // Added stats
                xp: 30, sprite_index: spr_enemy_nut_thief_2, status: "none"
            };
        // Add other enemies...
        default:
            return {
                name: "???", hp: 10, maxhp: 10,
                atk: 2, def: 1, matk: 1, mdef: 1, spd: 1, luk: 1, // Added stats
                xp: 5, sprite_index: spr_enemy_slime, status: "none"
            };
    }
}