/// obj_player :: Create Event

// Persist this player across rooms
persistent = true;

// Only initialize these base stats once
if (!variable_instance_exists(id, "initialized")) {
    initialized = true;
    show_debug_message("!!! obj_player CREATE: First Time Initialization !!!");

    // --- Add self to the global party list ---
    if (variable_global_exists("party_members")) {
        if (is_array(global.party_members)) {
            array_push(global.party_members, "hero");
            show_debug_message("  -> Added 'hero' to global.party_members. Current Party: " + string(global.party_members));
        } else { /* Error */ }
    } else { show_debug_message("  -> WARNING: global.party_members array not found! Cannot add player to party."); }
    // --- End Add Self to Party ---


    // ── Movement & world setup ──
    move_speed = 2;
    tilemap    = layer_tilemap_get_id("Tiles_Col");
    show_debug_message("  -> Initialized 'tilemap' variable with ID: " + string(tilemap));
    if (script_exists(scr_InitRoomMap)) scr_InitRoomMap();


    // ── Base stats (These are the persistent stats) ──
    hp_total   = 40;    hp   = hp_total;
    mp_total   = 20;    mp   = mp_total;
    atk        = 10;    def  = 5;
    matk       = 8;     mdef = 4;
    spd        = 7;     luk  = 5;

    // Skills (These are the persistent skills known by the player)
    skills = [
        { name: "Heal", cost: 5, effect: "heal_hp", requires_target: false, heal_amount: 25, power_stat: "matk" },
        { name: "Fireball", cost: 6, effect: "damage_enemy", requires_target: true, damage: 18, element: "fire", power_stat: "matk" }
    ];

    // ── Inventory ──
    inventory = [ { item_key: "potion", quantity: 1 }, { item_key: "bomb", quantity: 1 }, { item_key: "antidote", quantity: 1 } ];
    show_debug_message("  -> Player Inventory Initialized.");

    // ── Leveling ──
    level      = 1;
    xp         = 0;
    // Use the function to get initial requirement
    // Ensure scr_LevelingSystem script runs before this object if GetXPForLevel is needed here
    xp_require = (script_exists(scr_GetXPForLevel)) ? scr_GetXPForLevel(level + 1) : 100;


    // --- REMOVED old add_xp function ---
    // add_xp = function(_gain) { /* ... Old Level up logic ... */ };

} // End if !initialized