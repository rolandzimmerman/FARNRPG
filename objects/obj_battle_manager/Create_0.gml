/// obj_battle_manager :: Create Event
// Initializes battle state, variables, spawns party and enemies, creates status map, sets up speed queue.

show_debug_message("--- Battle Manager Create START --- Received Formation: " + string(global.battle_formation ?? "UNDEFINED"));

var spawn_offset_x = -192;
var spawn_offset_y = -192;

// Speed Queue Configuration
BASE_TICK_VALUE = 10000; // Base value for turn counter calculations
TURN_ORDER_DISPLAY_COUNT = 6; // How many turns ahead to show in the UI

// State Management using Strings (User's original + new states)
// global.battle_state will be used as the primary state variable
// currentState = "initializing"; // Using global.battle_state directly

// Combatant Management & Turn Order
combatants_all = ds_list_create(); // Holds ALL combatants (players + enemies) for speed queue calculation
currentActor = noone;              // Instance ID of the combatant whose turn it is
turnOrderDisplay = [];             // Array to store predicted turn order instance IDs

// Initialize/Clear Global DS Lists (keeping your existing structure)
if (variable_global_exists("battle_enemies") && ds_exists(global.battle_enemies, ds_type_list)) {
    ds_list_clear(global.battle_enemies); // Clear instead of destroy if reusing list ID
} else {
    global.battle_enemies = ds_list_create();
}

if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) {
     ds_list_clear(global.battle_party); // Clear instead of destroy
} else {
    global.battle_party = ds_list_create();
}

show_debug_message(" -> Using existing or new battle_enemies list (ID: " + string(global.battle_enemies) + ")");
show_debug_message(" -> Using existing or new battle_party list (ID: " + string(global.battle_party) + ")");

// <<< Initialize Global Status Effect Map >>>
if (variable_global_exists("battle_status_effects") && ds_exists(global.battle_status_effects, ds_type_map)) {
    ds_map_destroy(global.battle_status_effects); // Keep destroying/creating this one seems fine
}
global.battle_status_effects = ds_map_create();
show_debug_message(" -> Created new empty battle_status_effects map (ID: " + string(global.battle_status_effects) + ")");

// Initial battle variables (some may become redundant or managed differently)
global.battle_state               = "initializing"; // Start in initializing state using the global variable
global.battle_target              = 0; // Still used for player targeting index
global.enemy_turn_index           = 0; // Kept for compatibility if any UI element reads it, but not used for turn logic
total_xp_from_battle            = 0;
stored_action_data              = undefined; // Still used for player action choice
selected_target_id              = noone;     // Still used for player action target
global.active_party_member_index = -1; // Initialize to -1, set when player turn starts

// --- Spawn Party Members ---
show_debug_message("--- Spawning Party Members ---");
var party_positions = [
    [576, 672, 1.00],
    [768 + 100, 416 + 192, 0.80],
    [352, 480, 0.90],
    [544, 256, 0.75]
];

