/// @function scr_BuildCharacterDB()
/// @description Returns a DS Map containing base data for all playable characters.
function scr_BuildCharacterDB() {
    var _char_map = ds_map_create();
    // Define base nested structures for consistency
    var base_resistances = { physical: 0, fire: 0, ice: 0, lightning: 0, poison: 0, holy: 0, dark: 0 }; 
    var base_equipment = { weapon: noone, offhand: noone, armor: noone, helm: noone, accessory: noone }; 

    // --- Player Character ("Hero") ---
    ds_map_add(_char_map, "hero", {
        name: "Hero", class: "Hero",
        // Using consistent stat names matching persistent map
        hp: 40, maxhp: 40, mp: 20, maxmp: 20, 
        atk: 10, def: 5, matk: 8, mdef: 4, spd: 7, luk: 5,
        level: 1, xp: 0, xp_require: 100, overdrive: 0, overdrive_max: 100, 
        skills: [ 
            { name: "Heal", cost: 5, effect: "heal_hp", requires_target: false, heal_amount: 25, power_stat: "matk" },
            { name: "Fireball", cost: 6, effect: "damage_enemy", requires_target: true, damage: 18, element: "fire", power_stat: "matk" },
            { name: "Blind", cost: 5, effect: "blind", duration: 3, requires_target: true },
            { name: "Shame", cost: 8, effect: "shame", duration: 3, requires_target: true }, // <<< ADDED COMMA HERE
        ], 
        equipment: { weapon: "bronze_sword", offhand: noone, armor: "leather_armor", helm: noone, accessory: noone }, 
        resistances: variable_clone(base_resistances, true), 
        character_key: "hero",
        battle_sprite: spr_player_battle, 
        attack_sprite: spr_player_attack 
    });

    // --- Recruitable Character ("Claude") ---
    ds_map_add(_char_map, "claude", {
        name: "Claude", class: "Cleric",
        hp: 35, maxhp: 35, mp: 25, maxmp: 25, 
        atk: 8, def: 4, matk: 12, mdef: 6, spd: 6, luk: 7,
        level: 1, xp: 0, xp_require: 100, overdrive: 0, overdrive_max: 100, 
        skills: [ 
             { name: "Heal", cost: 5, effect: "heal_hp", requires_target: false, heal_amount: 25, power_stat: "matk" },
             { name: "Zap", cost: 4, effect: "damage_enemy", requires_target: true, damage: 15, element: "lightning", power_stat: "matk" },
             { name: "Bind", cost: 6, effect: "bind", duration: 3, requires_target: true }, // Added comma for consistency
        ], 
        equipment: { weapon: "iron_dagger", offhand: noone, armor: noone, helm: noone, accessory: noone }, 
        resistances: { physical: 0.05, fire: -0.1, ice: 0.1, lightning: 0, poison: 0, holy: 0, dark: 0 }, 
        character_key: "claude",
        battle_sprite: spr_claude_battle,
        attack_sprite: spr_claude_attack 
    });

    // --- Gabby ("gabby") - Mage ---
    ds_map_add(_char_map, "gabby", {
        name: "Gabby", class: "Mage",
        hp: 30, maxhp: 30, mp: 35, maxmp: 35, 
        atk: 6, def: 3, matk: 15, mdef: 8, spd: 9, luk: 6,
        level: 1, xp: 0, xp_require: 100, overdrive: 0, overdrive_max: 100, 
        skills: [ 
            { name: "Fireball", cost: 6, effect: "damage_enemy", requires_target: true, damage: 18, element: "fire", power_stat: "matk" },
            { name: "Heal", cost: 5, effect: "heal_hp", requires_target: false, heal_amount: 25, power_stat: "matk" }, // Added comma for consistency
        ], 
        equipment: { weapon: "wooden_staff", offhand: noone, armor: noone, helm: noone, accessory: "lucky_charm" }, 
        resistances: variable_clone(base_resistances, true), 
        character_key: "gabby",
        battle_sprite: spr_gabby_battle, 
        attack_sprite: spr_gabby_attack 
    });

    // --- Izzy ("izzy") - Thief ---
    ds_map_add(_char_map, "izzy", {
        name: "Izzy", class: "Thief",
        hp: 38, maxhp: 38, mp: 15, maxmp: 15, 
        atk: 12, def: 6, matk: 5, mdef: 4, spd: 12, luk: 10,
        level: 1, xp: 0, xp_require: 100, overdrive: 0, overdrive_max: 100, 
        skills: [ 
            { name: "Steal", cost: 0, effect: "steal_item", requires_target: true }, 
            { name: "Quick Attack", cost: 3, effect: "damage_enemy", requires_target: true, damage: 10, element: "physical", power_stat: "atk" }, // Added comma for consistency
        ], 
        equipment: { weapon: "iron_dagger", offhand: noone, armor: noone, helm: noone, accessory: "thief_gloves" }, 
        resistances: variable_clone(base_resistances, true), 
        character_key: "izzy",
        battle_sprite: spr_izzy_battle, 
        attack_sprite: spr_izzy_attack 
    });

    show_debug_message("Character Database Initialized with " + string(ds_map_size(_char_map)) + " characters.");
    return _char_map;
}