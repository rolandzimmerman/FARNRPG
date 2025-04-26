/// @function scr_ItemDatabase()
/// @description Returns a DS Map containing definitions for all items in the game.
///              Equipment includes `bonuses` struct and optional `allowed_classes` array.
function scr_ItemDatabase() {
    var _item_map = ds_map_create();

    // --- CONSUMABLE ITEMS ---
    ds_map_add(_item_map, "potion", {
        name:             "Potion",
        description:      "Restores 50 HP.",
        effect:           "heal_hp", value: 50, target: "ally",
        usable_in_battle: true, usable_in_field: true,
        sprite_index:     spr_item_food // Example sprite
    });
    ds_map_add(_item_map, "bomb", {
        name:             "Bomb",
        description:      "Deals 30 fire damage to one enemy.",
        effect:           "damage_enemy", value: 30, element: "fire", target: "enemy",
        usable_in_battle: true, usable_in_field: false,
        sprite_index:     spr_item_bomb // Example sprite
    });
    ds_map_add(_item_map, "antidote", {
        name:             "Antidote",
        description:      "Cures poison.",
        effect:           "cure_status", value: "poison", target: "ally",
        usable_in_battle: true, usable_in_field: true,
        sprite_index:     spr_item_antidote // Example sprite
    });

    // --- EQUIPMENT ITEMS ---
    ds_map_add(_item_map, "bronze_sword", {
        name:             "Bronze Sword",
        description:      "A basic sword. +4 ATK.",
        type:             "equipment",        // REQUIRED
        equip_slot:       "weapon",           // REQUIRED
        bonuses:          { atk:4, def:0, matk:0, mdef:0, spd:0, luk:0, hp_total:0, mp_total:0 },
        allowed_classes:  ["Hero"],      // <<< ADDED/RESTORED: Only Hero can use
        usable_in_battle: false,
        usable_in_field:  false,
        sprite_index:     spr_equipment_generic // Example sprite
    });

     ds_map_add(_item_map, "wooden_staff", { // Example new item
         name:             "Wooden Staff",
         description:      "A simple staff. +4 MATK.",
         type:             "equipment",
         equip_slot:       "weapon",
         bonuses:          { atk:0, def:0, matk:4, mdef:0, spd:0, luk:0, hp_total:0, mp_total:0 },
         allowed_classes:  ["Cleric", "Mage"], // <<< ADDED: Example - Cleric & Mage only
         usable_in_battle: false,
         usable_in_field:  false,
         sprite_index:     spr_equipment_generic
     });

     ds_map_add(_item_map, "iron_dagger", { // Example new item
         name:             "Iron Dagger",
         description:      "Quick and sharp. +3 ATK, +1 SPD.",
         type:             "equipment",
         equip_slot:       "weapon", // Or "offhand"
         bonuses:          { atk:3, def:0, matk:0, mdef:0, spd:1, luk:0, hp_total:0, mp_total:0 },
         allowed_classes:  ["Hero", "Thief"], // <<< ADDED: Example - Hero & Thief only
         usable_in_battle: false,
         usable_in_field:  false,
         sprite_index:     spr_equipment_generic
     });

    ds_map_add(_item_map, "leather_armor", {
        name:             "Leather Armor",
        description:      "Simple armor. +3 DEF.",
        type:             "equipment",
        equip_slot:       "armor",
        bonuses:          { atk:0, def:3, matk:0, mdef:0, spd:0, luk:0, hp_total:0, mp_total:0 },
        allowed_classes:  [], // <<< ADDED/RESTORED: Empty array = ALL classes
        usable_in_battle: false,
        usable_in_field:  false,
        sprite_index:     spr_equipment_generic
    });

     ds_map_add(_item_map, "thief_gloves", { // Example new item
         name:             "Thief Gloves",
         description:      "Improves dexterity. +2 SPD, +2 LUK.",
         type:             "equipment",
         equip_slot:       "accessory",
         bonuses:          { atk:0, def:0, matk:0, mdef:0, spd:2, luk:2, hp_total:0, mp_total:0 },
         allowed_classes:  ["Thief"], // <<< ADDED: Example - Thief only
         usable_in_battle: false,
         usable_in_field:  false,
         sprite_index:     spr_equipment_generic
     });

    ds_map_add(_item_map, "lucky_charm", {
        name:             "Lucky Charm",
        description:      "Increases LUK by 5.",
        type:             "equipment",
        equip_slot:       "accessory",
        bonuses:          { atk:0, def:0, matk:0, mdef:0, spd:0, luk:5, hp_total:0, mp_total:0 },
        // allowed_classes field omitted = ALL classes
        usable_in_battle: false,
        usable_in_field:  false,
        sprite_index:     spr_equipment_generic
    });

    // ... Add ALL your equipment with `type`, `equip_slot`, `bonuses`, and `allowed_classes` ...

    show_debug_message("Item Database Initialized with " + string(ds_map_size(_item_map)) + " items.");
    return _item_map;
}