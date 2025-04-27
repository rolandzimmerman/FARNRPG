/// @function scr_ItemDatabase()
/// @description Returns a DS Map containing definitions for all items in the game.
function scr_ItemDatabase() {
    var _item_map = ds_map_create();

    // --- CONSUMABLE ITEMS ---
    ds_map_add(_item_map, "potion", {
        item_key:         "potion", // <<< ADDED
        name:             "Potion",
        description:      "Restores 50 HP.",
        effect:           "heal_hp", value: 50, target: "ally",
        usable_in_battle: true, usable_in_field: true,
        sprite_index:     spr_item_food
    });
    ds_map_add(_item_map, "bomb", {
        item_key:         "bomb", // <<< ADDED
        name:             "Bomb",
        description:      "Deals 30 fire damage to one enemy.",
        effect:           "damage_enemy", value: 30, element: "fire", target: "enemy",
        usable_in_battle: true, usable_in_field: false,
        sprite_index:     spr_item_bomb
    });
    ds_map_add(_item_map, "antidote", {
        item_key:         "antidote", // <<< ADDED
        name:             "Antidote",
        description:      "Cures poison.",
        effect:           "cure_status", value: "poison", target: "ally",
        usable_in_battle: true, usable_in_field: true,
        sprite_index:     spr_item_antidote
    });

    // --- EQUIPMENT ITEMS ---
    ds_map_add(_item_map, "bronze_sword", {
        item_key:         "bronze_sword", // <<< ADDED
        name:             "Bronze Sword",
        description:      "A basic sword. +4 ATK.",
        type:             "equipment", equip_slot: "weapon",
        bonuses:          { atk:4, def:0, matk:0, mdef:0, spd:0, luk:0, hp_total:0, mp_total:0 },
        allowed_classes:  ["Hero"],
        usable_in_battle: false, usable_in_field:  false, sprite_index: spr_equipment_generic
    });
     ds_map_add(_item_map, "wooden_staff", {
        item_key:         "wooden_staff", // <<< ADDED
        name:             "Wooden Staff", description: "+4 MATK.",
        type:             "equipment", equip_slot: "weapon",
        bonuses:          { atk:0, def:0, matk:4, mdef:0, spd:0, luk:0, hp_total:0, mp_total:0 },
        allowed_classes:  ["Cleric", "Mage"],
        usable_in_battle: false, usable_in_field: false, sprite_index: spr_equipment_generic
     });
     ds_map_add(_item_map, "iron_dagger", {
        item_key:         "iron_dagger", // <<< ADDED
        name:             "Iron Dagger", description: "+3 ATK, +1 SPD.",
        type:             "equipment", equip_slot: "weapon",
        bonuses:          { atk:3, def:0, matk:0, mdef:0, spd:1, luk:0, hp_total:0, mp_total:0 },
        allowed_classes:  ["Hero", "Thief"],
        usable_in_battle: false, usable_in_field: false, sprite_index: spr_equipment_generic
     });
    ds_map_add(_item_map, "leather_armor", {
        item_key:         "leather_armor", // <<< ADDED
        name:             "Leather Armor", description: "+3 DEF.",
        type:             "equipment", equip_slot: "armor",
        bonuses:          { atk:0, def:3, matk:0, mdef:0, spd:0, luk:0, hp_total:0, mp_total:0 },
        allowed_classes:  [],
        usable_in_battle: false, usable_in_field: false, sprite_index: spr_equipment_generic
    });
     ds_map_add(_item_map, "thief_gloves", {
        item_key:         "thief_gloves", // <<< ADDED
        name:             "Thief Gloves", description: "+2 SPD, +2 LUK.",
        type:             "equipment", equip_slot: "accessory",
        bonuses:          { atk:0, def:0, matk:0, mdef:0, spd:2, luk:2, hp_total:0, mp_total:0 },
        allowed_classes:  ["Thief"],
        usable_in_battle: false, usable_in_field: false, sprite_index: spr_equipment_generic
     });
    ds_map_add(_item_map, "lucky_charm", {
        item_key:         "lucky_charm", // <<< ADDED
        name:             "Lucky Charm", description: "+5 LUK.",
        type:             "equipment", equip_slot: "accessory",
        bonuses:          { atk:0, def:0, matk:0, mdef:0, spd:0, luk:5, hp_total:0, mp_total:0 },
        // allowed_classes omitted = all
        usable_in_battle: false, usable_in_field: false, sprite_index: spr_equipment_generic
    });

    // ... Add definitions for ALL your items, ensuring each has an item_key field matching its map key ...

    show_debug_message("Item Database Initialized with " + string(ds_map_size(_item_map)) + " items.");
    return _item_map;
}