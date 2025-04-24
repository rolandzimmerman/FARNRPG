/// @function scr_BuildCharacterDB()
/// @description Returns a DS Map containing base data for all playable characters.
/// Call this ONCE at game start (e.g., in obj_init) and store the result in a global variable.
function scr_BuildCharacterDB() {

    var _char_map = ds_map_create();

    // --- Define Characters Here ---
    // Use unique string keys (e.g., "hero", "claude")

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
             { name: "Blind", cost: 5, effect: "blind",  duration: 3, requires_target: true },
             { name: "Shame", cost: 8, effect: "shame",  duration: 3, requires_target: true },
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
            { name: "Bind",  cost: 6, effect: "bind",   duration: 3, requires_target: true }
             ],
        // Battle Sprite
        battle_sprite: spr_claude_battle // <<< Ensure this is the correct sprite asset name
    });

    // --- Add definitions for other potential party members ---


    show_debug_message("Character Database Initialized with " + string(ds_map_size(_char_map)) + " characters.");
    return _char_map;
}