/// obj_player :: Create Event

// Persist this player across rooms
persistent = true;

// Only initialize these base stats once
if (!variable_instance_exists(id, "initialized")) {
    initialized = true;
    show_debug_message("!!! obj_player CREATE: First Time Initialization !!!");

    // --- Add self to the global party list ---
    // SAFETY CHECK: Ensure the list exists before trying to add to it.
    // The root cause is likely obj_init running AFTER obj_player, fix creation order in Room1.
    if (variable_global_exists("party_members")) {
        if (is_array(global.party_members)) {
            // Add the key corresponding to this player character in the database
            array_push(global.party_members, "hero"); // Add "hero" key
            show_debug_message("  -> Added 'hero' to global.party_members. Current Party: " + string(global.party_members));
        } else {
             show_debug_message("  -> ERROR: global.party_members exists but is not an array!");
             // Force creation if it's wrong type? Risky.
             // global.party_members = ["hero"];
        }
    } else {
        show_debug_message("  -> WARNING: global.party_members array not found! Cannot add player to party. (Check obj_init creation order in Room1)");
        // Don't create it here, let obj_init handle it.
    }
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

    // Skills
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
    xp_require = 100;

    // Initialize the variable for the add_xp method here
    add_xp = function(_gain) {/*
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
            hp_total += 5; mp_total += 3; atk += 1; def += 1; matk += 2; mdef += 1; spd += 1; luk += 1;
            hp = hp_total; mp = mp_total;
            if (script_exists(scr_dialogue)) { create_dialog([{ name:"Level Up!", msg: "Reached level " + string(level) + "!\n" + "HP: " + string(hp_total) + " | MP: " + string(mp_total) + "\n" + "ATK: " + string(atk) + " | DEF: " + string(def) + "\n" + "MATK: "+ string(matk)+ " | MDEF: "+ string(mdef)+ "\n" + "SPD: " + string(spd) + " | LUK: " + string(luk) }]); }
        }
        if (_levelled_up_this_call) { show_debug_message("$$$ Finished Level Up Process! Current Level: " + string(level)); }
        else { show_debug_message("--- add_xp Function END (No level up occurred) ---"); }
    */}

} // End if !initialized