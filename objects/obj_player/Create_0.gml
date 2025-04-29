/// obj_player :: Create Event
/// Initializes player control, sprite, and ensures persistent data exists in global map ONLY for a new game.

persistent = true; 

show_debug_message("--- obj_player Create Event RUNNING (Instance ID: " + string(id) + ") ---");

// Movement & world setup
move_speed = 2;
tilemap    = layer_tilemap_get_id(layer_get_id("Tiles_Col")); 
if (tilemap == -1) { show_debug_message("Warning [obj_player Create]: Collision layer 'Tiles_Col' not found!"); }
if (script_exists(scr_InitRoomMap)) scr_InitRoomMap(); 

// --- Ensure Persistent Data Structures & Initialize Hero ONLY ONCE per Game Start ---
if (!variable_instance_exists(id, "persistent_data_initialized")) {
    persistent_data_initialized = true; 
    show_debug_message("!!! obj_player CREATE: First Time Instance Initialization !!!");

    var _hero_key = "hero"; 

    // Add hero to global party list if needed 
    if (variable_global_exists("party_members") && is_array(global.party_members)) {
        if (array_get_index(global.party_members, _hero_key) == -1) { array_push(global.party_members, _hero_key); show_debug_message("  -> Added '" + _hero_key + "' to global.party_members."); }
    } else { show_debug_message("ERROR: global.party_members missing or not array in obj_player Create. Initializing."); global.party_members = [_hero_key]; }

    // Ensure global.party_current_stats map exists 
    if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) {
        show_debug_message("WARNING: obj_player Create creating global.party_current_stats map.");
        global.party_current_stats = ds_map_create();
    }

    // Initialize "hero" stats in the map ONLY if starting a New Game 
    var _is_new_game = (variable_global_exists("start_as_new_game")) ? global.start_as_new_game : true; 

    if (_is_new_game) {
        show_debug_message(" -> New Game Detected by Player Create.");
        if (ds_exists(global.party_current_stats, ds_type_map) && !ds_map_exists(global.party_current_stats, _hero_key)) {
            show_debug_message(" -> Initializing NEW GAME '" + _hero_key + "' data in global.party_current_stats.");
            
            // Fetch base data using the (now verified/created) fetch script
            var _base_data = script_exists(scr_FetchCharacterInfo) ? scr_FetchCharacterInfo(_hero_key) : undefined; 
            
            // --- Fallback Data (Includes class) ---
            if (!is_struct(_base_data)) {
                show_debug_message("CRITICAL ERROR: Could not fetch base data for '" + _hero_key + "'! Using fallback.");
                _base_data = { 
                    name:"Hero", class:"Hero", // <<< Default class included
                    hp: 40, maxhp: 40, mp: 20, maxmp: 20, 
                    atk: 10, def: 5, matk: 8, mdef: 4, spd: 7, luk: 5, 
                    level: 1, xp: 0, xp_require: 100, 
                    overdrive: 0, overdrive_max: 100, 
                    skills:[], equipment: { weapon:noone, offhand:noone, armor:noone, helm:noone, accessory:noone }, 
                    resistances: { physical: 0 }, 
                    character_key: _hero_key
                };
            }
            // --- End Fallback ---

            // Create initial persistent struct - Safely access fields from _base_data
            var _xp_req = (script_exists(scr_GetXPForLevel)) ? scr_GetXPForLevel(2) : 100;
            var _skills_arr = variable_struct_exists(_base_data, "skills") && is_array(_base_data.skills) ? variable_clone(_base_data.skills, true) : [];
            var _equip_struct = variable_struct_exists(_base_data, "equipment") && is_struct(_base_data.equipment) ? variable_clone(_base_data.equipment, true) : { weapon: noone, offhand: noone, armor: noone, helm: noone, accessory: noone };
            var _resists_struct = variable_struct_exists(_base_data, "resistances") && is_struct(_base_data.resistances) ? variable_clone(_base_data.resistances, true) : { physical: 0, fire: 0, ice: 0, lightning: 0, poison: 0, holy: 0, dark: 0 };

            var _initial_hero_stats = {
                maxhp:      variable_struct_get(_base_data, "maxhp") ?? 40, 
                maxmp:      variable_struct_get(_base_data, "maxmp") ?? 20,
                atk:        variable_struct_get(_base_data, "atk") ?? 10,    
                def:        variable_struct_get(_base_data, "def") ?? 5,
                matk:       variable_struct_get(_base_data, "matk") ?? 8,   
                mdef:       variable_struct_get(_base_data, "mdef") ?? 4,
                spd:        variable_struct_get(_base_data, "spd") ?? 7,     
                luk:        variable_struct_get(_base_data, "luk") ?? 5,
                level:      variable_struct_get(_base_data, "level") ?? 1, 
                xp:         variable_struct_get(_base_data, "xp") ?? 0, 
                xp_require: variable_struct_get(_base_data, "xp_require") ?? _xp_req, 
                skills:     _skills_arr, 
                equipment:  _equip_struct,
                resistances: _resists_struct, 
                overdrive:  variable_struct_get(_base_data, "overdrive") ?? 0, 
                overdrive_max: variable_struct_get(_base_data, "overdrive_max") ?? 100,
                name:       variable_struct_get(_base_data, "name") ?? "Hero",
                class:      variable_struct_get(_base_data, "class") ?? "Adventurer", // <<< Safely get class
                character_key: _hero_key
            };
            _initial_hero_stats.hp = _initial_hero_stats.maxhp; 
            _initial_hero_stats.mp = _initial_hero_stats.maxmp; 

            ds_map_add(global.party_current_stats, _hero_key, _initial_hero_stats);
            show_debug_message(" -> Finished initializing NEW GAME '" + _hero_key + "' map entry.");

      } else if (ds_exists(global.party_current_stats, ds_type_map)) { 
            show_debug_message(" -> New Game flag true, but hero data already exists in map? Skipping default init.");
      }
      
    } else {
         show_debug_message(" -> Player Create: Assuming Loading Game or Returning Player (Skipping Default Stat Init).");
         if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) {
              show_debug_message(" -> CRITICAL WARNING: Loading game/returning but party_current_stats missing! Creating empty map.");
              global.party_current_stats = ds_map_create();
         }
    }

} // End persistent_data_initialized check


// --- Initialize non-persistent battle state vars ---
// These are reset when this instance is used in battle by the manager
combat_state = "idle"; 
origin_x = x; origin_y = y;
target_for_attack = noone; 
attack_fx_sprite = spr_pow; 
attack_fx_sound = snd_punch; 
attack_animation_finished = false; 
stored_action_for_anim = undefined; 
sprite_assigned = false; 
turnCounter = 0; 

// --- Overworld specific variables ---
// (Keep any other necessary instance variables for the overworld player here)