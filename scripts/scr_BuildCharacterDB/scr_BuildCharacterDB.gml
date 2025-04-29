/// @function scr_BuildCharacterDB()
/// @description Returns a DS Map containing base data for all playable characters.
function scr_BuildCharacterDB() {
    var _char_map = ds_map_create();
    var base_resistances = { physical: 0, fire: 0, ice: 0, lightning: 0, poison: 0, holy: 0, dark: 0 }; 
    var base_equipment = { weapon: -4, offhand: -4, armor: -4, helm: -4, accessory: -4 };

    // --- Player Character ("Hero") ---
    ds_map_add(_char_map, "hero", {
        name: "Hero", class: "Hero",
        hp: 40, maxhp: 40, mp: 20, maxmp: 20, // Using hp/maxhp etc. directly
        atk: 10, def: 5, matk: 8, mdef: 4, spd: 7, luk: 5,
        level: 1, xp: 0, xp_require: 100, overdrive: 0, overdrive_max: 100, 
        skills: [ /* ... skills ... */ ],
        equipment: { weapon: "bronze_sword", offhand: -4, armor: "leather_armor", helm: -4, accessory: -4 }, 
        resistances: variable_clone(base_resistances, true), 
        character_key: "hero",
        battle_sprite: spr_player_battle, 
        attack_sprite: spr_player_attack // <<< ASSIGN ACTUAL SPRITE
    });

    // --- Recruitable Character ("Claude") ---
    ds_map_add(_char_map, "claude", {
        name: "Claude", class: "Cleric",
        hp: 35, maxhp: 35, mp: 25, maxmp: 25, 
        atk: 8, def: 4, matk: 12, mdef: 6, spd: 6, luk: 7,
        level: 1, xp: 0, xp_require: 100, overdrive: 0, overdrive_max: 100, 
        skills: [ /* ... skills ... */ ],
        equipment: { weapon: "iron_dagger", offhand: -4, armor: -4, helm: -4, accessory: -4 }, 
        resistances: { physical: 0.05, fire: -0.1, ice: 0.1, lightning: 0, poison: 0, holy: 0, dark: 0 }, 
        character_key: "claude",
        battle_sprite: spr_claude_battle,
        attack_sprite: spr_claude_attack // <<< ASSIGN ACTUAL SPRITE
    });

    // --- Gabby ("gabby") - Mage ---
    ds_map_add(_char_map, "gabby", {
        name: "Gabby", class: "Mage",
        hp: 30, maxhp: 30, mp: 35, maxmp: 35, 
        atk: 6, def: 3, matk: 15, mdef: 8, spd: 9, luk: 6,
        level: 1, xp: 0, xp_require: 100, overdrive: 0, overdrive_max: 100, 
        skills: [ /* ... skills ... */ ],
        equipment: { weapon: "wooden_staff", offhand: -4, armor: -4, helm: -4, accessory: "lucky_charm" }, 
        resistances: variable_clone(base_resistances, true), 
        character_key: "gabby",
        battle_sprite: spr_gabby_battle,
        attack_sprite: spr_gabby_attack // <<< ASSIGN ACTUAL SPRITE
    });

    // --- Izzy ("izzy") - Thief ---
    ds_map_add(_char_map, "izzy", {
        name: "Izzy", class: "Thief",
        hp: 38, maxhp: 38, mp: 15, maxmp: 15, 
        atk: 12, def: 6, matk: 5, mdef: 4, spd: 12, luk: 10,
        level: 1, xp: 0, xp_require: 100, overdrive: 0, overdrive_max: 100, 
        skills: [ /* ... skills ... */ ],
        equipment: { weapon: "iron_dagger", offhand: -4, armor: -4, helm: -4, accessory: "thief_gloves" }, 
        resistances: variable_clone(base_resistances, true), 
        character_key: "izzy",
        battle_sprite: spr_izzy_battle,
        attack_sprite: spr_izzy_attack // <<< ASSIGN ACTUAL SPRITE
    });

    show_debug_message("Character Database Initialized with " + string(ds_map_size(_char_map)) + " characters.");
    return _char_map;
}