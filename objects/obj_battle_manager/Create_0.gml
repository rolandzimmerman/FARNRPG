/// obj_battle_manager :: Create Event
// Initializes battle state, variables, spawns ALL party members and enemies.

show_debug_message("--- Battle Manager Create START --- Received Formation: " + string(global.battle_formation));

/// ── Tweak these to shift ALL spawns ──
var spawn_offset_x = -192;
var spawn_offset_y = -192;

// ── 1) Initialize or Clear DS Lists ──
if (variable_global_exists("battle_enemies") && ds_exists(global.battle_enemies, ds_type_list)) {
    ds_list_destroy(global.battle_enemies);
}
global.battle_enemies = ds_list_create();

if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) {
    ds_list_destroy(global.battle_party);
}
global.battle_party = ds_list_create();

// ── 2) Initial battle state ──
global.battle_state             = "player_input";
global.battle_target            = 0;
global.enemy_turn_index         = 0;
total_xp_from_battle            = 0;
stored_action_data              = undefined;
selected_target_id              = noone;
global.active_party_member_index = 0;

// ── 3) Spawn ALL Party Members at custom positions ──
show_debug_message("--- Spawning Party Members ---");

var party_positions = [
    [576, 672, 1.00],
    [768+100, 416+192, 0.80],
    [352, 480, 0.90],
    [544, 256, 0.75]
];

if (variable_global_exists("party_members") && is_array(global.party_members)) {
    var _party_size = array_length(global.party_members);
    show_debug_message("  Found " + string(_party_size) + " members in global.party_members");
    show_debug_message("📋 Contents of global.party_members: " + string(global.party_members));

    var spawn_layer_player = layer_exists("Instances_Battle") ? "Instances_Battle" : "Instances";
    if (!layer_exists(spawn_layer_player)) {
        show_debug_message("FATAL: Layer '" + spawn_layer_player + "' missing!");
        instance_destroy();
        exit;
    }

    for (var i = 0; i < _party_size; i++) {
        if (i >= array_length(party_positions)) break;
        var char_key = global.party_members[i];
        var pos = party_positions[i];
        var px = pos[0] + spawn_offset_x;
        var py = pos[1] + spawn_offset_y;
        var sc = pos[2];

        show_debug_message("  Spawning party slot " + string(i) + " at ("+string(px)+","+string(py)+") scale "+string(sc));

        var p_inst = instance_create_layer(px, py, spawn_layer_player, obj_battle_player);
        if (p_inst != noone) {
            p_inst.image_xscale = sc;
            p_inst.image_yscale = sc;
            p_inst.data = scr_GetPlayerData(char_key);

            if (!is_struct(p_inst.data)) {
                show_debug_message("    -> ⚠️ scr_GetPlayerData returned INVALID for " + string(char_key));
            } else {
                show_debug_message("    -> ✅ scr_GetPlayerData for " + string(char_key) + " returned level " + string(p_inst.data.level) + " with " + string(array_length(p_inst.data.skills)) + " skills");
            }

            if (is_struct(p_inst.data)) {
                p_inst.data.party_slot_index = i;
                ds_list_add(global.battle_party, p_inst);
                show_debug_message("    -> SUCCESS: Party member created and added.");
            } else {
                show_debug_message("    -> ⚠️ FAILED: invalid data struct, destroying instance.");
                instance_destroy(p_inst);
            }
        } else {
            show_debug_message("    -> ⚠️ FAILED to create obj_battle_player instance.");
        }
    }
} else {
    show_debug_message("❌ Cannot start battle: global.party_members not found or not an array!");
    instance_destroy();
    exit;
}
show_debug_message("--- Finished Party spawn, count: " + string(ds_list_size(global.battle_party)));

// ── 4) Spawn ALL Enemies at custom positions ──
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
    show_debug_message("  Expecting to spawn " + string(_num) + " enemies.");

    var spawn_layer_enemy = layer_exists("Instances_Battle") ? "Instances_Battle" : "Instances";
    if (!layer_exists(spawn_layer_enemy)) {
        show_debug_message("FATAL: Layer '" + spawn_layer_enemy + "' missing!");
    } else {
        for (var i = 0; i < _num; ++i) {
            var type = form[i];
            if (!object_exists(type)) continue;

            var ex, ey, esc;
            if (i < array_length(enemy_positions)) {
                ex  = enemy_positions[i][0] + spawn_offset_x;
                ey  = enemy_positions[i][1] + spawn_offset_y;
                esc = enemy_positions[i][2];
            } else {
                ex  = 980  + spawn_offset_x;
                ey  = 120 + i*180 + spawn_offset_y;
                esc = 1;
            }

            show_debug_message("  Spawning enemy " + string(i) +
                               " (" + object_get_name(type) + ") at ("+
                               string(ex)+","+string(ey)+") scale "+string(esc));

            var e = instance_create_layer(ex, ey, spawn_layer_enemy, type);
            if (e != noone) {
                e.image_xscale = esc;
                e.image_yscale = esc;
                e.data = scr_GetEnemyDataFromName(type);
                ds_list_add(global.battle_enemies, e);
                show_debug_message("    -> Enemy created ID: " + string(e));
            }
        }
    }
} else {
    global.battle_formation = [];
}
show_debug_message("--- Finished Enemy spawn, count: " + string(ds_list_size(global.battle_enemies)));

// ── 5) Check for instant end ──
if (ds_list_size(global.battle_enemies) == 0) {
    global.battle_state = "victory";
    alarm[0] = 5;
} else if (ds_list_size(global.battle_party) == 0) {
    global.battle_state = "defeat";
    alarm[0] = 5;
} else {
    global.battle_target = 0;
}

// ── 6) Create the battle menu UI ──
if (!instance_exists(obj_battle_menu)) {
    var _ml = layer_exists("Instances_GUI") ? "Instances_GUI" : "Instances";
    if (layer_exists(_ml)) {
        instance_create_layer(0, 0, _ml, obj_battle_menu);
    }
}

show_debug_message("🧱 Battle Manager Create DONE. State: " + global.battle_state);
