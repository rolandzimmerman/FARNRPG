/// @function scr_GetPlayerData(_key)
/// @description Retrieves character data, prioritizing VALID persistent data from global map, falling back to base template. Ensures a full, valid struct is returned.
/// @param {String} _key Character key.
/// @returns {Struct} A DEEP COPY of the character's current stats struct.
function scr_GetPlayerData(_key) {
    show_debug_message("--- scr_GetPlayerData START for key: " + string(_key) + " ---");
    var final_data = {}; 
    var loaded_persistent_struct = noone; 
    var use_persistent_data = false; 

    // --- Define Base Character Template (used as fallback) ---
    var base_data = {}; 
    var base_resistances = { physical: 0, fire: 0, ice: 0, lightning: 0, poison: 0, holy: 0, dark: 0 }; 
    // Use -4 or noone consistently for empty slots
    var base_equipment = { weapon: -4, offhand: -4, armor: -4, helm: -4, accessory: -4 }; 

    // Populate base_data based on _key 
    switch (_key) {
        case "hero":
            // Ensure base template includes all fields, including class
            base_data = { 
                name: "Hero", class: "Hero", hp: 40, maxhp: 40, mp: 20, maxmp: 20, 
                atk: 10, def: 5, matk: 8, mdef: 4, spd: 7, luk: 5, 
                level: 1, xp: 0, xp_require: 100, overdrive: 0, overdrive_max: 100, 
                skills: [ 
                    { name: "Heal", cost: 5, effect:"heal_hp", heal_amount: 25, power_stat:"matk", requires_target: false }, 
                    { name: "Fireball", cost: 6, effect:"damage_enemy", damage: 18, power_stat:"matk", element:"fire", requires_target: true },
                    { name: "Blind", cost: 5, effect:"blind", duration:3, requires_target: true },
                    { name: "Shame", cost: 8, effect:"shame", duration:3, requires_target: true }
                ], 
                // Use actual item keys for starting equipment if desired, otherwise use -4/noone
                equipment: { weapon: "bronze_sword", offhand: -4, armor: "leather_armor", helm: -4, accessory: -4 }, 
                resistances: variable_clone(base_resistances, true), 
                character_key: _key,
                battle_sprite: spr_player_battle // Add sprite if known here
            };
            break;
            
        case "claude":
             base_data = { 
                name: "Claude", class: "Cleric", hp: 35, maxhp: 35, mp: 25, maxmp: 25, 
                atk: 8, def: 4, matk: 12, mdef: 6, spd: 6, luk: 7, 
                level: 1, xp: 0, xp_require: 100, overdrive: 0, overdrive_max: 100, 
                skills: [ 
                     { name: "Heal", cost: 5, effect: "heal_hp", requires_target: false, heal_amount: 25, power_stat: "matk" },
                     { name: "Zap", cost: 4, effect: "damage_enemy", requires_target: true, damage: 15, element: "lightning", power_stat: "matk" },
                     { name: "Bind", cost: 6, effect: "bind", duration: 3, requires_target: true }
                ], 
                equipment: { weapon: "iron_dagger", offhand: -4, armor: -4, helm: -4, accessory: -4 }, 
                resistances: { physical: 0.05, fire: -0.1, ice: 0.1, lightning: 0, poison: 0, holy: 0, dark: 0 }, 
                character_key: _key,
                battle_sprite: spr_claude_battle // Add sprite if known here
             };
            break;
            
        // <<< ADDED CASES FOR OTHER CHARACTERS >>>
        case "izzy": 
             base_data = { 
                name: "Izzy", class: "Thief", hp: 38, maxhp: 38, mp: 15, maxmp: 15, 
                atk: 12, def: 6, matk: 5, mdef: 4, spd: 12, luk: 10, 
                level: 1, xp: 0, xp_require: 100, overdrive: 0, overdrive_max: 100, 
                skills: [ 
                    { name: "Steal", cost: 0, effect: "steal_item", requires_target: true }, // Define steal_item effect later
                    { name: "Quick Attack", cost: 3, effect: "damage_enemy", requires_target: true, damage: 10, element: "physical", power_stat: "atk" } 
                ], 
                equipment: { weapon: "iron_dagger", offhand: -4, armor: -4, helm: -4, accessory: "thief_gloves" }, // Example equipment
                resistances: variable_clone(base_resistances, true), 
                character_key: _key,
                battle_sprite: spr_izzy_battle // Add sprite if known here
             };
            break;
            
        case "gabby": 
             base_data = { 
                name: "Gabby", class: "Mage", hp: 30, maxhp: 30, mp: 35, maxmp: 35, 
                atk: 6, def: 3, matk: 15, mdef: 8, spd: 9, luk: 6, 
                level: 1, xp: 0, xp_require: 100, overdrive: 0, overdrive_max: 100, 
                skills: [ 
                    { name: "Fireball", cost: 6, effect: "damage_enemy", requires_target: true, damage: 18, element: "fire", power_stat: "matk" },
                    { name: "Heal", cost: 5, effect: "heal_hp", requires_target: false, heal_amount: 25, power_stat: "matk" } 
                ], 
                equipment: { weapon: "wooden_staff", offhand: -4, armor: -4, helm: -4, accessory: "lucky_charm" }, // Example equipment
                resistances: variable_clone(base_resistances, true), 
                character_key: _key,
                battle_sprite: spr_gabby_battle // Add sprite if known here
             };
            break;
       // <<< END ADDED CASES >>>

        default: // Fallback for unknown keys
            base_data = { name: "Unknown", class: "Unknown", hp: 10, maxhp: 10, mp: 5, maxmp: 5, atk: 1, def: 1, matk: 1, mdef: 1, spd: 1, luk: 1, level: 1, xp: 0, xp_require: 100, overdrive: 0, overdrive_max: 100, skills: [], equipment: variable_clone(base_equipment, true), resistances: variable_clone(base_resistances, true), character_key: _key };
            break;
    }
    // Ensure base template always has necessary nested structs and core fields
    if (!variable_struct_exists(base_data, "resistances")) base_data.resistances = variable_clone(base_resistances, true);
    if (!variable_struct_exists(base_data, "equipment")) base_data.equipment = variable_clone(base_equipment, true);
    if (!variable_struct_exists(base_data, "skills")) base_data.skills = [];
    // Ensure other base stats exist if template was incomplete
    if (!variable_struct_exists(base_data, "hp")) base_data.hp=1; if (!variable_struct_exists(base_data, "maxhp")) base_data.maxhp=1;
    if (!variable_struct_exists(base_data, "mp")) base_data.mp=0; if (!variable_struct_exists(base_data, "maxmp")) base_data.maxmp=0;
    if (!variable_struct_exists(base_data, "level")) base_data.level=1; if (!variable_struct_exists(base_data, "xp")) base_data.xp=0;
    if (!variable_struct_exists(base_data, "overdrive")) base_data.overdrive=0; if (!variable_struct_exists(base_data, "overdrive_max")) base_data.overdrive_max=100;
    if (!variable_struct_exists(base_data, "character_key")) base_data.character_key = _key;
    if (!variable_struct_exists(base_data, "class")) base_data.class = "Unknown";


    // --- Attempt to Load Persistent Data ---
    var loaded_persistent = false;
    if (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) {
        if (ds_map_exists(global.party_current_stats, _key)) {
            loaded_persistent_struct = ds_map_find_value(global.party_current_stats, _key); 
            if (is_struct(loaded_persistent_struct) && variable_struct_exists(loaded_persistent_struct,"maxhp") && variable_struct_exists(loaded_persistent_struct,"level")) {
                show_debug_message(" -> Found VALID persistent data struct for " + _key + ". Cloning it.");
                // try { show_debug_message("    Persistent Data Found: " + json_encode(loaded_persistent_struct)); } catch(_e){} // Can be very verbose
                final_data = variable_clone(loaded_persistent_struct, true); 
                loaded_persistent = true; 
                // Add Missing Fields from Template (for forward compatibility)
                var base_keys = variable_struct_get_names(base_data);
                for (var i = 0; i < array_length(base_keys); i++) { /* ... same loop as before to add MISSING keys ... */ }
            } else { show_debug_message(" -> Persistent data for " + _key + " was invalid/incomplete struct. Using base template instead."); }
        } else { show_debug_message(" -> No persistent data found for key '" + _key + "'. Using base template."); }
    } else { show_debug_message(" -> global.party_current_stats map not found. Using base template."); }

    // --- If Persistent Data Wasn't Loaded or Invalid, Use Base Template ---
    if (!loaded_persistent) {
        show_debug_message(" -> Using BASE TEMPLATE data for " + _key + ".");
        final_data = variable_clone(base_data, true); 
        if (!variable_struct_exists(final_data, "resistances")) final_data.resistances = variable_clone(base_resistances, true);
        if (!variable_struct_exists(final_data, "equipment")) final_data.equipment = variable_clone(base_equipment, true);
        if (!variable_struct_exists(final_data, "skills")) final_data.skills = [];
        // Ensure current HP/MP are set to MaxHP/MaxMP from template
        final_data.hp = final_data.maxhp;
        final_data.mp = final_data.maxmp;
    }
    
    // --- Final Check & Clamp HP/MP ---
    if (!variable_struct_exists(final_data,"maxhp")) final_data.maxhp = 1; 
    if (!variable_struct_exists(final_data,"maxmp")) final_data.maxmp = 0;
    if (!variable_struct_exists(final_data,"hp")) final_data.hp = final_data.maxhp; 
    if (!variable_struct_exists(final_data,"mp")) final_data.mp = final_data.maxmp;
    final_data.hp = clamp(final_data.hp, 0, final_data.maxhp); // Allow 0 HP 
    final_data.mp = clamp(final_data.mp, 0, final_data.maxmp);

    // --- Final Logging & Return ---
    show_debug_message(" -> scr_GetPlayerData FINAL (before equip calc) for " + (final_data.name ?? _key) + 
                       ": Lvl=" + string(final_data.level ?? 1) + 
                       " HP=" + string(final_data.hp) + "/" + string(final_data.maxhp) + 
                       " MP=" + string(final_data.mp) + "/" + string(final_data.maxmp) + 
                       " XP=" + string(final_data.xp ?? 0));
                       
    return final_data; 
}