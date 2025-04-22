/// obj_player :: Create Event

// Persist this player across rooms
persistent = true;

// Only initialize these base stats once
if (!variable_instance_exists(id, "initialized")) {
    initialized = true;
    show_debug_message("!!! obj_player CREATE: First Time Initialization !!!");

    // ── Movement & world setup ──
    move_speed = 2;
    tilemap    = layer_tilemap_get_id("Tiles_Col"); // Ensure this layer exists in your room
    if (script_exists(scr_InitRoomMap)) scr_InitRoomMap();
    // Encounter table init moved to obj_init

    // ── Base stats ──
    hp_total   = 40;    hp   = hp_total;
    mp_total   = 20;    mp   = mp_total;
    atk        = 10;
    def        = 5;

    // Skills
    skills = [
        // Ensure these structs have all necessary properties (name, cost, effect, requires_target, damage/heal_amount etc.)
        { name: "Heal", cost: 5, effect: "heal_hp", requires_target: false, heal_amount: 25 },
        { name: "Fireball", cost: 6, effect: "damage_enemy", requires_target: true, damage: 18, element: "fire" }
    ];

    // ── Inventory ──
    inventory = [
        // Start with one of each item defined in scr_ItemDatabase
        { item_key: "potion", quantity: 1 },
        { item_key: "bomb", quantity: 1 },
        { item_key: "antidote", quantity: 1 }
        // Add more starting items if desired
    ];
    show_debug_message("  -> Player Inventory Initialized: " + string(inventory)); // Log initial items

    // ── Leveling ──
    level      = 1;
    xp         = 0;
    xp_require = 100;

    // Initialize the variable for the add_xp method here
    add_xp = function(_gain) {
        show_debug_message("--- add_xp Function START ---");
        show_debug_message("  Received _gain: " + string(_gain));
        if (!variable_instance_exists(id,"xp") || !variable_instance_exists(id,"xp_require") || !variable_instance_exists(id,"level")) { return; }
        if (!is_real(xp) || !is_real(_gain) || !is_real(xp_require)) { return; }
        show_debug_message("  XP Before Add: " + string(xp) + "/" + string(xp_require) + " | Level: " + string(level));
        xp += _gain;
        show_debug_message("  XP After Add: " + string(xp) + "/" + string(xp_require));
        var _levelled_up_this_call = false;
        while (xp >= xp_require) {
            _levelled_up_this_call = true;
            xp -= xp_require; level += 1; var _old_req = xp_require; xp_require = floor(xp_require * 1.4);
            hp_total += 5; mp_total += 3; atk += 1; def += 1;
            hp = hp_total; mp = mp_total;
            if (script_exists(scr_dialogue)) { create_dialog([{ name:"Level Up!", msg: "You reached level " + string(level) + "!\n" + "HP: " + string(hp_total) + "\n" + "MP: " + string(mp_total) + "\n" + "ATK: " + string(atk) + "\n" + "DEF: " + string(def) }]); }
        }
        if (_levelled_up_this_call) { show_debug_message("$$$ Finished Level Up Process! Current Level: " + string(level)); }
        else { show_debug_message("--- add_xp Function END (No level up occurred) ---"); }
    }

} // End if !initialized