/// obj_battle_manager :: Create Event
// Initializes battle state, variables, spawns player/enemies.
// UI Layer visibility is handled by obj_battle_menu Draw GUI event.

show_debug_message("--- Battle Manager Create START --- Received Formation: " + string(global.battle_formation));

// --- 1) Initialize or Clear DS Lists ---
if (variable_global_exists("battle_enemies")) { if (ds_exists(global.battle_enemies, ds_type_list)) { ds_list_destroy(global.battle_enemies); } } global.battle_enemies = ds_list_create();
if (variable_global_exists("battle_party")) { if (ds_exists(global.battle_party, ds_type_list)) { ds_list_destroy(global.battle_party); } } global.battle_party = ds_list_create();

// 2) Initial battle state
global.battle_state = "player_input"; global.battle_target = 0; global.enemy_turn_index = 0;
total_xp_from_battle = 0; stored_action_data = undefined; selected_target_id = noone;

// --- 3) Spawn your single hero & Assign Data ---
if (instance_exists(obj_player)) {
    var spawn_layer_player = layer_exists("Instances_Battle") ? "Instances_Battle" : "Instances";
    if (!layer_exists(spawn_layer_player)) { show_debug_message("FATAL: Layer '" + spawn_layer_player + "' missing!"); instance_destroy(); exit; }
    var p = instance_create_layer(300, 120, spawn_layer_player, obj_battle_player);
    if (p != noone) { p.data = scr_GetPlayerData(); ds_list_add(global.battle_party, p); show_debug_message(" -> Created battle player instance ID: " + string(p)); }
    else { show_debug_message(" -> ⚠️ FAILED to create obj_battle_player instance!"); instance_destroy(); exit; }
} else { show_debug_message("❌ Cannot start battle: obj_player does not exist!"); instance_destroy(); exit; }


// --- 4) Spawn enemies ---
if (variable_global_exists("battle_formation") && is_array(global.battle_formation)) {
    var form = global.battle_formation;
    var _num_enemies_to_spawn = array_length(form);
    show_debug_message("--- Spawning Enemies (Expected Size: " + string(_num_enemies_to_spawn) + ") ---");
    for (var i = 0; i < _num_enemies_to_spawn; ++i) {
        var type = form[i];
        if (!object_exists(type)) { show_debug_message("   ERROR: Invalid object index in formation at index " + string(i) + "!"); continue; }
        var ex = 980; var ey = 120 + i*180;
        var spawn_layer_enemy = layer_exists("Instances_Battle") ? "Instances_Battle" : "Instances";
        if (!layer_exists(spawn_layer_enemy)) { show_debug_message("   ERROR: Cannot find layer '" + spawn_layer_enemy + "' to spawn enemy."); continue; }
        var e = instance_create_layer(ex, ey, spawn_layer_enemy, type);
        if (e == noone) { show_debug_message("   ERROR: Failed to create instance of " + object_get_name(type)); continue; }
        e.data = scr_GetEnemyDataFromName(type);
        ds_list_add(global.battle_enemies, e);
        if (is_struct(e.data)) { show_debug_message(" Spawned Enemy ID: " + string(e) + " | HP: " + string(e.data.hp)); }
    }
} else { show_debug_message("   ERROR: global.battle_formation is missing or not an array!"); global.battle_formation = []; }

show_debug_message("--- Finished Spawning Enemies --- Final Enemy List Size: " + string(ds_list_size(global.battle_enemies)));

// 5) Check if battle should end immediately
if (ds_list_size(global.battle_enemies) == 0) {
    show_debug_message("⚠️ Create Event: No valid enemies were spawned. Setting state to victory.");
    global.battle_state = "victory"; alarm[0] = 5;
} else { global.battle_target = 0; }

// --- 6) CREATE BATTLE MENU INSTANCE (For HP/MP etc.) ---
if (!instance_exists(obj_battle_menu)) {
     var _ml = layer_exists("Instances_GUI") ? "Instances_GUI" : "Instances";
     if (layer_exists(_ml)) { instance_create_layer(0, 0, _ml, obj_battle_menu); }
     else { show_debug_message("WARNING: Cannot create obj_battle_menu - suitable layer not found!"); }
}

// --- Layer visibility code REMOVED ---

show_debug_message("🧱 Battle Manager Create Done. Final State: " + global.battle_state);
