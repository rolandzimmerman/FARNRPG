/// obj_battle_manager :: Create Event
// Initializes battle state, variables, spawns ALL party members and enemies.

show_debug_message("--- Battle Manager Create START --- Received Formation: " + string(global.battle_formation));

// --- 1) Initialize or Clear DS Lists ---
if (variable_global_exists("battle_enemies")) { if (ds_exists(global.battle_enemies, ds_type_list)) { ds_list_destroy(global.battle_enemies); } } global.battle_enemies = ds_list_create();
if (variable_global_exists("battle_party")) { if (ds_exists(global.battle_party, ds_type_list)) { ds_list_destroy(global.battle_party); } } global.battle_party = ds_list_create(); // This list holds BATTLE instances

// 2) Initial battle state
global.battle_state = "player_input"; global.battle_target = 0; global.enemy_turn_index = 0;
total_xp_from_battle = 0; stored_action_data = undefined; selected_target_id = noone;
global.active_party_member_index = 0; // Index of the current acting party member

// --- 3) Spawn ALL Party Members ---
show_debug_message("--- Spawning Party Members ---");
if (variable_global_exists("party_members") && is_array(global.party_members)) {
    show_debug_message("  Current global.party_members: " + string(global.party_members));
    var _party_size = array_length(global.party_members);
    show_debug_message("  Found " + string(_party_size) + " members in global party list.");

    var spawn_layer_player = layer_exists("Instances_Battle") ? "Instances_Battle" : "Instances";
    if (!layer_exists(spawn_layer_player)) { show_debug_message("FATAL: Layer '" + spawn_layer_player + "' missing!"); instance_destroy(); exit; }

    // Define starting positions for party members
    var start_x = 300;
    var start_y = 120;
    // --- ADJUSTED SPACING ---
    var player_sprite_height = 192; // Your sprite height
    var y_spacing = player_sprite_height + 20; // Height + 20 pixels padding
    // --- END ADJUSTMENT ---

    for (var i = 0; i < _party_size; i++) {
        var char_key = global.party_members[i];
        show_debug_message("  Spawning member " + string(i) + ": Key='" + char_key + "'");

        var current_x = start_x;
        var current_y = start_y + (i * y_spacing); // Use updated spacing
        var p_inst = instance_create_layer(current_x, current_y, spawn_layer_player, obj_battle_player);

        if (p_inst != noone) {
            p_inst.data = scr_GetPlayerData(char_key);
            if (is_struct(p_inst.data)) {
                 p_inst.data.party_slot_index = i;
                 ds_list_add(global.battle_party, p_inst);
                 show_debug_message("    -> SUCCESS: Assigned data and added to battle party.");
            } else {
                 show_debug_message("    -> ⚠️ FAILED: scr_GetPlayerData returned invalid data. Destroying instance.");
                 instance_destroy(p_inst);
            }
        } else { show_debug_message("    -> ⚠️ FAILED to create obj_battle_player instance."); }
    } // End party member loop

} else { show_debug_message("❌ Cannot start battle: global.party_members list not found!"); instance_destroy(); exit; }
show_debug_message("--- Finished Spawning Party --- Final Battle Party Size: " + string(ds_list_size(global.battle_party)));


// --- 4) Spawn enemies ---
if (variable_global_exists("battle_formation") && is_array(global.battle_formation)) { var form = global.battle_formation; var _num = array_length(form); show_debug_message("--- Spawning Enemies (Expected Size: " + string(_num) + ") ---"); for (var i = 0; i < _num; ++i) { var type = form[i]; if (!object_exists(type)) continue; var ex = 980; var ey = 120 + i*180; var sle = layer_exists("Instances_Battle") ? "Instances_Battle" : "Instances"; if (!layer_exists(sle)) continue; var e = instance_create_layer(ex, ey, sle, type); if (e == noone) continue; e.data = scr_GetEnemyDataFromName(type); ds_list_add(global.battle_enemies, e); if (is_struct(e.data)) { /* Log Spawn */ } } } else { global.battle_formation = []; }


// 5) Check if battle should end immediately
if (ds_list_size(global.battle_enemies) == 0) { global.battle_state = "victory"; alarm[0] = 5; }
else if (ds_list_size(global.battle_party) == 0) { global.battle_state = "defeat"; alarm[0] = 5; }
else { global.battle_target = 0; }

// --- 6) CREATE BATTLE MENU INSTANCE ---
if (!instance_exists(obj_battle_menu)) { var _ml = layer_exists("Instances_GUI") ? "Instances_GUI" : "Instances"; if (layer_exists(_ml)) instance_create_layer(0, 0, _ml, obj_battle_menu); }

show_debug_message("🧱 Battle Manager Create Done. Final State: " + global.battle_state);