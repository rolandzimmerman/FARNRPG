/// obj_battle_manager :: Alarm[0]
/// Handles timed transitions for Victory/Defeat processing, saving persistent stats, and cleaning up.

show_debug_message("⏰ BattleManager Alarm[0] Triggered — Current State: " + string(global.battle_state) + " !!!");

switch (global.battle_state) {

    case "victory": 
    {
        // <<< ADDED LOGGING >>>
        show_debug_message("🏆 Alarm 0: Processing Victory.");
        show_debug_message("    -> Final Accumulated XP: " + string(total_xp_from_battle));
        // <<< END LOGGING >>>
        
        var leveled_up_characters = [];
        if (ds_exists(global.battle_party, ds_type_list) && script_exists(scr_AddXPToCharacter)) { // <<< MAKE SURE scr_AddXPToCharacter EXISTS >>>
            var partyCount = ds_list_size(global.battle_party);
            show_debug_message("    -> Found " + string(partyCount) + " party members to potentially award XP.");
            for (var i = 0; i < partyCount; i++) {
                var inst = global.battle_party[| i];
                // Check if instance exists and is alive before awarding XP
                if (!instance_exists(inst) || !variable_instance_exists(inst, "data") || !is_struct(inst.data) || !variable_instance_exists(inst.data,"hp") || inst.data.hp <= 0) {
                     show_debug_message("    -> Skipping XP for instance " + string(inst) + " (Invalid or KO'd).");
                     continue; 
                }
                 // Check if character key exists
                if (!variable_struct_exists(inst.data, "character_key")) {
                     show_debug_message("    -> Skipping XP for instance " + string(inst) + " (Missing character_key).");
                     continue;
                }

                var key = inst.character_key; 
                show_debug_message("    -> Awarding " + string(total_xp_from_battle) + " XP to " + key + " (Instance: " + string(inst) + ")"); // Log award attempt
                
                // Call your XP script - Add logging INSIDE this script if possible!
                var didLevel = scr_AddXPToCharacter(key, total_xp_from_battle); 
                
                show_debug_message("    -> scr_AddXPToCharacter returned: " + string(didLevel) + " for " + key);
                if (didLevel && variable_struct_exists(inst.data, "name")) {
                     array_push(leveled_up_characters, inst.data.name);
                     show_debug_message("        -> " + key + " Leveled Up!");
                }
                 
                 // Refresh instance data from persistent store AFTER potentially leveling up
                 if (ds_exists(global.party_current_stats, ds_type_map) && ds_map_exists(global.party_current_stats, key)) {
                     var pers = ds_map_find_value(global.party_current_stats, key);
                     if (is_struct(pers) && instance_exists(inst)) { // Ensure instance still exists
                        // Update the instance's data struct directly for immediate reflection (e.g., in HUD if still visible)
                        inst.data.level      = pers.level ?? inst.data.level;
                        inst.data.xp         = pers.xp ?? inst.data.xp;
                        inst.data.xp_require = pers.xp_require ?? inst.data.xp_require;
                        // Update MaxHP/MaxMP/etc. on the instance if scr_AddXPToCharacter changed them
                        inst.data.maxhp      = pers.maxhp ?? inst.data.maxhp;
                        inst.data.maxmp      = pers.maxmp ?? inst.data.maxmp;
                        show_debug_message("        -> Refreshed instance data for " + key + " from persistent store.");
                     }
                 }
            }
        } else {
             show_debug_message("    -> ERROR: Cannot award XP (battle_party list or scr_AddXPToCharacter missing).");
        }

        // --- Build & show dialogue ---
        var messages = [];
        var xp_msg = "Gained " + string(total_xp_from_battle) + " XP!";
        array_push(messages, { name:"Victory!", msg: xp_msg });
        show_debug_message("    -> Dialogue Message 1: " + xp_msg); // Log message content
        if (array_length(leveled_up_characters) > 0) { 
            var upMsg = "";
            if (array_length(leveled_up_characters) == 1) { upMsg = leveled_up_characters[0] + " leveled up!"; } 
            else { for (var j = 0; j < array_length(leveled_up_characters); j++) { upMsg += leveled_up_characters[j]; if (j < array_length(leveled_up_characters) - 2) upMsg += ", "; else if (j == array_length(leveled_up_characters) - 2) upMsg += " and "; } upMsg += " leveled up!"; }
            array_push(messages, { name:"System", msg:upMsg }); 
            show_debug_message("    -> Dialogue Message 2: " + upMsg); 
        }
        
        show_debug_message("    -> Attempting to create dialogue box..."); // Log before creation
        // Use create_dialog if it exists, otherwise skip dialogue
        if (script_exists(create_dialog)) { // Assuming create_dialog handles obj_dialog creation
            var dlgLayer = layer_get_id("Instances_GUI") != -1 ? layer_get_id("Instances_GUI") : layer_get_id("Instances");
            if (dlgLayer != -1) {
                var dlg = create_dialog(messages); // Assuming create_dialog returns the instance ID
                if (instance_exists(dlg)) { 
                     show_debug_message("    -> Dialogue instance created via script (ID: " + string(dlg) + ") with messages."); 
                } else { show_debug_message("    -> ERROR: create_dialog script ran but failed to create instance!"); }
            } else { show_debug_message("    -> ERROR: No valid layer found for dialogue!"); }
        } else { show_debug_message("    -> ERROR: create_dialog script missing.");}

        // Queue return to field after showing results
        global.battle_state = "return_to_field"; 
        alarm[0]     = 120; // Delay before actually returning (adjust as needed for reading dialogue)
    }
    break;

    case "defeat": 
    { 
        show_debug_message("😭 Alarm 0: Processing Defeat.");
        if (script_exists(create_dialog)) { 
            var dLayer = layer_get_id("Instances_GUI") != -1 ? layer_get_id("Instances_GUI") : layer_get_id("Instances");
             if (dLayer != -1) {
                var defeatDlg = create_dialog([{ name:"Defeat", msg:"You have been defeated..." }]); 
                if(!instance_exists(defeatDlg)){show_debug_message("    -> ERROR: Failed to create defeat dialog instance!");}
             } else {show_debug_message("    -> ERROR: No valid layer found for defeat dialogue!");}
        } else { show_debug_message("    -> ERROR: create_dialog script missing."); }
        global.battle_state = "return_to_field"; 
        alarm[0]     = 120; 
    }
    break;

    case "return_to_field": 
    {
        show_debug_message("    Alarm 0: Returning to field map.");
        show_debug_message("    -> Saving persistent party stats (HP, MP)...");
        if (ds_exists(global.battle_party, ds_type_list) && ds_exists(global.party_current_stats, ds_type_map)) {
            var count = ds_list_size(global.battle_party);
            for (var i = 0; i < count; i++) {
                var inst = global.battle_party[| i];
                if (!instance_exists(inst) || !variable_instance_exists(inst, "data") || !is_struct(inst.data) || !variable_struct_exists(inst.data,"character_key")) continue;
                var key = inst.character_key; 
                if (!is_string(key) || !ds_map_exists(global.party_current_stats, key)) continue;
                
                var pers = ds_map_find_value(global.party_current_stats, key);
                 if (!is_struct(pers)) { show_debug_message("        -> ERROR: Persistent data for " + key + " is not a struct!"); continue; } 
                 
                show_debug_message("        -> Saving for [" + key + "]: Instance HP=" + string(inst.data.hp) + ", MP=" + string(inst.data.mp));
                // Save final HP/MP state from battle instance back to persistent struct
                // Also ensure level/xp reflect any changes from scr_AddXPToCharacter
                 pers.hp = (variable_struct_exists(inst.data,"maxhp") && inst.data.maxhp > 0) ? max(1, inst.data.hp) : 0; 
                 pers.mp = max(0, inst.data.mp); 
                 pers.level = inst.data.level ?? pers.level; // Update level from instance if needed
                 pers.xp = inst.data.xp ?? pers.xp; // Update xp from instance if needed
                 pers.xp_require = inst.data.xp_require ?? pers.xp_require; // Update xp_require from instance
                 // Overdrive saving might happen here too if desired
                 // pers.overdrive = inst.data.overdrive ?? pers.overdrive;
                
                ds_map_replace(global.party_current_stats, key, pers);
                
                // <<< VERIFY Save to Map Logging >>>
                var _saved_pers = ds_map_find_value(global.party_current_stats, key); 
                if(is_struct(_saved_pers)) {
                     show_debug_message("        -> VERIFY Saved [" + key + "]: HP=" + string(_saved_pers.hp) + ", MP=" + string(_saved_pers.mp) + ", Lvl=" + string(_saved_pers.level ?? "N/A") + ", XP=" + string(_saved_pers.xp ?? "N/A"));
                } else {
                     show_debug_message("        -> ERROR Verifying save for [" + key + "] - Map value invalid after replace!");
                }
                // <<< END LOGGING >>>
            }
        } else { show_debug_message("    -> ERROR: Cannot save stats (missing battle_party list or party_current_stats map)."); }

        // <<< ADDED LOGGING: Show final map state >>>
        if (ds_exists(global.party_current_stats, ds_type_map)) {
            show_debug_message("--- Final global.party_current_stats before leaving battle ---");
            try { show_debug_message(json_encode(global.party_current_stats)); } 
            catch(_err) { show_debug_message("Unable to json_encode global.party_current_stats (may contain instance IDs or other non-JSON types)"); }
            show_debug_message("--------------------------------------------------------------");
        } else { show_debug_message("--- global.party_current_stats MISSING before leaving battle ---"); }
        // <<< END LOGGING >>>

        // --- Destroy battle objects --- 
        show_debug_message("    -> Destroying battle instances...");
        instance_destroy(obj_attack_visual); 
        with (obj_battle_enemy) { if(instance_exists(id)) instance_destroy(); } 
        with (obj_enemy_nut_thief) { if(instance_exists(id)) instance_destroy(); } 
        with (obj_enemy_goblin) { if(instance_exists(id)) instance_destroy(); } 
        with (obj_battle_player) { if(instance_exists(id)) instance_destroy(); } 
        with (obj_battle_menu) { if(instance_exists(id)) instance_destroy(); } 
        with (obj_popup_damage) { if(instance_exists(id)) instance_destroy(); }
        with (obj_dialog) { if(instance_exists(id)) instance_destroy(); } 
        
        // --- Cleanup DS containers ---
        show_debug_message("    -> Cleaning up DS containers...");
        if (ds_exists(combatants_all, ds_type_list)) ds_list_destroy(combatants_all); combatants_all = -1;
        if (ds_exists(global.battle_enemies, ds_type_list)) ds_list_destroy(global.battle_enemies); global.battle_enemies = -1; 
        if (ds_exists(global.battle_party, ds_type_list)) ds_list_destroy(global.battle_party); global.battle_party = -1;
        if (ds_exists(global.battle_status_effects, ds_type_map)) ds_map_destroy(global.battle_status_effects); global.battle_status_effects = -1;
        
        // Reset manager variables
        total_xp_from_battle = 0; currentActor = noone; turnOrderDisplay = [];
        stored_action_data = undefined; selected_target_id = noone;
        current_attack_animation_complete = false;

        // Reset globals used by battle system
        global.battle_state = undefined; global.battle_target = 0;
        global.enemy_turn_index = 0; global.active_party_member_index = 0;

        // --- Finally, jump back to the original room ---
        show_debug_message("    -> Returning to original room...");
        if (variable_global_exists("original_room") && room_exists(global.original_room)) {
            if (instance_exists(obj_player) && variable_global_exists("return_x") && variable_global_exists("return_y")) {
                with (obj_player) { x = global.return_x; y = global.return_y; }
            }
            instance_activate_all(); 
            var _manager_id = id; 
            room_goto(global.original_room); 
            instance_destroy(_manager_id); 
        } else {
            show_debug_message("ERROR: Cannot return to field map! Ending game.");
            instance_destroy(); 
            game_end(); 
        }
    }
    break;

    default:
        show_debug_message("    -> Alarm[0] in unhandled state: " + string(global.battle_state));
        alarm[0] = -1; 
        break;
} // End Switch