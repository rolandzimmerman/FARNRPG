/// @function scr_GetPlayerData()
/// @description Creates a struct containing a snapshot of the current player's stats for battle.
function scr_GetPlayerData() {
    // Ensure the persistent player object exists
    if (!instance_exists(obj_player)) {
        show_debug_message("ERROR [scr_GetPlayerData]: obj_player instance not found!");
        // Return an empty struct or default data to prevent crashes,
        // though the battle manager should ideally prevent battle start without player.
        return {
             hp: 1, maxhp: 1, mp: 0, maxmp: 0, atk: 1, def: 1, skills: [], skill_index: 0, is_defending: false
        };
    }

    // Create and return a struct with copies of relevant stats
    // Assumes obj_player has these variables defined (hp, hp_total, mp, mp_total, atk, def, skills)
    return {
        hp:           obj_player.hp,
        maxhp:        obj_player.hp_total, // Use hp_total from obj_player
        mp:           obj_player.mp,
        maxmp:        obj_player.mp_total, // Use mp_total from obj_player
        atk:          obj_player.atk,
        def:          obj_player.def,
        // Add any other stats needed in battle (magic etc.)
        // magic_atk: obj_player.magic_atk,

        skills:       obj_player.skills, // Copy the array reference (assuming skills don't change IN battle)
        skill_index:  0,                 // Battle-specific starting value
        is_defending: false              // Battle-specific starting value
    };
}