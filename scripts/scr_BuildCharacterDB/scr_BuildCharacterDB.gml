/// @function scr_BuildCharacterDB()
/// @description Returns a DS Map containing base data for all playable characters.
/// Call this ONCE at game start (e.g., in obj_init) and store the result in a global variable.
function scr_BuildCharacterDB() {

    var _char_map = ds_map_create();

    // --- Define Characters Here ---
    // Use unique string keys (e.g., "hero", "claude", "gabriel", "izzy")

    // --- Player Character ("Hero") ---
    ds_map_add(_char_map, "hero", {
        name: "Hero", // Display name
        // Base Stats (Level 1 equivalents)
        hp_total: 40, mp_total: 20, atk: 10, def: 5,
        matk: 8, mdef: 4, spd: 7, luk: 5,
        // Starting Skills (Array of skill structs)
        skills: [
             { name: "Heal", cost: 5, effect: "heal_hp", requires_target: false, heal_amount: 25, power_stat: "matk" },
             { name: "Fireball", cost: 6, effect: "damage_enemy", requires_target: true, damage: 18, element: "fire", power_stat: "matk" },
             { name: "Blind", cost: 5, effect: "blind", duration: 3, requires_target: true },
             { name: "Shame", cost: 8, effect: "shame", duration: 3, requires_target: true },
             // Add more starting skills if needed
            ],
        // Battle Sprite
        battle_sprite: spr_player_battle // <<< Ensure this is the correct sprite asset name
    });

    // --- Recruitable Character ("Claude") ---
    ds_map_add(_char_map, "claude", {
        name: "Claude", // Display name
        // Base Stats (Level 1 equivalents)
        hp_total: 35, mp_total: 25, atk: 8, def: 4,
        matk: 12, mdef: 6, spd: 6, luk: 7,
        // Starting Skills
        skills: [
            { name: "Heal", cost: 5, effect: "heal_hp", requires_target: false, heal_amount: 25, power_stat: "matk" },
            { name: "Zap", cost: 4, effect: "damage_enemy", requires_target: true, damage: 15, element: "lightning", power_stat: "matk" },
            { name: "Bind", cost: 6, effect: "bind", duration: 3, requires_target: true }
            ],
        // Battle Sprite
        battle_sprite: spr_claude_battle // <<< Ensure this is the correct sprite asset name
    });

    // --- New Character: Gabby ("gabby") - Mage ---
    ds_map_add(_char_map, "gabby", {
        name: "Gabby", // Display name
        // Base Stats (Level 1 equivalents) - High MP/MATK, moderate SPD, lower ATK/DEF
        hp_total: 30, mp_total: 35, atk: 6, def: 3,
        matk: 15, mdef: 8, spd: 9, luk: 6,
        // Starting Skills (Placeholder spell keys - ensure these match your scr_BuildSpellDB)
        skills: [
             { name: "Fireball", cost: 6, effect: "damage_enemy", requires_target: true, damage: 18, element: "fire", power_stat: "matk" },
             { name: "Heal", cost: 5, effect: "heal_hp", requires_target: false, heal_amount: 25, power_stat: "matk" }, // Can also have healing spells
             // Add other starting mage skills here (e.g., Ice Lance, Thunder)
        ],
        // Battle Sprite (Placeholder)
        battle_sprite: spr_gabby_battle // <<< Create a sprite for Gabby and use its asset name!
    });

    // --- New Character: Izzy ("izzy") - Thief ---
    ds_map_add(_char_map, "izzy", {
        name: "Izzy", // Display name
        // Base Stats (Level 1 equivalents) - High SPD/LUK, moderate ATK, lower DEF/MDEF
        hp_total: 38, mp_total: 15, atk: 12, def: 6,
        matk: 5, mdef: 4, spd: 12, luk: 10,
        // Starting Skills (Placeholder - ensure these match your scr_BuildSpellDB or custom thief actions)
        skills: [
             { name: "Steal", cost: 0, effect: "steal_item", requires_target: true }, // Example Thief skill
             { name: "Quick Attack", cost: 3, effect: "damage_enemy", requires_target: true, damage: 10, power_stat: "atk" }, // Uses ATK
             // Add other starting thief skills here (e.g., Backstab, Smoke Bomb)
        ],
        // Battle Sprite (Placeholder)
        battle_sprite: spr_izzy_battle // <<< Create a sprite for Izzy and use its asset name!
    });


    show_debug_message("Character Database Initialized with " + string(ds_map_size(_char_map)) + " characters.");
    return _char_map;
}