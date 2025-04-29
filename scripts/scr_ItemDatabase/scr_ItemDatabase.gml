/// @function scr_ItemDatabase()
/// @description Returns a DS Map containing definitions for all items in the game.
function scr_ItemDatabase() {
    var _item_map = ds_map_create();

    // --- CONSUMABLE ITEMS ---
    ds_map_add(_item_map, "potion", {
        item_key: "potion", name: "Potion", description: "Restores 50 HP.",
        effect: "heal_hp", value: 50, target: "ally",
        usable_in_battle: true, usable_in_field: true, sprite_index: spr_item_food
    });
    ds_map_add(_item_map, "bomb", {
        item_key: "bomb", name: "Bomb", description: "Deals 30 fire damage to one enemy.",
        effect: "damage_enemy", value: 30, element: "fire", target: "enemy", 
        usable_in_battle: true, usable_in_field: false, sprite_index: spr_item_bomb
    });
    ds_map_add(_item_map, "antidote", {
        item_key: "antidote", name: "Antidote", description: "Cures poison.",
        effect: "cure_status", value: "poison", target: "ally",
        usable_in_battle: true, usable_in_field: true, sprite_index: spr_item_antidote
    });

    // --- EQUIPMENT ITEMS ---

    // <<< NEW: Unarmed Default >>>
    ds_map_add(_item_map, "unarmed", {
        item_key: "unarmed", name: "Unarmed", description: "Basic fist attack.",
        type: "equipment", equip_slot: "weapon", // Technically weapon slot for FX lookup
        bonuses: { atk:0, def:0, matk:0, mdef:0, spd:0, luk:0, hp_total:0, mp_total:0 }, // No stat bonuses
        allowed_classes: [], // Anyone can be unarmed
        usable_in_battle: false, usable_in_field: false, sprite_index: -1, // No inventory sprite needed
        // --- Default Attack FX ---
        attack_sprite: spr_pow,     // <<< Use your desired default punch/hit sprite
        attack_sound: snd_punch,   // <<< Use your desired default punch/hit sound
        attack_element: "physical"
    });
    // <<< END NEW >>>

    // -- Weapons --
    ds_map_add(_item_map, "bronze_sword", {
        item_key: "bronze_sword", name: "Bronze Sword", description: "A basic sword. +4 ATK.",
        type: "equipment", equip_slot: "weapon",
        bonuses: { atk:4 }, // Only list non-zero bonuses
        allowed_classes: ["Hero"],
        usable_in_battle: false, usable_in_field: false, sprite_index: spr_equipment_generic, // Assign specific icon if you have one
        attack_sprite: spr_slash,   // <<< EXAMPLE: Use a slash sprite
        attack_sound: snd_punch,    // <<< EXAMPLE: Use a sword sound
        attack_element: "physical" 
    });
     ds_map_add(_item_map, "wooden_staff", {
        item_key: "wooden_staff", name: "Wooden Staff", description: "+4 MATK.",
        type: "equipment", equip_slot: "weapon",
        bonuses: { matk:4 },
        allowed_classes: ["Cleric", "Mage"],
        usable_in_battle: false, usable_in_field: false, sprite_index: spr_equipment_generic,
        attack_sprite: spr_pow,    // Staff might just use a generic hit/pow
        attack_sound: snd_punch,   // Or a 'whack' sound
        attack_element: "physical"  // Whacking is physical
     });
     ds_map_add(_item_map, "iron_dagger", {
        item_key: "iron_dagger", name: "Iron Dagger", description: "+3 ATK, +1 SPD.",
        type: "equipment", equip_slot: "weapon",
        bonuses: { atk:3, spd:1 },
        allowed_classes: ["Hero", "Thief"],
        usable_in_battle: false, usable_in_field: false, sprite_index: spr_equipment_generic,
        attack_sprite: spr_slash,    // <<< EXAMPLE: Use a slash sprite
        attack_sound: snd_punch,    // <<< EXAMPLE: Use a dagger sound
        attack_element: "physical"
     });

     // -- Armor/Accessories --
    ds_map_add(_item_map, "leather_armor", {
        item_key: "leather_armor", name: "Leather Armor", description: "+3 DEF.",
        type: "equipment", equip_slot: "armor",
        bonuses: { def:3 },
        allowed_classes: [],
        usable_in_battle: false, usable_in_field: false, sprite_index: spr_equipment_generic,
        resistances: { physical: 0.05 } // 5% physical resistance
    });
     ds_map_add(_item_map, "thief_gloves", {
        item_key: "thief_gloves", name: "Thief Gloves", description: "+2 SPD, +2 LUK.",
        type: "equipment", equip_slot: "accessory",
        bonuses: { spd:2, luk:2 },
        allowed_classes: ["Thief"],
        usable_in_battle: false, usable_in_field: false, sprite_index: spr_equipment_generic
     });
    ds_map_add(_item_map, "lucky_charm", {
        item_key: "lucky_charm", name: "Lucky Charm", description: "+5 LUK.",
        type: "equipment", equip_slot: "accessory",
        bonuses: { luk:5 },
        // allowed_classes omitted = all
        usable_in_battle: false, usable_in_field: false, sprite_index: spr_equipment_generic
     });
    
    // ... Add definitions for ALL your items ...

    show_debug_message("Item Database Initialized with " + string(ds_map_size(_item_map)) + " items.");
    return _item_map;
}