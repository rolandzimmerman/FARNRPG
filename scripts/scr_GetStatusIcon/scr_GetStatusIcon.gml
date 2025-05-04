/// @function scr_GetStatusIcon(effect_name)
/// @returns {Int} sprite_index for the status‐icon or -1 if none
function scr_GetStatusIcon(effect_name) {
    switch (effect_name) {
        case "poison":  return spr_status_poison; //STD
        case "blind":   return spr_status_blind;
        case "bind":    return spr_status_bind;
        case "shame":   return spr_status_shame;
        case "webbed":  return spr_status_webbed; //Spooged
        case "silence": return spr_status_silence; //Gagged
        case "disgust": return spr_status_disgust;
        case "haste":   return spr_status_haste;
        case "slow":    return spr_status_slow;
        default:        return -1;
    }
}
