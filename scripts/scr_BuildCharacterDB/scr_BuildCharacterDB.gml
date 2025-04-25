/// @function scr_BuildCharacterDB()
/// @description Returns a DS Map containing base data for all playable characters.
/// Call this ONCE at game start (e.g., in obj_init) and store the result in a global variable.

function scr_BuildCharacterDB() {
    var _char_map = ds_map_create();

    // --- Player Character ("Hero") ---
    ds_map_add(_char_map, "hero", {
        name: "Hero",
        class: "Hero",
        hp_total: 40, mp_total: 20, atk: 10, def: 5,
        matk: 8, mdef: 4, spd: 7, luk: 5,
        skills: [
            { name: "Heal", cost: 5, effect: "heal_hp", requires_target: false, heal_amount: 25, power_stat: "matk" },
            { name: "Fireball", cost: 6, effect: "damage_enemy", requires_target: true, damage: 18, element: "fire", power_stat: "matk" },
            { name: "Blind", cost: 5, effect: "blind", duration: 3, requires_target: true },
            { name: "Shame", cost: 8, effect: "shame", duration: 3, requires_target: true }
        ],
        battle_sprite: spr_player_battle
    });

    // --- Recruitable Character ("Claude") ---
    ds_map_add(_char_map, "claude", {
        name: "Claude",
        class: "Cleric",
        hp_total: 35, mp_total: 25, atk: 8, def: 4,
        matk: 12, mdef: 6, spd: 6, luk: 7,
        skills: [
            { name: "Heal", cost: 5, effect: "heal_hp", requires_target: false, heal_amount: 25, power_stat: "matk" },
            { name: "Zap", cost: 4, effect: "damage_enemy", requires_target: true, damage: 15, element: "lightning", power_stat: "matk" },
            { name: "Bind", cost: 6, effect: "bind", duration: 3, requires_target: true }
        ],
        battle_sprite: spr_claude_battle
    });

    // --- New Character: Gabby ("gabby") - Mage ---
    ds_map_add(_char_map, "gabby", {
        name: "Gabby",
        class: "Mage",
        hp_total: 30, mp_total: 35, atk: 6, def: 3,
        matk: 15, mdef: 8, spd: 9, luk: 6,
        skills: [
            { name: "Fireball", cost: 6, effect: "damage_enemy", requires_target: true, damage: 18, element: "fire", power_stat: "matk" },
            { name: "Heal", cost: 5, effect: "heal_hp", requires_target: false, heal_amount: 25, power_stat: "matk" }
        ],
        battle_sprite: spr_gabby_battle
    });

    // --- New Character: Izzy ("izzy") - Thief ---
    ds_map_add(_char_map, "izzy", {
        name: "Izzy",
        class: "Thief",
        hp_total: 38, mp_total: 15, atk: 12, def: 6,
        matk: 5, mdef: 4, spd: 12, luk: 10,
        skills: [
            { name: "Steal", cost: 0, effect: "steal_item", requires_target: true },
            { name: "Quick Attack", cost: 3, effect: "damage_enemy", requires_target: true, damage: 10, power_stat: "atk" }
        ],
        battle_sprite: spr_izzy_battle
    });

    show_debug_message("Character Database Initialized with " + string(ds_map_size(_char_map)) + " characters.");
    return _char_map;
}
