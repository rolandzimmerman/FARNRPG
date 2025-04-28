/// @function scr_CalculateEquippedStats(_base_stats_struct)
/// @description Calculates final battle stats by adding equipment bonuses and resistances to base stats.
/// @param {Struct} _base_stats_struct The base character data struct from scr_GetPlayerData.
/// @returns {Struct} A *new* struct with the final calculated stats.
function scr_CalculateEquippedStats(_base_stats_struct) {
    // --- Validate input ---
    if (!is_struct(_base_stats_struct)) {
        show_debug_message("ERROR [CalculateEquippedStats]: Invalid base stats struct provided.");
        // Return a minimal fallback struct
        return { 
            name: "Error", hp: 1, maxhp: 1, mp: 1, maxmp: 1, 
            atk: 1, def: 1, matk: 1, mdef: 1, spd: 1, luk: 1, 
            level: 1, xp: 0, xp_require: 100, skills: [], 
            equipment: { weapon: -4, offhand: -4, armor: -4, helm: -4, accessory: -4 }, 
            overdrive: 0, overdrive_max: 100, character_key: "error", is_defending: false,
            resistances: { physical: 0, fire: 0, ice: 0, lightning: 0, poison: 0, holy: 0, dark: 0 } 
        };
    }

    // <<< ADDED LOGGING: Show input HP/MaxHP >>>
    show_debug_message(" -> CalculateEquippedStats INPUT HP/MaxHP: " + 
        string(_base_stats_struct.hp ?? "N/A") + "/" + string(_base_stats_struct.maxhp ?? "N/A"));
    // <<< END LOGGING >>>

    // --- Start with a DEEP COPY of base stats using the built-in function ---
    var final_stats = variable_clone(_base_stats_struct, true); 
        
    // --- Ensure essential nested structs exist AFTER potential copy ---
     if (!is_struct(final_stats)) { 
          show_debug_message("ERROR [CalculateEquippedStats]: variable_clone failed to copy base stats struct.");
           // Re-create fallback if copy failed
           return { /* minimal fallback struct */ };
     }
     if (!variable_struct_exists(final_stats, "resistances") || !is_struct(final_stats.resistances)) {
          final_stats.resistances = { physical: 0, fire: 0, ice: 0, lightning: 0, poison: 0, holy: 0, dark: 0 };
          show_debug_message(" -> Initialized missing resistances struct after clone.");
     }
     if (!variable_struct_exists(final_stats, "equipment") || !is_struct(final_stats.equipment)) {
          final_stats.equipment = { weapon: -4, offhand: -4, armor: -4, helm: -4, accessory: -4 };
          show_debug_message(" -> Initialized missing equipment struct after clone.");
     }


    // --- Ensure base stats exist before adding bonuses ---
    var bonus_stats = ["atk", "def", "matk", "mdef", "spd", "luk", "maxhp", "maxmp"]; 
    for (var i=0; i<array_length(bonus_stats); i++){
        var stat_key = bonus_stats[i];
        if (!variable_struct_exists(final_stats, stat_key)) {
            final_stats[$ stat_key] = (stat_key == "maxhp" || stat_key == "maxmp") ? 1 : 0; 
        }
    }
    // Also ensure current hp/mp exist, copying from max if needed (will be clamped later anyway)
    if (!variable_struct_exists(final_stats, "hp")) final_stats.hp = final_stats.maxhp;
    if (!variable_struct_exists(final_stats, "mp")) final_stats.mp = final_stats.maxmp;
    
    
    // --- Get Item Database ---
    var item_db = global.item_database; 
    if (!ds_exists(item_db, ds_type_map)) { 
        show_debug_message("ERROR [CalculateEquippedStats]: Item Database (global.item_database) not found or invalid DS Map.");
        return final_stats; 
    }

    // --- Iterate through equipped items ---
    var equip_struct = final_stats.equipment;
    var equip_slots = variable_struct_get_names(equip_struct);
    show_debug_message(" -> Calculating bonuses for equipment: " + json_encode(equip_struct));
    for (var i = 0; i < array_length(equip_slots); i++) {
        var slot = equip_slots[i];
        var item_key = variable_struct_get(equip_struct, slot);

        if (is_string(item_key) && item_key != "" && item_key != "-4" && item_key != string(noone)) { 
             var item_data = ds_map_find_value(item_db, item_key); 
             if (is_struct(item_data)) {
                 show_debug_message("    -> Applying bonuses/resists from: " + (item_data.name ?? "???"));
                 // Apply stat bonuses
                 if (variable_struct_exists(item_data, "bonuses") && is_struct(item_data.bonuses)) {
                     var item_bonuses = item_data.bonuses;
                     var bonus_keys = variable_struct_get_names(item_bonuses);
                     for (var j = 0; j < array_length(bonus_keys); j++) {
                         var bonus_key = bonus_keys[j];
                         var bonus_value = variable_struct_get(item_bonuses, bonus_key);
                         // Check if stat exists OR if it's hp_total/mp_total which modify maxhp/maxmp
                         if (variable_struct_exists(final_stats, bonus_key) || bonus_key == "hp_total" || bonus_key == "mp_total") {
                              if (bonus_key == "hp_total") { final_stats.maxhp += bonus_value; show_debug_message("      +MaxHP: " + string(bonus_value)); }
                              else if (bonus_key == "mp_total") { final_stats.maxmp += bonus_value; show_debug_message("      +MaxMP: " + string(bonus_value)); }
                              // Check again if bonus_key exists now, as hp_total/mp_total don't exist on final_stats
                              else if (variable_struct_exists(final_stats, bonus_key)) { 
                                   final_stats[$ bonus_key] += bonus_value; 
                                   show_debug_message("      +" + bonus_key + ": " + string(bonus_value)); 
                              }
                         }
                     }
                 }
                 // Apply resistances (ADDITIVE percentage points)
                 if (variable_struct_exists(item_data, "resistances") && is_struct(item_data.resistances)) {
                     var item_resists = item_data.resistances;
                     var resist_keys = variable_struct_get_names(item_resists);
                     for (var j = 0; j < array_length(resist_keys); j++) {
                         var resist_key = resist_keys[j]; 
                         var resist_value = variable_struct_get(item_resists, resist_key); 
                         if (variable_struct_exists(final_stats.resistances, resist_key)) {
                              final_stats.resistances[$ resist_key] += resist_value;
                              show_debug_message("      +Resist " + resist_key + ": " + string(resist_value * 100) + "%");
                         } else {
                              final_stats.resistances[$ resist_key] = resist_value; 
                               show_debug_message("      +Resist " + resist_key + " (New): " + string(resist_value * 100) + "%");
                         }
                     }
                 }
             } else { show_debug_message("Warning [CalculateEquippedStats]: Item data not found for key: " + string(item_key)); }
        } // end if valid item_key
    } // end for loop equip_slots
    
    // --- Final adjustments ---
    // Clamp MaxHP/MaxMP first
    final_stats.maxhp = max(1, final_stats.maxhp); 
    final_stats.maxmp = max(0, final_stats.maxmp); 
    
    // Use the HP/MP value passed into this function (which came from scr_GetPlayerData's loaded/default data) 
    // as the base for clamping against the *new* calculated MaxHP/MaxMP.
    var starting_hp = _base_stats_struct.hp ?? final_stats.maxhp; // Use the input HP
    var starting_mp = _base_stats_struct.mp ?? final_stats.maxmp; // Use the input MP
    
    // Clamp Current HP/MP: Ensure it's at least 1 (if MaxHP>0) / 0 (for MP), and not more than the NEW MaxHP/MaxMP
    final_stats.hp = clamp(starting_hp, (final_stats.maxhp > 0 ? 1 : 0) , final_stats.maxhp); 
    final_stats.mp = clamp(starting_mp, 0, final_stats.maxmp); 

    // <<< ADDED LOGGING: Show final HP/MaxHP >>>
    show_debug_message(" -> CalculateEquippedStats FINAL HP/MaxHP: " + 
        string(final_stats.hp) + "/" + string(final_stats.maxhp));
    // <<< END LOGGING >>>
    
    // Ensure other core fields exist
    if (!variable_struct_exists(final_stats,"character_key")) final_stats.character_key = _base_stats_struct.character_key ?? _base_stats_struct.name ?? "unknown";
    if (!variable_struct_exists(final_stats,"is_defending")) final_stats.is_defending = false;
    if (!variable_struct_exists(final_stats,"skill_index")) final_stats.skill_index = 0;
    if (!variable_struct_exists(final_stats,"item_index")) final_stats.item_index = 0;

    show_debug_message(" -> Calculated stats for " + (final_stats.name ?? "???") + ": ATK=" + string(final_stats.atk) + " DEF=" + string(final_stats.def) + " SPD=" + string(final_stats.spd) + " Resists=" + json_encode(final_stats.resistances));

    return final_stats;
}