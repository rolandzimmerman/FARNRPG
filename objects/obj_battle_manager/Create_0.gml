/// obj_battle_manager :: Create Event
// Initializes battle state, variables, spawns party and enemies, creates status map.

show_debug_message("--- Battle Manager Create START --- Received Formation: " + string(global.battle_formation ?? "UNDEFINED"));

var spawn_offset_x = -192;
var spawn_offset_y = -192;

// Initialize/Clear DS Lists
if (variable_global_exists("battle_enemies") && ds_exists(global.battle_enemies, ds_type_list)) {
    ds_list_destroy(global.battle_enemies);
}
global.battle_enemies = ds_list_create();

if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) {
    ds_list_destroy(global.battle_party);
}
global.battle_party = ds_list_create();

show_debug_message(" -> Created new empty battle_enemies list (ID: " + string(global.battle_enemies) + ")");
show_debug_message(" -> Created new empty battle_party list (ID: " + string(global.battle_party) + ")");

// <<< Initialize Global Status Effect Map >>>
if (variable_global_exists("battle_status_effects") && ds_exists(global.battle_status_effects, ds_type_map)) {
    ds_map_destroy(global.battle_status_effects);
}
global.battle_status_effects = ds_map_create();
show_debug_message(" -> Created new empty battle_status_effects map (ID: " + string(global.battle_status_effects) + ")");

// Initial battle state variables
global.battle_state              = "player_input";
global.battle_target             = 0;
global.enemy_turn_index          = 0;
total_xp_from_battle             = 0;
stored_action_data               = undefined;
selected_target_id               = noone;
global.active_party_member_index = 0;

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
            p_inst.character_key = char_key;

            // Fetch persistent + equipped stats (now including overdrive fields)
            var _base_stats = scr_GetPlayerData(char_key);
            if (is_struct(_base_stats)) {
                var _calculated_stats = scr_CalculateEquippedStats(_base_stats);
                if (is_struct(_calculated_stats) && instance_exists(p_inst)) {
                    // Assign the main battle data
                    p_inst.data = _calculated_stats;

                    // ★ ENSURE overdrive fields are carried over ★
                    p_inst.data.overdrive     = _base_stats.overdrive;
                    p_inst.data.overdrive_max = _base_stats.overdrive_max;

                    show_debug_message("    -> Assigned stats with OD="
                        + string(p_inst.data.overdrive) + "/"
                        + string(p_inst.data.overdrive_max));
                }
                else {
                    // Fallback minimal struct (with OD)
                    p_inst.data = {
                        hp:1, maxhp:1,
                        mp:0, maxmp:0,
                        atk:1, def:1, matk:1, mdef:1, spd:1, luk:1,
                        level:1, xp:0, xp_require:100,
                        skills:[], skill_index:0, item_index:0,
                        equipment:{weapon:noone,offhand:noone,armor:noone,helm:noone,accessory:noone},
                        is_defending:false,
                        overdrive:0,
                        overdrive_max:100
                    };
                }
            }
            else {
                // If scr_GetPlayerData failed entirely
                p_inst.data = {
                    hp:1, maxhp:1,
                    mp:0, maxmp:0,
                    atk:1, def:1, matk:1, mdef:1, spd:1, luk:1,
                    level:1, xp:0, xp_require:100,
                    skills:[], skill_index:0, item_index:0,
                    equipment:{weapon:noone,offhand:noone,armor:noone,helm:noone,accessory:noone},
                    is_defending:false,
                    overdrive:0,
                    overdrive_max:100
                };
            }

            // Track slot and add to party list
            p_inst.data.party_slot_index = i;
            ds_list_add(global.battle_party, p_inst);
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

            show_debug_message("   -> Attempting to spawn " + object_get_name(type)
                + " at ("+string(ex)+","+string(ey)+")");
            var e = instance_create_layer(ex, ey, spawn_layer_enemy, type);
            if (instance_exists(e)) {
                show_debug_message("     -> Instance Created (ID: " + string(e) + ")");
                e.image_xscale = esc;
                e.image_yscale = esc;
                if (script_exists(scr_GetEnemyDataFromName)) {
                    e.data = scr_GetEnemyDataFromName(type);
                }
                if (ds_exists(global.battle_enemies, ds_type_list)) {
                    ds_list_add(global.battle_enemies, e);
                    show_debug_message("     -> Enemy list size now: " + string(ds_list_size(global.battle_enemies)));
                }
            } else {
                show_debug_message("   -> FAILED to create enemy instance!");
            }
        }
    } else {
        show_debug_message("FATAL: Layer missing for enemies!");
    }
} else {
    global.battle_formation = [];
}
show_debug_message("--- Finished Enemy spawn, count: " + string(ds_list_size(global.battle_enemies)) + " ---");

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

show_debug_message("🧱 Battle Manager Create DONE. State: " + global.battle_state);
