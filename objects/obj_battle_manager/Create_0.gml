/// obj_battle_manager :: Create Event
// Initializes battle state, variables, spawns party and enemies, creates status map.

show_debug_message("--- Battle Manager Create START --- Received Formation: " + string(global.battle_formation ?? "UNDEFINED"));

var spawn_offset_x = -192; var spawn_offset_y = -192;
// Initialize/Clear DS Lists
if (variable_global_exists("battle_enemies") && ds_exists(global.battle_enemies, ds_type_list)) { ds_list_destroy(global.battle_enemies); } global.battle_enemies = ds_list_create();
if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) { ds_list_destroy(global.battle_party); } global.battle_party = ds_list_create();
show_debug_message(" -> Created new empty battle_enemies list (ID: " + string(global.battle_enemies) + ")");
show_debug_message(" -> Created new empty battle_party list (ID: " + string(global.battle_party) + ")");

// <<< Initialize Global Status Effect Map >>>
if (variable_global_exists("battle_status_effects") && ds_exists(global.battle_status_effects, ds_type_map)) { ds_map_destroy(global.battle_status_effects); }
global.battle_status_effects = ds_map_create();
show_debug_message(" -> Created new empty battle_status_effects map (ID: " + string(global.battle_status_effects) + ")");

// Initial battle state variables
global.battle_state = "player_input"; global.battle_target = 0; global.enemy_turn_index = 0; total_xp_from_battle = 0; stored_action_data = undefined; selected_target_id = noone; global.active_party_member_index = 0;

// --- Spawn Party Members ---
show_debug_message("--- Spawning Party Members ---");
var party_positions = [ [576, 672, 1.00], [768+100, 416+192, 0.80], [352, 480, 0.90], [544, 256, 0.75] ];
if (variable_global_exists("party_members") && is_array(global.party_members)) {
    var _party_size = array_length(global.party_members); show_debug_message("  Found " + string(_party_size) + " members");
    var spawn_layer_player = layer_get_id("Instances_Battle"); if (spawn_layer_player == -1) spawn_layer_player = layer_get_id("Instances"); if (spawn_layer_player == -1) { show_debug_message("FATAL: Layer missing!"); instance_destroy(); exit; }
    for (var i = 0; i < _party_size; i++) {
        if (i >= array_length(party_positions)) break;
        var char_key = global.party_members[i]; var pos = party_positions[i]; var px = pos[0] + spawn_offset_x; var py = pos[1] + spawn_offset_y; var sc = pos[2];
        show_debug_message("  Spawning party slot " + string(i) + " key: " + char_key);
        var p_inst = instance_create_layer(px, py, spawn_layer_player, obj_battle_player);
        if (p_inst != noone) {
            p_inst.image_xscale = sc; p_inst.image_yscale = sc; p_inst.character_key = char_key;
            var _base_stats = scr_GetPlayerData(char_key);
            if (is_struct(_base_stats)) { var _calculated_stats = scr_CalculateEquippedStats(_base_stats); if (is_struct(_calculated_stats) && instance_exists(p_inst)) { show_debug_message("    -> scr_CalculateEquippedStats RETURNED HP: " + string(_calculated_stats.hp ?? "ERR")); p_inst.data = _calculated_stats; if (variable_instance_exists(p_inst, "data") && is_struct(p_inst.data)) { show_debug_message("    -> p_inst.data AFTER assignment: HP=" + string(p_inst.data.hp ?? "ERR")); } else { show_debug_message("    -> p_inst.data is invalid AFTER assignment!"); } } else { if(instance_exists(p_inst)) p_inst.data = { hp: 1 }; } } else { if(instance_exists(p_inst)) p_inst.data = { hp: 1 }; }
            if (is_struct(p_inst.data)) { p_inst.data.party_slot_index = i; if(ds_exists(global.battle_party, ds_type_list)){ ds_list_add(global.battle_party, p_inst); } else { show_debug_message("   -> ERROR: global.battle_party invalid before adding player!");} } else { if(instance_exists(p_inst)) instance_destroy(p_inst); }
        }
    }
} else { show_debug_message("❌ Cannot start battle: global.party_members missing"); instance_destroy(); exit; }
show_debug_message("--- Finished Party spawn, count: " + string(ds_exists(global.battle_party, ds_type_list) ? ds_list_size(global.battle_party) : "INVALID"));

