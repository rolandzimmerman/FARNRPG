/// obj_player :: Create Event
/// Initializes player control, sprite, and ensures persistent data exists in global map.

// Persist this player instance across rooms (for visual/control)
persistent = true;

show_debug_message("--- obj_player Create Event RUNNING (Instance ID: " + string(id) + ") ---");

// Movement & world setup (These can remain instance variables)
move_speed = 2;
tilemap    = layer_tilemap_get_id("Tiles_Col"); // Get collision tilemap ID
if (script_exists(scr_InitRoomMap)) scr_InitRoomMap(); // Initialize room connections if needed

// --- Ensure Persistent Data for "hero" exists in global map ---
// This block runs ONLY ONCE for the persistent player instance due to the check below.
if (!variable_instance_exists(id, "persistent_data_initialized")) {
    persistent_data_initialized = true; // Flag to prevent re-running this block
    show_debug_message("!!! obj_player CREATE: First Time Persistent Data Initialization !!!");

    var _hero_key = "hero"; // Character key for the player

    // --- Add to global party list if not already there ---
     if (variable_global_exists("party_members") && is_array(global.party_members)) {
         if (array_get_index(global.party_members, _hero_key) == -1) {
              array_push(global.party_members, _hero_key);
              show_debug_message("  -> Added '" + _hero_key + "' to global.party_members.");
         }
     } else {
         show_debug_message("ERROR: global.party_members missing or not array in obj_player Create.");
         global.party_members = [_hero_key]; // Initialize if missing
     }

     // --- Ensure global.party_current_stats map exists ---
     if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) {
         show_debug_message("WARNING: obj_player Create creating global.party_current_stats map.");
         global.party_current_stats = ds_map_create();
     }

     // --- Check/Initialize "hero" data in the map ---
     if (!ds_map_exists(global.party_current_stats, _hero_key)) {
          show_debug_message(" -> Initializing '" + _hero_key + "' data in global.party_current_stats.");
          // Fetch base data
          var _base_data = scr_FetchCharacterInfo(_hero_key);
          if (!is_struct(_base_data)) {
               show_debug_message("CRITICAL ERROR: Could not fetch base data for '" + _hero_key + "'!");
               // Create minimal fallback data
               _base_data = { name:"Hero", class:"Hero", hp_total: 1, mp_total: 0, atk: 1, def: 1, matk: 1, mdef: 1, spd: 1, luk: 1, skills:[] };
          }

          // Create initial persistent struct
          var _xp_req = (script_exists(scr_GetXPForLevel)) ? scr_GetXPForLevel(2) : 100;
          var _skills_arr = []; // Initial skills might come from base or level 1
          if (variable_struct_exists(_base_data, "skills") && is_array(_base_data.skills)) {
                // Deep copy skills if needed, or just reference? Depends on if skills change.
                 for (var i=0; i<array_length(_base_data.skills); i++) { if(is_struct(_base_data.skills[i])) array_push(_skills_arr, struct_copy(_base_data.skills[i])); }
          }

          var _initial_hero_stats = {
               hp: _base_data.hp_total ?? 1, maxhp: _base_data.hp_total ?? 1,
               mp: _base_data.mp_total ?? 0, maxmp: _base_data.mp_total ?? 0,
               atk: _base_data.atk ?? 1,     def: _base_data.def ?? 1,
               matk: _base_data.matk ?? 1,   mdef: _base_data.mdef ?? 1,
               spd: _base_data.spd ?? 1,     luk: _base_data.luk ?? 1,
               level: 1, xp: 0, xp_require: _xp_req,
               skills: _skills_arr, // Store learned/current skills here
               equipment: { // Initial empty equipment
                   weapon: noone, offhand: noone, armor: noone, helm: noone, accessory: noone
               }
               // DO NOT store inventory here - it's global
          };
          ds_map_add(global.party_current_stats, _hero_key, _initial_hero_stats);
          show_debug_message(" -> Finished initializing '" + _hero_key + "' map entry: " + string(_initial_hero_stats));

     } else {
          show_debug_message(" -> Found existing '" + _hero_key + "' data in global.party_current_stats.");
          // Optional: Ensure existing data has mandatory fields like 'equipment'
          var _existing_data = global.party_current_stats[? _hero_key];
          if (is_struct(_existing_data) && !variable_struct_exists(_existing_data, "equipment")) {
               show_debug_message(" -> Adding missing 'equipment' struct to existing hero data.");
               _existing_data.equipment = { weapon:noone, offhand:noone, armor:noone, helm:noone, accessory:noone };
          }
     }

     // --- REMOVED Instance variables for stats/equipment/inventory/skills ---
     // hp_total = 40; hp = hp_total; // REMOVED
     // mp_total = 20; mp = mp_total; // REMOVED
     // atk = 10; def = 5; // REMOVED
     // ... etc for other stats ... // REMOVED
     // equipment = { ... }; // REMOVED
     // skills = [ ... ]; // REMOVED (Skills now stored in map)
     // inventory = [ ... ]; // REMOVED (Inventory is global)
     // level = 1; xp = 0; xp_require = ...; // REMOVED

} // End !variable_instance_exists(id, "persistent_data_initialized")