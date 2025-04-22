/// @function scr_GetPlayerData()
/// @description Creates a struct containing a snapshot of the current player's stats for battle.
function scr_GetPlayerData() {
    // Ensure the persistent player object exists
    if (!instance_exists(obj_player)) {
        show_debug_message("ERROR [scr_GetPlayerData]: obj_player instance not found!");
        // Return default data with new stats
        return {
             hp: 1, maxhp: 1, mp: 0, maxmp: 0, atk: 1, def: 1,
             matk: 1, mdef: 1, spd: 1, luk: 1, // Added defaults
             skills: [], skill_index: 0, item_index: 0, is_defending: false,
             status: "none"
        };
    }

    // Create and return a struct with copies of relevant stats
    // Assumes obj_player has these variables defined
    return {
        hp:           obj_player.hp,
        maxhp:        obj_player.hp_total,
        mp:           obj_player.mp,
        maxmp:        obj_player.mp_total,
        atk:          obj_player.atk,
        def:          obj_player.def,
        matk:         obj_player.matk,     // <<< ADDED
        mdef:         obj_player.mdef,     // <<< ADDED
        spd:          obj_player.spd,      // <<< ADDED
        luk:          obj_player.luk,      // <<< ADDED

        skills:       obj_player.skills,   // Copy the array reference
        skill_index:  0,
        item_index:   0,
        is_defending: false,
        status:       "none"
    };
}