// --- Spawn Enemies ---
show_debug_message("--- Spawning Enemies ---");
var enemy_positions = [ [1632, 800, 1.10], [1504, 544, 0.90], [1344, 288, 0.75], [1792, 576, 1.00], [1664, 320, 0.80] ];
if (variable_global_exists("battle_formation") && is_array(global.battle_formation)) {
    var form = global.battle_formation; var _num = array_length(form); show_debug_message("  Formation Array Contents: " + string(form)); show_debug_message("  Expecting to spawn " + string(_num) + " enemies.");
    var spawn_layer_enemy = layer_get_id("Instances_Battle"); if (spawn_layer_enemy == -1) spawn_layer_enemy = layer_get_id("Instances");
    if (spawn_layer_enemy != -1) {
        for (var i = 0; i < _num; ++i) {
            var type = form[i]; show_debug_message("   -> Processing formation index " + string(i) + ", type: " + string(type) + " (Is Object? " + string(object_exists(type)) + ")"); if (!object_exists(type)) { continue; }
            var ex, ey, esc; if (i < array_length(enemy_positions)) { ex=enemy_positions[i][0]+spawn_offset_x; ey=enemy_positions[i][1]+spawn_offset_y; esc=enemy_positions[i][2]; } else { ex=980+spawn_offset_x; ey=120+i*180+spawn_offset_y; esc=1; }
            show_debug_message("   -> Attempting to spawn " + object_get_name(type) + " at (" + string(ex)+","+string(ey)+")"); var e = instance_create_layer(ex, ey, spawn_layer_enemy, type);
            if (instance_exists(e)) {
                show_debug_message("     -> Instance Created (ID: " + string(e) + ")"); e.image_xscale = esc; e.image_yscale = esc; if (script_exists(scr_GetEnemyDataFromName)) { e.data = scr_GetEnemyDataFromName(type); if (!is_struct(e.data)) { /* Warning */ } } else { /* Error */ }
                var _list_id_before = global.battle_enemies; show_debug_message("     -> BEFORE ds_list_add: List ID=" + string(_list_id_before) + ", Size=" + string(ds_list_size(_list_id_before)) + ", Adding Instance=" + string(e));
                if(ds_exists(_list_id_before, ds_type_list)){ ds_list_add(global.battle_enemies, e); show_debug_message("     -> AFTER ds_list_add: New Size=" + string(ds_list_size(global.battle_enemies))); } else { show_debug_message("     -> !!! ERROR: global.battle_enemies is NOT valid list! !!!"); }
            } else { show_debug_message("   -> FAILED to create enemy instance!"); }
        } // End for loop
    } else { show_debug_message("FATAL: Layer missing for enemies!"); }
} else { global.battle_formation = []; }
show_debug_message("--- Finished Enemy spawn, final count in global.battle_enemies: " + string(ds_exists(global.battle_enemies, ds_type_list) ? ds_list_size(global.battle_enemies) : "INVALID"));

// --- Check for instant end / Create Menu ---
if (ds_exists(global.battle_enemies, ds_type_list) && ds_list_size(global.battle_enemies) == 0 && ds_exists(global.battle_party, ds_type_list) && ds_list_size(global.battle_party) > 0) { global.battle_state = "victory"; alarm[0] = 5; } else if (ds_exists(global.battle_party, ds_type_list) && ds_list_size(global.battle_party) == 0) { global.battle_state = "defeat"; alarm[0] = 5; } else if (ds_exists(global.battle_enemies, ds_type_list) && ds_list_size(global.battle_enemies) > 0) { global.battle_target = 0; } else { global.battle_target = -1; }
show_debug_message("--- Attempting to create battle menu ---");
if (!instance_exists(obj_battle_menu)) { var _ml = layer_get_id("Instances_GUI"); if (_ml == -1) _ml = layer_get_id("Instances"); if (_ml != -1) { instance_create_layer(0, 0, _ml, obj_battle_menu); show_debug_message(" -> obj_battle_menu instance created."); } else { show_debug_message(" -> ERROR: Could not find layer for obj_battle_menu!"); } } else { show_debug_message(" -> obj_battle_menu instance already exists."); }

show_debug_message("🧱 Battle Manager Create DONE. State: " + global.battle_state);