if (variable_global_exists("party_members") && is_array(global.party_members)) {
    var _party_size = array_length(global.party_members);
    show_debug_message("  Found " + string(_party_size) + " members");

    var spawn_layer_player = layer_get_id("Instances_Battle");
    if (spawn_layer_player == -1) spawn_layer_player = layer_get_id("Instances");
    if (spawn_layer_player == -1) {
        show_debug_message("FATAL: Layer missing!");
        instance_destroy();
        exit;
    }

    for (var i = 0; i < _party_size; i++) {
        if (i >= array_length(party_positions)) break;
        var char_key = global.party_members[i];
        var pos      = party_positions[i];
        var px       = pos[0] + spawn_offset_x;
        var py       = pos[1] + spawn_offset_y;
        var sc       = pos[2];

        show_debug_message("  Spawning party slot " + string(i) + " key: " + char_key);
        var p_inst = instance_create_layer(px, py, spawn_layer_player, obj_battle_player);
        if (p_inst != noone) {
            // Scale & identify
            p_inst.image_xscale  = sc;
            p_inst.image_yscale  = sc;
            p_inst.character_key = char_key; // Keep this for referencing persistent data

            // Fetch persistent + equipped stats
            var _base_stats = scr_GetPlayerData(char_key);
             var _fallback_data = { // Define fallback once
                hp:1, maxhp:1, mp:0, maxmp:0,
                atk:1, def:1, matk:1, mdef:1, spd:1, luk:1, // Ensure spd exists!
                level:1, xp:0, xp_require:100,
                skills:[], skill_index:0, item_index:0,
                equipment:{weapon:noone,offhand:noone,armor:noone,helm:noone,accessory:noone},
                is_defending:false,
                overdrive:0, overdrive_max:100,
                name: "Fallback", // Added name for consistency
                character_key: char_key // Store key in data too
            };
            
            if (is_struct(_base_stats)) {
                var _calculated_stats = scr_CalculateEquippedStats(_base_stats);
                if (is_struct(_calculated_stats) && instance_exists(p_inst)) {
                    // Assign the main battle data
                    p_inst.data = _calculated_stats;
                    
                    // Ensure essential fields exist if calculation script missed them
                    if (!variable_struct_exists(p_inst.data, "spd")) p_inst.data.spd = _fallback_data.spd;
                    if (!variable_struct_exists(p_inst.data, "hp")) p_inst.data.hp = _fallback_data.hp;
                    if (!variable_struct_exists(p_inst.data, "maxhp")) p_inst.data.maxhp = _fallback_data.maxhp;
                    if (!variable_struct_exists(p_inst.data, "name")) p_inst.data.name = _base_stats.name ?? _fallback_data.name;
                     if (!variable_struct_exists(p_inst.data, "character_key")) p_inst.data.character_key = char_key;


                    // Carry over overdrive fields
                    p_inst.data.overdrive     = _base_stats.overdrive ?? 0;
                    p_inst.data.overdrive_max = _base_stats.overdrive_max ?? 100;

                    show_debug_message("    -> Assigned stats with OD="
                        + string(p_inst.data.overdrive) + "/"
                        + string(p_inst.data.overdrive_max));
                } else {
                    p_inst.data = _fallback_data; // Use fallback
                }
            } else {
                 p_inst.data = _fallback_data; // Use fallback
            }

            // Track original party slot if needed for UI ordering, but not turn order
            p_inst.data.party_slot_index = i; 
            ds_list_add(global.battle_party, p_inst);
            
            // NEW: Add to combined list and initialize turn counter
            ds_list_add(combatants_all, p_inst);
            p_inst.turnCounter = BASE_TICK_VALUE / max(1, p_inst.data.spd); // Initialize based on speed
            show_debug_message("    -> Initial turnCounter: " + string(p_inst.turnCounter) + " (Spd: " + string(p_inst.data.spd) + ")");
        }
    }
} else {
    show_debug_message("❌ Cannot start battle: global.party_members missing");
    instance_destroy();
    exit;
}
show_debug_message("--- Finished Party spawn, count: " + string(ds_list_size(global.battle_party)) + " ---");

// --- Spawn Enemies ---
show_debug_message("--- Spawning Enemies ---");
var enemy_positions = [
    [1632, 800, 1.10],
    [1504, 544, 0.90],
    [1344, 288, 0.75],
    [1792, 576, 1.00],
    [1664, 320, 0.80]
];

