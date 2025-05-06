/// @function scr_AddXPToParty(amount)
/// @description Awards `amount` XP to every alive member of the party.
function scr_AddXPToParty(_amt) {
    if (!ds_exists(global.party_current_stats, ds_type_map)) return;
    // For each key in party_current_stats
    var keys = ds_map_keys_to_array(global.party_current_stats);
    for (var i = 0; i < array_length(keys); i++) {
        var key = keys[i];
        // call your existing XP script
        scr_AddXPToCharacter(key, _amt);
    }
}