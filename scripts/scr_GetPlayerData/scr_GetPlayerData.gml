/// @function scr_GetPlayerData(_key)
/// @description Retrieves character data, prioritizing VALID persistent data from global map, falling back to base template. Ensures a full, valid struct is returned.
/// @param {String} _key Character key.
/// @returns {Struct} A DEEP COPY of the character's current stats struct.
function scr_GetPlayerData(_key) {
    show_debug_message("--- scr_GetPlayerData START for key: " + string(_key) + " ---");
    var final_data = {}; // Initialize empty struct for the result
    var loaded_persistent_struct = noone; 
    var use_persistent_data = false; 

    // --- Define Base Character Template (used as fallback) ---
    var base_data = {}; 
    var base_resistances = { physical: 0, fire: 0, ice: 0, lightning: 0, poison: 0, holy: 0, dark: 0 }; 
    var base_equipment = { weapon: -4, offhand: -4, armor: -4, helm: -4, accessory: -4 }; 

    // Populate base_data based on _key (same as your existing switch)
    switch (_key) {
        case "hero": // Make sure this matches the base stats template
            base_data = { name: "Hero", hp: 40, maxhp: 40, mp: 20, maxmp: 20, atk: 10, def: 5, matk: 8, mdef: 4, spd: 7, luk: 5, level: 1, xp: 0, xp_require: 100, overdrive: 0, overdrive_max: 100, skills: [ { name: "Heal", cost: 5, effect:"heal_hp", heal_amount: 25, power_stat:"matk", requires_target: false }, { name: "Fireball", cost: 6, effect:"damage_enemy", damage: 18, power_stat:"matk", element:"fire", requires_target: true }, { name: "Blind", cost: 5, effect:"blind", duration:3, requires_target: true }, { name: "Shame", cost: 8, effect:"shame", duration:3, requires_target: true } ], equipment: { weapon: "bronze_sword", offhand: -4, armor: "leather_armor", helm: -4, accessory: -4 }, resistances: variable_clone(base_resistances, true), character_key: _key };
            break;
        case "claude":
             base_data = { name: "Claude", hp: 35, maxhp: 35, mp: 15, maxmp: 15, atk: 8, def: 6, matk: 4, mdef: 5, spd: 6, luk: 4, level: 1, xp: 0, xp_require: 100, overdrive: 0, overdrive_max: 100, skills: [ ], equipment: { weapon: "iron_dagger", offhand: -4, armor: -4, helm: -4, accessory: -4 }, resistances: { physical: 0.05, fire: -0.1, ice: 0.1, lightning: 0, poison: 0, holy: 0, dark: 0 }, character_key: _key };
            break;
        default: // Fallback for unknown keys
            base_data = { name: "Unknown", hp: 10, maxhp: 10, mp: 5, maxmp: 5, atk: 1, def: 1, matk: 1, mdef: 1, spd: 1, luk: 1, level: 1, xp: 0, xp_require: 100, overdrive: 0, overdrive_max: 100, skills: [], equipment: variable_clone(base_equipment, true), resistances: variable_clone(base_resistances, true), character_key: _key };
            break;
    }
    // Ensure base template always has necessary nested structs and core fields
    if (!variable_struct_exists(base_data, "resistances")) base_data.resistances = variable_clone(base_resistances, true);
    if (!variable_struct_exists(base_data, "equipment")) base_data.equipment = variable_clone(base_equipment, true);
    if (!variable_struct_exists(base_data, "skills")) base_data.skills = [];
    if (!variable_struct_exists(base_data, "overdrive")) base_data.overdrive = 0;
    if (!variable_struct_exists(base_data, "overdrive_max")) base_data.overdrive_max = 100;
    if (!variable_struct_exists(base_data, "character_key")) base_data.character_key = _key;
    if (!variable_struct_exists(base_data, "level")) base_data.level = 1; 
    if (!variable_struct_exists(base_data, "xp")) base_data.xp = 0; 
    if (!variable_struct_exists(base_data, "xp_require")) base_data.xp_require = (script_exists(scr_GetXPForLevel)) ? scr_GetXPForLevel(base_data.level + 1) : 100; 
    if (!variable_struct_exists(base_data, "maxhp")) base_data.maxhp = 1; 
    if (!variable_struct_exists(base_data, "hp")) base_data.hp = base_data.maxhp; 
    if (!variable_struct_exists(base_data, "maxmp")) base_data.maxmp = 0; 
    if (!variable_struct_exists(base_data, "mp")) base_data.mp = base_data.maxmp; 

    // --- Attempt to Load Persistent Data ---
    if (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) {
        if (ds_map_exists(global.party_current_stats, _key)) {
            loaded_persistent_struct = ds_map_find_value(global.party_current_stats, _key); 
            
            // --- Validate the loaded struct ---
            // Check if it's a struct AND has at least some essential fields
            if (is_struct(loaded_persistent_struct) && 
                variable_struct_exists(loaded_persistent_struct,"maxhp") && 
                variable_struct_exists(loaded_persistent_struct,"level")) 
            {
                show_debug_message(" -> Found VALID persistent data struct for " + _key + ". Cloning it.");
                try { show_debug_message("    Persistent Data Found: " + json_encode(loaded_persistent_struct)); } catch(_e){}
                
                final_data = variable_clone(loaded_persistent_struct, true); // Deep copy the VALID persistent data
                use_persistent_data = true; 

                // Add Missing Fields from Template (for forward compatibility if save is old)
                var base_keys = variable_struct_get_names(base_data);
                for (var i = 0; i < array_length(base_keys); i++) {
                     var k = base_keys[i];
                     if (!variable_struct_exists(final_data, k)) { 
                          show_debug_message("    -> Persistent data missing key '" + k + "'. Adding default from template.");
                          var default_val = variable_struct_get(base_data, k);
                          final_data[$ k] = variable_clone(default_val, true); 
                     }
                     // Ensure nested structs are valid after clone/adding missing fields
                     else if (k == "resistances" && (!variable_struct_exists(final_data,"resistances") || !is_struct(final_data.resistances))) { final_data.resistances = variable_clone(base_data.resistances, true); }
                     else if (k == "equipment" && (!variable_struct_exists(final_data,"equipment") || !is_struct(final_data.equipment))) { final_data.equipment = variable_clone(base_data.equipment, true); }
                     else if (k == "skills" && (!variable_struct_exists(final_data,"skills") || !is_array(final_data.skills))) { final_data.skills = []; }
                }
            } else { 
                show_debug_message(" -> Persistent data for " + _key + " was invalid/incomplete struct (e.g., '{}'). Using base template instead."); 
                 try { show_debug_message("    Invalid Data Found: " + json_encode(loaded_persistent_struct)); } catch(_e){}
                use_persistent_data = false; // Mark as invalid, fallback to base template
            }
        } else { show_debug_message(" -> No persistent data found for key '" + _key + "'. Using base template."); }
    } else { show_debug_message(" -> global.party_current_stats map not found. Using base template."); }

    // --- If Persistent Data Wasn't Loaded or was Invalid, Use Base Template ---
    if (!use_persistent_data) {
        show_debug_message(" -> Using BASE TEMPLATE data for " + _key + ".");
        final_data = variable_clone(base_data, true); // Deep copy the base template
        // Ensure nested structs exist in the fallback case
        if (!variable_struct_exists(final_data, "resistances")) final_data.resistances = variable_clone(base_resistances, true);
        if (!variable_struct_exists(final_data, "equipment")) final_data.equipment = variable_clone(base_equipment, true);
        if (!variable_struct_exists(final_data, "skills")) final_data.skills = [];
        // Ensure current HP/MP are set to MaxHP/MaxMP from template
        final_data.hp = final_data.maxhp;
        final_data.mp = final_data.maxmp;
    }
    
    // --- Final Check & Clamp HP/MP ---
    // Ensure HP/MP are not above max values from loaded/template data
    if (!variable_struct_exists(final_data,"maxhp")) final_data.maxhp = 1; // Safety default
    if (!variable_struct_exists(final_data,"maxmp")) final_data.maxmp = 0;
    if (!variable_struct_exists(final_data,"hp")) final_data.hp = final_data.maxhp; // Default HP to max if missing
    if (!variable_struct_exists(final_data,"mp")) final_data.mp = final_data.maxmp;
    final_data.hp = clamp(final_data.hp, 0, final_data.maxhp); // Allow 0 HP initially if loaded as such
    final_data.mp = clamp(final_data.mp, 0, final_data.maxmp);


    // --- Final Logging & Return ---
    show_debug_message(" -> scr_GetPlayerData FINAL (before equip calc) for " + (final_data.name ?? _key) + 
                       ": Lvl=" + string(final_data.level ?? 1) + 
                       " HP=" + string(final_data.hp) + "/" + string(final_data.maxhp) + // Use calculated values
                       " MP=" + string(final_data.mp) + "/" + string(final_data.maxmp) + 
                       " XP=" + string(final_data.xp ?? 0));
                       
    return final_data; // Return the deep copy
}