if (variable_global_exists("battle_formation") && is_array(global.battle_formation)) {
    var form = global.battle_formation;
    var _num = array_length(form);
    show_debug_message("  Formation Array Contents: " + string(form));
    show_debug_message("  Expecting to spawn " + string(_num) + " enemies.");

    var spawn_layer_enemy = layer_get_id("Instances_Battle");
    if (spawn_layer_enemy == -1) spawn_layer_enemy = layer_get_id("Instances");

    if (spawn_layer_enemy != -1) {
        for (var i = 0; i < _num; ++i) {
            var type = form[i];
            if (!object_exists(type)) continue;

            var ex, ey, esc;
            if (i < array_length(enemy_positions)) {
                ex  = enemy_positions[i][0] + spawn_offset_x;
                ey  = enemy_positions[i][1] + spawn_offset_y;
                esc = enemy_positions[i][2];
            } else {
                ex  = 980 + spawn_offset_x;
                ey  = 120 + i * 180 + spawn_offset_y;
                esc = 1;
            }

            show_debug_message("    -> Attempting to spawn " + object_get_name(type)
                + " at ("+string(ex)+","+string(ey)+")");
            var e = instance_create_layer(ex, ey, spawn_layer_enemy, type);
            if (instance_exists(e)) {
                show_debug_message("      -> Instance Created (ID: " + string(e) + ")");
                e.image_xscale = esc;
                e.image_yscale = esc;
                
                // Assign enemy data
                var enemy_data = {}; // Default empty
                 if (script_exists(scr_GetEnemyDataFromName)) {
                    enemy_data = scr_GetEnemyDataFromName(type);
                 }
                 // Ensure essential fields exist
                 if (!is_struct(enemy_data)) enemy_data = {};
                 if (!variable_struct_exists(enemy_data, "hp")) enemy_data.hp = 10;
                 if (!variable_struct_exists(enemy_data, "maxhp")) enemy_data.maxhp = 10;
                 if (!variable_struct_exists(enemy_data, "spd")) enemy_data.spd = 5; // Crucial fallback
                 if (!variable_struct_exists(enemy_data, "name")) enemy_data.name = object_get_name(type);
                 
                 e.data = enemy_data; // Assign the struct to the instance
                 
                 show_debug_message("      -> Assigned data. HP: " + string(e.data.hp) + " Spd: " + string(e.data.spd));


                if (ds_exists(global.battle_enemies, ds_type_list)) {
                    ds_list_add(global.battle_enemies, e);
                    show_debug_message("      -> Enemy list size now: " + string(ds_list_size(global.battle_enemies)));
                }
                
                // NEW: Add to combined list and initialize turn counter
                ds_list_add(combatants_all, e);
                e.turnCounter = BASE_TICK_VALUE / max(1, e.data.spd);
                show_debug_message("      -> Initial turnCounter: " + string(e.turnCounter) + " (Spd: " + string(e.data.spd) + ")");

            } else {
                show_debug_message("    -> FAILED to create enemy instance!");
            }
        }
    } else {
        show_debug_message("FATAL: Layer missing for enemies!");
    }
} else {
    global.battle_formation = []; // Ensure it's an empty array if not defined
}
show_debug_message("--- Finished Enemy spawn, count: " + string(ds_list_size(global.battle_enemies)) + " ---");
show_debug_message("--- Total Combatants for Speed Queue: " + string(ds_list_size(combatants_all)) + " ---");

// --- Create Battle Menu ---
show_debug_message("--- Creating battle menu ---");
if (!instance_exists(obj_battle_menu)) {
    var _ml = layer_get_id("Instances_GUI");
    if (_ml == -1) _ml = layer_get_id("Instances");
    if (_ml != -1) {
        instance_create_layer(0, 0, _ml, obj_battle_menu);
        show_debug_message(" -> obj_battle_menu instance created.");
    } else {
        show_debug_message(" -> ERROR: Could not find layer for obj_battle_menu!");
    }
} else {
    show_debug_message(" -> obj_battle_menu instance already exists.");
}

// --- Final Initialization ---
// Calculate initial turn order display
if (script_exists(scr_CalculateTurnOrderDisplay)) {
     turnOrderDisplay = scr_CalculateTurnOrderDisplay(combatants_all, BASE_TICK_VALUE, TURN_ORDER_DISPLAY_COUNT);
     show_debug_message(" -> Calculated initial turn order display.");
}

// Set state to start the turn calculation loop
global.battle_state = "calculate_turn"; // Use new string state to start the loop
show_debug_message("🧱 Battle Manager Create DONE. Initial State: " + global.battle_state);