/// @function scr_BuildCharacterDB()
/// @description Returns a DS Map containing base data for all playable characters.
function scr_BuildCharacterDB() {
    var _char_map = ds_map_create();
    // Define base nested structures for consistency
    var base_resistances = { physical: 0, fire: 0, ice: 0, lightning: 0, poison: 0, holy: 0, dark: 0 }; 
    var base_equipment = { weapon: noone, offhand: noone, armor: noone, helm: noone, accessory: noone }; 

    // Default FX (Replace with your actual assets)
    var default_heal_fx = spr_pow ?? spr_pow; 
    var default_heal_snd = snd_punch ?? snd_punch;
    var default_damage_fx = spr_pow ?? spr_pow;
    var default_damage_snd = snd_punch ?? snd_punch;
    var default_status_fx = spr_pow ?? spr_pow;
    var default_status_snd = snd_punch ?? snd_punch;
    var default_overdrive_fx = spr_pow ?? spr_pow;
    var default_overdrive_snd = snd_punch ?? snd_punch;
    var default_slash_fx = spr_slash ?? spr_pow;


    // --- Player Character ("Hero") ---
    ds_map_add(_char_map, "hero", {
        name: "Hero", class: "Hero",
        hp: 40, maxhp: 40, mp: 20, maxmp: 20, 
        atk: 10, def: 5, matk: 8, mdef: 4, spd: 7, luk: 5,
        level: 1, xp: 0, xp_require: 100, overdrive: 0, overdrive_max: 100, 
        skills: [ 
            { name: "Heal", cost: 5, effect: "heal_hp", target_type: "ally", heal_amount: 25, power_stat: "matk", fx_sprite: default_heal_fx, fx_sound: default_heal_snd }, 
            { name: "Fireball", cost: 6, effect: "damage_enemy", target_type: "enemy", damage: 18, element: "fire", power_stat: "matk", fx_sprite: spr_pow ?? default_damage_fx, fx_sound: snd_punch ?? default_damage_snd }, 
            { name: "Blind", cost: 5, effect: "blind", target_type: "enemy", duration: 3, fx_sprite: default_status_fx, fx_sound: default_status_snd }, 
            { name: "Shame", cost: 8, effect: "shame", target_type: "enemy", duration: 3, fx_sprite: default_status_fx, fx_sound: default_status_snd }, 
        ], // Added trailing comma previously
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
             { name: "Heal", cost: 5, effect: "heal_hp", target_type: "ally", heal_amount: 25, power_stat: "matk", fx_sprite: default_heal_fx, fx_sound: default_heal_snd }, 
             { name: "Zap", cost: 4, effect: "damage_enemy", target_type: "enemy", damage: 15, element: "lightning", power_stat: "matk", fx_sprite: default_damage_fx, fx_sound: default_damage_snd }, 
             { name: "Bind", cost: 6, effect: "bind", target_type: "enemy", duration: 3, fx_sprite: default_status_fx, fx_sound: default_status_snd }, 
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
            { name: "Fireball", cost: 6, effect: "damage_enemy", target_type: "enemy", damage: 18, element: "fire", power_stat: "matk", fx_sprite: spr_pow ?? default_damage_fx, fx_sound: snd_punch ?? default_damage_snd }, 
            { name: "Heal", cost: 5, effect: "heal_hp", target_type: "ally", heal_amount: 25, power_stat: "matk", fx_sprite: default_heal_fx, fx_sound: default_heal_snd }, 
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
            { name: "Steal", cost: 0, effect: "steal_item", target_type: "enemy", fx_sprite: default_status_fx, fx_sound: default_status_snd }, 
            { name: "Quick Attack", cost: 3, effect: "damage_enemy", target_type: "enemy", damage: 10, element: "physical", power_stat: "atk", fx_sprite: default_slash_fx, fx_sound: snd_punch }, 
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