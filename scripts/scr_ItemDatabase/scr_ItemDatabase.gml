/// @function scr_ItemDatabase()
/// @description Returns a DS Map containing definitions for all items in the game.
/// Call this ONCE at game start (e.g., in obj_init) and store the result in a global variable.
function scr_ItemDatabase() {

    var _item_map = ds_map_create();

    // --- Define Items Here ---
    // Use unique string keys for each item

    // Example: Potion
    ds_map_add(_item_map, "potion", {
        name: "Potion",
        description: "Restores 50 HP.",
        effect: "heal_hp", // Custom identifier for the effect
        value: 50,         // Amount of HP to restore
        target: "ally",    // Can target self or allies (currently just self)
        usable_in_battle: true,
        usable_in_field: true,
        sprite_index: spr_item_potion // <<< ADD a sprite for the item!
    });

    // Example: Bomb
    ds_map_add(_item_map, "bomb", {
        name: "Bomb",
        description: "Deals 30 fire damage to one enemy.",
        effect: "damage_enemy",
        value: 30,
        element: "fire", // Optional: element type
        target: "enemy",
        usable_in_battle: true,
        usable_in_field: false,
        sprite_index: spr_item_bomb // <<< ADD a sprite for the item!
    });

    // Example: Antidote
    ds_map_add(_item_map, "antidote", {
        name: "Antidote",
        description: "Cures poison.",
        effect: "cure_status",
        value: "poison", // Status effect to cure
        target: "ally",
        usable_in_battle: true,
        usable_in_field: true,
        sprite_index: spr_item_antidote // <<< ADD a sprite for the item!
    });

    // --- Add more items as needed ---


    show_debug_message("Item Database Initialized with " + string(ds_map_size(_item_map)) + " items.");
    return _item_map;
}

/// @function scr_GetItemData(_item_key)
/// @description Safely retrieves the data struct for a given item key from the global database.
/// @param {string} _item_key The unique key of the item (e.g., "potion").
/// @returns {Struct} The item data struct, or undefined if not found.
function scr_GetItemData(_item_key) {
    if (!variable_global_exists("item_database") || !ds_exists(global.item_database, ds_type_map)) {
        show_debug_message("ERROR: Global item database not initialized!");
        return undefined;
    }
    var _data = ds_map_find_value(global.item_database, _item_key);
    if (is_undefined(_data)) { // GMS uses undefined for missing map keys
         show_debug_message("WARNING: Item key '" + string(_item_key) + "' not found in database.");
         return undefined;
    }
    // Optional: Return a *copy* if you want to prevent accidental modification of the database entry
    // return struct_clone(_data);
    return _data;
}