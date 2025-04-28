/// obj_battle_manager :: Alarm[0]
/// Handles timed transitions for Victory/Defeat processing, saving persistent stats, and cleaning up.

show_debug_message("⏰ BattleManager Alarm[0] Triggered — Current State: " + string(global.battle_state) + " !!!");

switch (global.battle_state) {

    case "victory": // <<< Use original string state
    {
        show_debug_message("🏆 Alarm 0: Processing Victory. Total XP Accumulated: " + string(total_xp_from_battle));
        var leveled_up_characters = [];

        // 1) Award XP (Your existing logic here is fine)
        if (ds_exists(global.battle_party, ds_type_list) && script_exists(scr_AddXPToCharacter)) {
            var partyCount = ds_list_size(global.battle_party);
            for (var i = 0; i < partyCount; i++) {
                var inst = global.battle_party[| i];
                if (!instance_exists(inst) || !variable_instance_exists(inst, "data") || !is_struct(inst.data) || inst.data.hp <= 0) continue; 
                var key = inst.character_key; 
                var didLevel = scr_AddXPToCharacter(key, total_xp_from_battle);
                if (didLevel && variable_struct_exists(inst.data, "name")) array_push(leveled_up_characters, inst.data.name);
                 var pers = ds_map_find_value(global.party_current_stats, key);
                 if (is_struct(pers) && instance_exists(inst)) { 
                    inst.data.level      = pers.level;
                    inst.data.xp         = pers.xp;
                    inst.data.xp_require = pers.xp_require;
                 }
            }
        }

        // 2) Build & show dialogue (Your existing logic here is fine)
        var messages = [];
        array_push(messages, { name:"Victory!", msg:"Gained " + string(total_xp_from_battle) + " XP!" });
        if (array_length(leveled_up_characters) > 0) {
            var upMsg = "";
             if (array_length(leveled_up_characters) == 1) { upMsg = leveled_up_characters[0] + " leveled up!"; } else { for (var j = 0; j < array_length(leveled_up_characters); j++) { upMsg += leveled_up_characters[j]; if (j < array_length(leveled_up_characters) - 2) upMsg += ", "; else if (j == array_length(leveled_up_characters) - 2) upMsg += " and "; } upMsg += " leveled up!"; }
            array_push(messages, { name:"System", msg:upMsg });
        }
        // Use create_dialog if it exists, otherwise skip dialogue
        if (script_exists(create_dialog)) { 
            var dlgLayer = layer_exists("Instances_GUI") ? "Instances_GUI" : "Instances";
            var dlg      = instance_create_layer(0, 0, dlgLayer, obj_dialog); 
            if (instance_exists(dlg)) { 
                 dlg.messages = messages;
            }
        } else if (instance_exists(obj_dialog)) { // Fallback? obj_dialog might need specific setup
             obj_dialog.messages = messages; // Less safe, assumes single dialog obj
        }


        // 3) Queue return
        global.battle_state = "return_to_field"; // <<< Use string state
        alarm[0]     = 120; // Delay before actually returning
    }
    break;


    case "defeat": // <<< Use original string state
    {
        show_debug_message("😭 Alarm 0: Processing Defeat.");
        // Show defeat message
        if (script_exists(create_dialog)) {
            var dLayer    = layer_exists("Instances_GUI") ? "Instances_GUI" : "Instances";
            var defeatDlg = instance_create_layer(0, 0, dLayer, obj_dialog);
            if (instance_exists(defeatDlg)) {
                defeatDlg.messages = [{ name:"Defeat", msg:"You have been defeated..." }];
            }
         } else if (instance_exists(obj_dialog)) {
             obj_dialog.messages = [{ name:"Defeat", msg:"You have been defeated..." }];
         }
        // Queue return
        global.battle_state = "return_to_field"; // <<< Use string state
        alarm[0]     = 120; // Delay before returning
    }
    break;


    case "return_to_field": // <<< Use string state (assuming you had this)
    {
        show_debug_message("    Alarm 0: Returning to field map.");
        show_debug_message("    Saving persistent party stats (HP, MP)...");

        // --- Save Persistent Stats --- (Your existing logic here is fine)
        if (ds_exists(global.battle_party, ds_type_list) && ds_exists(global.party_current_stats, ds_type_map)) {
            var count = ds_list_size(global.battle_party);
            for (var i = 0; i < count; i++) {
                var inst = global.battle_party[| i];
                if (!instance_exists(inst) || !variable_instance_exists(inst, "data") || !is_struct(inst.data)) continue;
                var key = inst.character_key; // Use stored key
                if (!is_string(key) || !ds_map_exists(global.party_current_stats, key)) continue;
                var pers = ds_map_find_value(global.party_current_stats, key);
                 if (!is_struct(pers)) continue; 
                 
                show_debug_message("        -> Before Save [" + key + "]: HP=" + string(pers.hp) + ", MP=" + string(pers.mp));
                pers.hp = max(1, inst.data.hp); // Return with at least 1 HP
                pers.mp = inst.data.mp;
                // pers.overdrive = inst.data.overdrive; // Optional: Save overdrive
                 
                ds_map_replace(global.party_current_stats, key, pers);
                show_debug_message("        -> After Save  [" + key + "]: HP=" + string(pers.hp) + ", MP=" + string(pers.mp));
            }
        } else {
            show_debug_message("    -> ERROR: Cannot save stats (missing DS structures).");
        }

        // --- Destroy battle objects ---
        // Use specific object names or a parent if applicable
        with(obj_battle_enemy) { if(instance_exists(id)) instance_destroy(); } // Assuming common parent
         // Add lines for specific enemy types if no common parent:
         with(obj_enemy_nut_thief) { if(instance_exists(id)) instance_destroy(); }
         with(obj_enemy_goblin) { if(instance_exists(id)) instance_destroy(); }
         // ... etc ...
        
        with(obj_battle_player) { if(instance_exists(id)) instance_destroy(); }
        with(obj_battle_menu) { if(instance_exists(id)) instance_destroy(); }
        with(obj_popup_damage) { if(instance_exists(id)) instance_destroy(); }
        with(obj_dialog) { if(instance_exists(id)) instance_destroy(); } // Destroy any active dialogs


        // --- Cleanup DS containers ---
        if (ds_exists(combatants_all, ds_type_list)) ds_list_destroy(combatants_all);
        if (ds_exists(global.battle_enemies, ds_type_list)) ds_list_destroy(global.battle_enemies);
        if (ds_exists(global.battle_party, ds_type_list)) ds_list_destroy(global.battle_party);
        if (ds_exists(global.battle_status_effects, ds_type_map)) ds_map_destroy(global.battle_status_effects);

        global.battle_enemies        = -1; // Mark as destroyed
        global.battle_party          = -1;
        global.battle_status_effects = -1;
        
        // Reset manager variables
        total_xp_from_battle       = 0;
        currentActor               = noone;
        turnOrderDisplay           = [];
        stored_action_data         = undefined;
        selected_target_id         = noone;

        // Reset globals used by battle system
        global.battle_state          = undefined; // Clear global state
        global.battle_target         = 0;
        global.enemy_turn_index      = 0; // Reset just in case
        global.active_party_member_index = 0; // Reset just in case

        // --- Finally, jump back to the original room ---
        if (variable_global_exists("original_room") && room_exists(global.original_room)) {
            if (instance_exists(obj_player) && variable_global_exists("return_x") && variable_global_exists("return_y")) {
                with (obj_player) { x = global.return_x; y = global.return_y; }
            }
            instance_activate_all(); 
            
            // Destroy the manager itself just before room change
            var _manager_id = id; // Store id in local var
            room_goto(global.original_room); 
            instance_destroy(_manager_id); // Destroy using stored id after initiating room change

        } else {
            show_debug_message("ERROR: Cannot return to field map!");
            instance_destroy(); // Destroy manager even on error
            game_end(); // Or go to a title screen/error room
        }
    }
    break;


    default:
        show_debug_message("    -> Alarm[0] in unhandled state: " + string(global.battle_state));
        alarm[0] = -1; // Stop alarm if state is unexpected
        break;
} // End Switch