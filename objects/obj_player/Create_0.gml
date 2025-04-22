/// obj_player :: Create Event

// Persist this player across rooms
persistent = true;

// Only initialize these base stats once
if (!variable_instance_exists(id, "initialized")) {
    initialized = true;
    show_debug_message("!!! obj_player CREATE: First Time Initialization !!!"); // DEBUG

    // ── Movement & world setup ──
    move_speed = 2;
    tilemap    = layer_tilemap_get_id("Tiles_Col"); // Ensure this layer exists
    if (script_exists(scr_InitRoomMap)) scr_InitRoomMap();
    if (script_exists(scr_InitEncounterTable)) scr_InitEncounterTable();

    // ── Base stats ──
    hp_total   = 40;    hp   = hp_total;
    mp_total   = 20;    mp   = mp_total;
    atk        = 10;
    def        = 5;
    // skills array defined here... (Make sure skill structs have required properties)
    skills = [
        { name: "Heal", cost: 5, effect: "heal", requires_target: false, heal_amount: 25 },
        { name: "Fireball", cost: 6, effect: "fire", requires_target: true, damage: 18 } // Added 'damage' property example
        // Add other skill structs here
    ];
    skill_index = 0; // No longer needed here if using obj_battle_player.data
    is_defending = false; // No longer needed here if using obj_battle_player.data

    // ── Leveling ──
    level      = 1;
    xp         = 0;
    xp_require = 100; // XP needed for level 2
    // xp_require = 20; // Use this for quick level up testing

    // Initialize the variable for the add_xp method here
    add_xp = function(_gain) { // Assign the function to the instance variable

        // --- DETAILED XP/LEVEL LOGGING ---
        show_debug_message("--- add_xp Function START ---");
        show_debug_message("  Received _gain: " + string(_gain));
        if (!variable_instance_exists(id,"xp") || !variable_instance_exists(id,"xp_require") || !variable_instance_exists(id,"level")) { return; }
        if (!is_real(xp) || !is_real(_gain) || !is_real(xp_require)) { return; }
        show_debug_message("  XP Before Add: " + string(xp) + "/" + string(xp_require) + " | Level: " + string(level));
        xp += _gain; // Add the gained XP
        show_debug_message("  XP After Add: " + string(xp) + "/" + string(xp_require));

        // Level‐up loop
        var _levelled_up_this_call = false;
        show_debug_message("  Checking level up loop (xp >= xp_require? -> " + string(xp) + ">=" + string(xp_require) + "? -> " + string(xp >= xp_require) + ")");

        while (xp >= xp_require)
        {
            _levelled_up_this_call = true;
            show_debug_message("    --> LEVEL UP! Starting loop iteration.");
            xp -= xp_require; level += 1; var _old_req = xp_require; xp_require = floor(xp_require * 1.4);
            show_debug_message("        Level Incr -> " + string(level));
            show_debug_message("        XP Req Changed: " + string(_old_req) + " -> " + string(xp_require));
            show_debug_message("        Remaining XP: " + string(xp));
            // Raise stats
            hp_total += 5; mp_total += 3; atk += 1; def += 1;
            // Restore to full on level‐up
            hp = hp_total; mp = mp_total;
            show_debug_message("        Stats Increased & HP/MP Restored.");

            // Show Level Up Dialogue
            // --- FIX: Call create_dialog, not scr_dialogue ---
            if (script_exists(scr_dialogue)) { // Check if script asset exists
                 // Call the function *defined inside* scr_dialogue
                 create_dialog([{
                      name:"Level Up!", // Ensure "Level Up!" exists in global.char_colors
                      msg: "You reached level " + string(level) + "!\n" +
                           "HP: "  + string(hp_total)  + "\n" +
                           "MP: "  + string(mp_total)  + "\n" +
                           "ATK: " + string(atk)       + "\n" +
                           "DEF: " + string(def)
                 }]);
            } else { show_debug_message("        ERROR: scr_dialogue script missing!"); }
            // --- End Fix ---
             show_debug_message("    <-- LEVEL UP! Loop Iteration End.");
        } // End while loop

        if (_levelled_up_this_call) { show_debug_message("$$$ Finished Level Up Process! Current Level: " + string(level)); }
        else { show_debug_message("--- add_xp Function END (No level up occurred) ---"); }
    } // End add_xp function definition

} // End if !initialized