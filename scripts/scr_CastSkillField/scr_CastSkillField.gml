/// @function           scr_CastSkillField(_caster_key, _skill_struct, _target_key)
/// @description        Applies a skill's effect outside of battle, modifying persistent stats.
/// @param {String}     _caster_key         The character key (from global.party_members) of the caster.
/// @param {Struct}     _skill_struct       The data struct of the skill being cast.
/// @param {String}     _target_key         The character key of the target.
/// @returns {Bool}     True if the effect was successfully applied, false otherwise.
function scr_CastSkillField(_caster_key, _skill_struct, _target_key) {
    
    var _skill_name = _skill_struct.name ?? "Unknown Skill";
    show_debug_message("--- scr_CastSkillField START --- Caster: " + _caster_key + " | Skill: " + _skill_name + " | Target: " + _target_key);

    // --- Validate Inputs & Data Access ---
    if (!is_string(_caster_key) || !is_struct(_skill_struct) || !is_string(_target_key)) {
        show_debug_message(" -> ERROR: Invalid arguments provided.");
        return false;
    }
    if (!ds_exists(global.party_current_stats, ds_type_map)) {
        show_debug_message(" -> ERROR: global.party_current_stats map missing!");
        return false;
    }
    if (!ds_map_exists(global.party_current_stats, _caster_key)) {
        show_debug_message(" -> ERROR: Caster key '" + _caster_key + "' not found in stats map!");
        return false;
    }
     if (!ds_map_exists(global.party_current_stats, _target_key)) {
        show_debug_message(" -> ERROR: Target key '" + _target_key + "' not found in stats map!");
        return false;
    }
    
    // Get direct references to the structs IN THE MAP
    var caster_data = global.party_current_stats[? _caster_key];
    var target_data = global.party_current_stats[? _target_key];
    
    if (!is_struct(caster_data) || !is_struct(target_data)) {
         show_debug_message(" -> ERROR: Caster or Target data in map is not a struct!");
         return false;
    }
    
    // --- Apply Effect (Add more cases as needed) ---
    var applied = false;
    var effect = _skill_struct.effect ?? "none";
    
    show_debug_message("  -> Applying effect: " + effect);

    switch (effect) {
        case "heal_hp":
            var target_hp = variable_struct_get(target_data, "hp") ?? -1;
            var target_maxhp = variable_struct_get(target_data, "maxhp") ?? 0;
            
            if (target_hp < 0 || target_maxhp <= 0) { // Invalid target data for healing
                 show_debug_message("    -> HEAL Fail: Target HP/MaxHP invalid or missing.");
                 applied = false; 
                 break; 
            }
            if (target_hp >= target_maxhp) { // Already at full HP
                 show_debug_message("    -> HEAL Fail: Target already at full HP.");
                 applied = false; // Or maybe return true but effect is 0? Let's say false for now.
                 break;
            }
             if (target_hp <= 0) { // Cannot heal KO'd character (unless revive logic added later)
                 show_debug_message("    -> HEAL Fail: Target is KO'd.");
                 applied = false; 
                 break;
            }
            
            var baseHeal = _skill_struct.heal_amount ?? 0;
            var pstatKey = _skill_struct.power_stat ?? "matk";
            var casterPower = variable_struct_get(caster_data, pstatKey) ?? 0;
            var healAmt = floor(baseHeal + casterPower * 0.5); // Example formula
            var actualHeal = min(healAmt, target_maxhp - target_hp); // Can't heal more than needed
            
            // --- MODIFY the persistent data ---
            target_data.hp += actualHeal; 
            // IMPORTANT: Replace the struct in the map with the modified version
            ds_map_replace(global.party_current_stats, _target_key, target_data); 
            // --- END MODIFY ---
            
            show_debug_message("    -> HEAL Applied: +" + string(actualHeal) + " HP to " + _target_key + ". New HP: " + string(target_data.hp));
            applied = true;
            break;

        case "cure_status":
             var status_to_cure = _skill_struct.value ?? ""; // Which status effect to cure?
             show_debug_message("    -> CURE STATUS '" + status_to_cure + "' effect (Not Implemented Yet)");
             // TODO: Implement status effect storage and removal on persistent data
             // For now, just pretend it worked
             applied = true; 
             break;
             
        // Add cases for MP restore, other field-usable buffs/effects
             
        default:
            show_debug_message("    -> Effect '" + effect + "' cannot be used outside battle.");
            applied = false;
            break;
    }

    show_debug_message("--- scr_CastSkillField END --- | Applied: " + string(applied));
    return applied;
}