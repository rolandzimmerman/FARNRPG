/// obj_player :: Create Event

// Persist this player across rooms
persistent = true;

// --- ADDED LOG: Check if Create Event runs unexpectedly ---
show_debug_message("--- obj_player Create Event RUNNING (Instance ID: " + string(id) + ") ---");
// --- END LOG ---

// Only initialize these base stats once
if (!variable_instance_exists(id, "initialized")) {
    initialized = true;
    show_debug_message("!!! obj_player CREATE: First Time Initialization !!!");

    // --- Add self to the global party list ---
    // Make sure obj_init runs first to create the array
     if (variable_global_exists("party_members")) {
         if (is_array(global.party_members)) {
             // Add only if not already present (important for persistence)
             if (array_get_index(global.party_members, "hero") == -1) {
                  array_push(global.party_members, "hero");
                  show_debug_message("  -> Added 'hero' to global.party_members. Current Party: " + string(global.party_members));
             } else {
                  show_debug_message("  -> 'hero' already in global.party_members.");
             }
         } else {
              show_debug_message("ERROR: global.party_members exists but is not an array!");
         }
     } else {
          show_debug_message("ERROR: global.party_members not initialized before obj_player Create!");
     }


    // ── Movement & world setup ──
    move_speed = 2;
    tilemap    = layer_tilemap_get_id("Tiles_Col");
    if (script_exists(scr_InitRoomMap)) scr_InitRoomMap();

    // ── Base stats (These are the persistent stats for 'hero') ──
    hp_total   = 40;    hp   = hp_total;
    mp_total   = 20;    mp   = mp_total;
    atk        = 10;    def  = 5;
    matk       = 8;     mdef = 4;
    spd        = 7;     luk  = 5;

    // ── Equipment (Managed on the player instance for 'hero') ──
    equipment = {
        weapon:    noone,
        offhand:   noone,
        armor:     noone,
        helm:      noone,
        accessory: noone
    };

    // ── Skills (Example skills for 'hero') ──
    // These might be better defined in scr_BuildCharacterDB and fetched/managed via level
    skills = [
        //{ name: "Heal", cost: 5, effect: "heal_hp", requires_target: false, heal_amount: 25, power_stat: "matk" },
        //{ name: "Fireball", cost: 6, effect: "damage_enemy", requires_target: true, damage: 18, element: "fire", power_stat: "matk" }
    ]; // Fetch skills based on level/character DB instead?

    // ── Inventory ──  <<<<< REMOVED THIS BLOCK >>>>>
    // inventory = [ ... ]; // This is now handled by global.party_inventory

    // ── Leveling ──
    level      = 1;
    xp         = 0;
    xp_require = (script_exists(scr_GetXPForLevel)) ? scr_GetXPForLevel(level + 1) : 100;
}