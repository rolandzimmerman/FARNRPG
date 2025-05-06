/// @function scr_ItemDatabase()
/// @description Returns a DS Map containing definitions for all items in the game.
function scr_ItemDatabase() {
    var _item_map = ds_map_create();
    
    // --- Define Default FX Assets (or override per‐item below) ---
    var default_item_fx_sprite = spr_item_effect_default;
    var default_item_fx_sound  = snd_item_use;
    var default_bomb_fx_sprite = spr_fx_fireball;
    var default_bomb_fx_sound  = snd_sfx_fire;
    var default_cure_fx_sprite = spr_fx_heal;
    var default_cure_fx_sound  = snd_sfx_heal;

    // --- CONSUMABLE ITEMS ---
    ds_map_add(_item_map, "potion", {
        item_key        : "potion", 
        name            : "Potion", 
        description     : "Restores 50 HP.",
        effect          : "heal_hp", 
        value           : 50,            // ← price in gold
        target          : "ally",
        usable_in_battle: true, 
        usable_in_field : true, 
        sprite_index    : spr_item_food,
        fx_sprite       : default_item_fx_sprite,
        fx_sound        : default_item_fx_sound
    });
    
    ds_map_add(_item_map, "bomb", {
        item_key        : "bomb", 
        name            : "Bomb", 
        description     : "Deals 30 fire damage to one enemy.",
        effect          : "damage_enemy", 
        value           : 80,
        element         : "fire", 
        target          : "enemy",
        usable_in_battle: true, 
        usable_in_field : false, 
        sprite_index    : spr_item_bomb,
        fx_sprite       : default_bomb_fx_sprite,
        fx_sound        : default_bomb_fx_sound
    });
    
    ds_map_add(_item_map, "antidote", {
        item_key        : "antidote", 
        name            : "Antidote", 
        description     : "Cures poison.",
        effect          : "cure_status", 
        value           : 40,
        target          : "ally",
        usable_in_battle: true, 
        usable_in_field : true, 
        sprite_index    : spr_item_antidote,
        fx_sprite       : default_cure_fx_sprite,
        fx_sound        : default_cure_fx_sound
    });

    // --- DEFAULT “UNARMED” ATTACK ---
    ds_map_add(_item_map, "unarmed", {
        item_key        : "unarmed", 
        name            : "Unarmed", 
        description     : "Basic fist attack.",
        type            : "equipment", 
        equip_slot      : "weapon",
        bonuses         : { atk:0, def:0, matk:0, mdef:0, spd:0, luk:0, hp_total:0, mp_total:0 },
        allowed_classes : [],
        usable_in_battle: false, 
        usable_in_field : false, 
        value           : 0,
        sprite_index    : -1,
        attack_sprite   : spr_pow, 
        attack_sound    : snd_punch,
        attack_element  : "physical"
    });

    // --- WEAPONS ---
    ds_map_add(_item_map, "bronze_sword", {
        item_key        : "bronze_sword", 
        name            : "Bronze Sword", 
        description     : "+4 ATK.",
        type            : "equipment", 
        equip_slot      : "weapon",
        bonuses         : { atk:4 },
        allowed_classes : ["Hero"],
        usable_in_battle: false, 
        usable_in_field : false, 
        value           : 120,
        sprite_index    : spr_equipment_generic,
        attack_sprite   : spr_slash, 
        attack_sound    : snd_punch,
        attack_element  : "physical"
    });
    
    ds_map_add(_item_map, "wooden_staff", {
        item_key        : "wooden_staff", 
        name            : "Wooden Staff", 
        description     : "+4 MATK.",
        type            : "equipment", 
        equip_slot      : "weapon",
        bonuses         : { matk:4 },
        allowed_classes : ["Cleric","Mage"],
        usable_in_battle: false, 
        usable_in_field : false, 
        value           : 140,
        sprite_index    : spr_equipment_generic,
        attack_sprite   : spr_pow, 
        attack_sound    : snd_punch,
        attack_element  : "physical"
    });

    ds_map_add(_item_map, "iron_dagger", {
        item_key        : "iron_dagger", 
        name            : "Iron Dagger", 
        description     : "+3 ATK, +1 SPD.",
        type            : "equipment", 
        equip_slot      : "weapon",
        bonuses         : { atk:3, spd:1 },
        allowed_classes : ["Hero","Thief"],
        usable_in_battle: false, 
        usable_in_field : false, 
        value           : 100,
        sprite_index    : spr_equipment_generic,
        attack_sprite   : spr_slash, 
        attack_sound    : snd_punch,
        attack_element  : "physical"
    });

    // --- ARMOR & ACCESSORIES ---
    ds_map_add(_item_map, "leather_armor", {
        item_key        : "leather_armor", 
        name            : "Leather Armor", 
        description     : "+3 DEF.",
        type            : "equipment", 
        equip_slot      : "armor",
        bonuses         : { def:3 },
        allowed_classes : [],
        usable_in_battle: false, 
        usable_in_field : false, 
        value           : 110,
        sprite_index    : spr_equipment_generic,
        resistances     : { physical:0.05 }
    });
    
    ds_map_add(_item_map, "thief_gloves", {
        item_key        : "thief_gloves", 
        name            : "Thief Gloves", 
        description     : "+2 SPD, +2 LUK.",
        type            : "equipment", 
        equip_slot      : "accessory",
        bonuses         : { spd:2, luk:2 },
        allowed_classes : ["Thief"],
        usable_in_battle: false, 
        usable_in_field : false, 
        value           : 90,
        sprite_index    : spr_equipment_generic
    });

    ds_map_add(_item_map, "lucky_charm", {
        item_key        : "lucky_charm", 
        name            : "Lucky Charm", 
        description     : "+5 LUK.",
        type            : "equipment", 
        equip_slot      : "accessory",
        bonuses         : { luk:5 },
        usable_in_battle: false, 
        usable_in_field : false, 
        value           : 80,
        sprite_index    : spr_equipment_generic
    });
    
    // …add any other items here with a `value` field…

    show_debug_message("Item Database Initialized with " 
        + string(ds_map_size(_item_map)) + " items."
    );
    return _item_map;
}
