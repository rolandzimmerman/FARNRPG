/// @function scr_ItemDatabase()
/// @description Returns a DS Map containing definitions for all items in the game,
/// including equipment items with a `bonuses` struct for use in battle.
function scr_ItemDatabase() {
    var _item_map = ds_map_create();

    // ------------------------
    // CONSUMABLE ITEMS
    // ------------------------

    ds_map_add(_item_map, "potion", {
        name:             "Potion",
        description:      "Restores 50 HP.",
        effect:           "heal_hp",
        value:            50,
        target:           "ally",
        usable_in_battle: true,
        usable_in_field:  true,
        sprite_index:     spr_item_food
    });

    ds_map_add(_item_map, "bomb", {
        name:             "Bomb",
        description:      "Deals 30 fire damage to one enemy.",
        effect:           "damage_enemy",
        value:            30,
        element:          "fire",
        target:           "enemy",
        usable_in_battle: true,
        usable_in_field:  false,
        sprite_index:     spr_item_bomb
    });

    ds_map_add(_item_map, "antidote", {
        name:             "Antidote",
        description:      "Cures poison.",
        effect:           "cure_status",
        value:            "poison",
        target:           "ally",
        usable_in_battle: true,
        usable_in_field:  true,
        sprite_index:     spr_item_antidote
    });

    // ------------------------
    // EQUIPMENT ITEMS
    // ------------------------
    // All equipment now uses a `bonuses` sub-struct.

    ds_map_add(_item_map, "bronze_sword", {
        name:             "Bronze Sword",
        description:      "A basic sword. +4 ATK.",
        type:             "equipment",
        equip_slot:       "weapon",
        bonuses:          { atk:4, def:0, matk:0, mdef:0, spd:0, luk:0, hp_total:0, mp_total:0 },
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
        usable_in_battle: false,
        usable_in_field:  false,
        sprite_index:     spr_equipment_generic
    });

    // …add more equipment as needed…

    show_debug_message("Item Database Initialized with " + string(ds_map_size(_item_map)) + " items.");
    return _item_map;
}
