/// obj_battle_manager :: Step Event
// Manages battle state, actions, UI visibility, including Target Selection input.
// NO STATIC VARIABLES USED.

// Log state every step (Optional)
// show_debug_message("--- Manager Step Start --- State: " + string(global.battle_state));


// --- Control UI Layer Visibility Based on State (Using Global ID) ---
if (variable_global_exists("layer_id_radial_menu") && global.layer_id_radial_menu != -1) {
    var _layer_id = global.layer_id_radial_menu;
    if (layer_exists(_layer_id)) {
        var _should_be_visible = (global.battle_state == "player_input");
        if (layer_get_visible(_layer_id) != _should_be_visible) {
            layer_set_visible(_layer_id, _should_be_visible);
            // show_debug_message("Set Layer (ID:" + string(_layer_id) + ") Visible: " + string(_should_be_visible)); // Optional Log
        }
    } // else { show_debug_message("WARNING (Manager Step): Layer with stored ID " + string(_layer_id) + " no longer exists!"); }
} // else { show_debug_message("WARNING (Manager Step): global.layer_id_radial_menu not set or invalid!"); }
// --- End UI Layer Control ---


// Process current battle state
switch (global.battle_state) {

    case "player_input":
    case "skill_select":
    case "item_select":
        // Manager waits - Input handled elsewhere (obj_battle_player)
        break;

    case "TargetSelect": {
        show_debug_message(" > In TargetSelect State"); // DEBUG: Confirm state entry
        // Manager handles target selection input
        var _enemy_count = ds_list_size(global.battle_enemies);
        if (_enemy_count <= 0) { // If no enemies left somehow
            show_debug_message("   TargetSelect: No enemies left, checking win/loss.");
            global.battle_state = "check_win_loss";
            break; // Exit switch for this step
        }

        // --- Read Input ---
        // Ensure consistent input reading (same as obj_battle_player)
        var P = 0; // Gamepad index
        var _up_pressed = keyboard_check_pressed(vk_up) || gamepad_button_check_pressed(P, gp_padu);
        var _down_pressed = keyboard_check_pressed(vk_down) || gamepad_button_check_pressed(P, gp_padd);
        var _confirm_pressed = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(P, gp_face1); // A button equivalent
        var _cancel_pressed = keyboard_check_pressed(vk_escape) || gamepad_button_check_pressed(P, gp_face2); // B button equivalent

        // --- Handle Input ---
        if (_down_pressed) {
            global.battle_target = (global.battle_target + 1) % _enemy_count;
            show_debug_message("   TargetSelect: Down pressed. New target index: " + string(global.battle_target)); // DEBUG
        }
        if (_up_pressed) {
            // Modulo needs careful handling for negative numbers in some languages, GML is usually okay
            global.battle_target = (global.battle_target - 1 + _enemy_count) % _enemy_count;
            show_debug_message("   TargetSelect: Up pressed. New target index: " + string(global.battle_target)); // DEBUG
        }
        if (_confirm_pressed) {
            show_debug_message("   TargetSelect: Confirm pressed."); // DEBUG
            // Check if the current target index is valid before proceeding
            if (global.battle_target >= 0 && global.battle_target < ds_list_size(global.battle_enemies)) { // Re-check size in case it changed
                 selected_target_id = global.battle_enemies[| global.battle_target]; // Get the instance ID
                 if (instance_exists(selected_target_id)) {
                     show_debug_message("   TargetSelect: Target confirmed (ID: " + string(selected_target_id) + "). Proceeding to Execute.");
                     global.battle_state = "ExecutingAction"; // Go execute the stored action
                 } else {
                     show_debug_message("   TargetSelect: Target instance (ID: " + string(selected_target_id) + ") no longer exists! Resetting target.");
                     selected_target_id = noone;
                     global.battle_target = 0; // Reset target index
                     // Stay in TargetSelect or go back? Maybe back to input?
                     // global.battle_state = "player_input"; // Option: Go back if target invalid
                 }
            } else {
                 show_debug_message("   TargetSelect: Invalid target index (" + string(global.battle_target) + ") on confirm. Resetting.");
                 selected_target_id = noone;
                 global.battle_target = 0;
            }
            break; // Exit switch this step after processing confirm
        }
        if (_cancel_pressed) {
            show_debug_message("   TargetSelect: Cancel pressed."); // DEBUG
            // Determine where to cancel back to (Item menu or main menu)
            if (is_struct(stored_action_data) && variable_struct_exists(stored_action_data, "usable_in_battle")) {
                 show_debug_message("   TargetSelect: Cancelling back to Item Select.");
                 global.battle_state = "item_select"; // Go back to item menu
            } else if (is_struct(stored_action_data) && variable_struct_exists(stored_action_data, "cost")) {
                 show_debug_message("   TargetSelect: Cancelling back to Skill Select.");
                 global.battle_state = "skill_select"; // Go back to skill menu
            } else {
                 show_debug_message("   TargetSelect: Cancelling back to Player Input.");
                 global.battle_state = "player_input"; // Default: Go back to main command menu
            }
            stored_action_data = undefined; // Clear the action that required targeting
            selected_target_id = noone;
            break; // Exit switch this step after processing cancel
        }
    }
    break; // End case "TargetSelect"


     case "ExecutingAction": {
        // ... (ExecutingAction logic - OK) ...
        show_debug_message("--> START ExecutingAction");var _a=false;var _pa=(ds_list_size(global.battle_party)>0)?global.battle_party[|0]:noone;if(instance_exists(_pa)&&variable_instance_exists(_pa,"data")&&is_struct(_pa.data)){var _pd=_pa.data;if(stored_action_data=="Attack"){if(selected_target_id!=noone && instance_exists(selected_target_id)){var _t=selected_target_id;if(variable_instance_exists(_t,"data")&&is_struct(_t.data)){var dmg=max(1,_pd.atk-_t.data.def);if(variable_struct_exists(_t.data,"is_defending")&&_t.data.is_defending)dmg=floor(dmg/2);_t.data.hp-=dmg;_t.data.hp=max(0,_t.data.hp);var pop=instance_create_layer(_t.x,_t.y-64,"Instances",obj_popup_damage);if(pop!=noone)pop.damage_amount=string(dmg);_a=true;}}}else if(is_struct(stored_action_data)&&variable_struct_exists(stored_action_data,"usable_in_battle")){var _item=stored_action_data;var _target_inst=selected_target_id;switch(_item.effect){case "heal_hp": if(instance_exists(_target_inst)&&variable_instance_exists(_target_inst,"data")&&is_struct(_target_inst.data)){var _td=_target_inst.data;if(variable_struct_exists(_td,"hp")&&variable_struct_exists(_td,"maxhp")){var ohp=_td.hp;_td.hp=min(_td.hp+_item.value,_td.maxhp);var hld=_td.hp-ohp;if(object_exists(obj_popup_damage)){var pop=instance_create_layer(_target_inst.x,_target_inst.y-64,"Instances",obj_popup_damage);if(pop!=noone){pop.damage_amount="+"+string(hld);pop.text_color=c_lime;}}_a=true;}}break;case "damage_enemy": if(instance_exists(_target_inst)&&variable_instance_exists(_target_inst,"data")&&is_struct(_target_inst.data)){var _td=_target_inst.data;if(variable_struct_exists(_td,"hp")){var dmg=_item.value;_td.hp=max(0,_td.hp-dmg);if(object_exists(obj_popup_damage)){var pop=instance_create_layer(_target_inst.x,_target_inst.y-64,"Instances",obj_popup_damage);if(pop!=noone)pop.damage_amount=string(dmg);}_a=true;}}break;case "cure_status": if(instance_exists(_target_inst)&&variable_instance_exists(_target_inst,"data")&&is_struct(_target_inst.data)){var _td=_target_inst.data;var stc=_item.value;if(variable_struct_exists(_td,"status")&&_td.status==stc){_td.status="none";if(object_exists(obj_popup_damage)){var pop=instance_create_layer(_target_inst.x,_target_inst.y-64,"Instances",obj_popup_damage);if(pop!=noone){pop.damage_amount="Cured!";pop.text_color=c_aqua;}}_a=true;}else{_a=true;}}break;default:_a=true;break;}}else if(is_struct(stored_action_data)){_a=scr_CastSkill(_pa.id,stored_action_data,selected_target_id);}else if(stored_action_data=="Defend"){_pd.is_defending=true;var pop=instance_create_layer(_pa.x,_pa.y-64,"Instances",obj_popup_damage);if(pop!=noone){pop.damage_amount="DEFEND";pop.text_color=c_aqua;}_a=true;}}stored_action_data=undefined;selected_target_id=noone;if(_a){global.battle_state="waiting_after_player";alarm[0]=30;}else{global.battle_state="player_input";}show_debug_message("<-- END ExecutingAction (State->"+global.battle_state+")");
     }
     break; // End ExecutingAction


     case "waiting_after_player": case "waiting_next_enemy": case "waiting_enemy": break; // Wait states


    case "check_win_loss": {
        // ... (check_win_loss logic - OK) ...
        show_debug_message("--> START check_win_loss Step");var enemies_remaining=false;var players_remaining=false;var xp_gained=0;if(ds_list_size(global.battle_party)>0){var _pi=global.battle_party[|0];if(instance_exists(_pi)&&variable_instance_exists(_pi,"data")&&is_struct(_pi.data)){var _pd=_pi.data;if(variable_struct_exists(_pd,"status")&&_pd.status=="poison"){var psn_dmg=max(1,floor(_pd.maxhp*0.05));_pd.hp=max(0,_pd.hp-psn_dmg);if(object_exists(obj_popup_damage)){var pop=instance_create_layer(_pi.x,_pi.y-64,"Instances",obj_popup_damage);if(pop!=noone){pop.damage_amount=string(psn_dmg);pop.text_color=c_purple;}}show_debug_message("    Player takes "+string(psn_dmg)+" poison damage.");}}}var _esc=ds_list_size(global.battle_enemies);for(var i=0;i<_esc;i++){var _ei=global.battle_enemies[|i];if(instance_exists(_ei)&&variable_instance_exists(_ei,"data")&&is_struct(_ei.data)){var _ed=_ei.data;if(variable_struct_exists(_ed,"status")&&_ed.status=="poison"){var psn_dmg=max(1,floor(_ed.maxhp*0.05));_ed.hp=max(0,_ed.hp-psn_dmg);if(object_exists(obj_popup_damage)){var pop=instance_create_layer(_ei.x,_ei.y-64,"Instances",obj_popup_damage);if(pop!=noone){pop.damage_amount=string(psn_dmg);pop.text_color=c_purple;}}show_debug_message("    Enemy "+string(_ei)+" takes "+string(psn_dmg)+" poison damage.");}}}var _ec=ds_list_size(global.battle_enemies);for(var i=_ec-1;i>=0;i--){if(i>=ds_list_size(global.battle_enemies))continue;var e=global.battle_enemies[|i];if(instance_exists(e)&&variable_instance_exists(e,"data")&&is_struct(e.data)&&variable_struct_exists(e.data,"hp")){if(e.data.hp<=0){if(variable_struct_exists(e.data,"xp"))xp_gained+=e.data.xp;instance_destroy(e);ds_list_delete(global.battle_enemies,i);}else{enemies_remaining=true;}}else{ds_list_delete(global.battle_enemies,i);}}if(xp_gained>0)total_xp_from_battle+=xp_gained;if(enemies_remaining){var _ps=ds_list_size(global.battle_party);for(var i=0;i<_ps;i++){var p=global.battle_party[|i];if(instance_exists(p)&&variable_instance_exists(p,"data")&&is_struct(p.data)&&p.data.hp>0){players_remaining=true;break;}}}else{players_remaining=true;} show_debug_message("    Check Results: Enemies="+string(enemies_remaining)+", Players="+string(players_remaining));if(!enemies_remaining){global.battle_state="victory";alarm[0]=30;}else if(!players_remaining){global.battle_state="defeat";alarm[0]=30;}else{if(global.enemy_turn_index>=ds_list_size(global.battle_enemies)){global.battle_state="player_input";var _nes=ds_list_size(global.battle_enemies);if(_nes>0)global.battle_target=clamp(global.battle_target,0,_nes-1);else global.battle_target=0;global.enemy_turn_index=0;}else{global.battle_state="waiting_enemy";global.enemy_turn_index=0;alarm[0]=30;}}show_debug_message("<-- END check_win_loss (New State Set: "+string(global.battle_state)+")");
    }
    break; // End check_win_loss


    case "enemy_turn": {
        // ... (enemy_turn logic - OK) ...
         var _ci=global.enemy_turn_index;var _es=ds_list_size(global.battle_enemies); if(_ci<_es){var enemy_inst=global.battle_enemies[|_ci];if(instance_exists(enemy_inst)&&variable_instance_exists(enemy_inst,"data")&&is_struct(enemy_inst.data)&&enemy_inst.data.hp>0){var enemy_data=enemy_inst.data;if(ds_list_size(global.battle_party)>0){var target_player=global.battle_party[|0];if(instance_exists(target_player)&&variable_instance_exists(target_player,"data")&&is_struct(target_player.data)){var target_data=target_player.data;var enemy_atk=variable_struct_exists(enemy_data,"atk")?enemy_data.atk:1;var player_def=variable_struct_exists(target_data,"def")?target_data.def:0;var dmg=max(1,enemy_atk-player_def);if(variable_struct_exists(target_data,"is_defending")&&target_data.is_defending){dmg=floor(dmg/2);}target_data.hp-=dmg;target_data.hp=max(0,target_data.hp);var pop=instance_create_layer(target_player.x,target_player.y-64,"Instances",obj_popup_damage);if(pop!=noone)pop.damage_amount=string(dmg);target_data.is_defending=false;if(irandom(99)<25){if(variable_struct_exists(target_data,"status")&&target_data.status=="none"){target_data.status="poison";if(object_exists(obj_popup_damage)){var pop_p=instance_create_layer(target_player.x,target_player.y-96,"Instances",obj_popup_damage);if(pop_p!=noone){pop_p.damage_amount="Poison!";pop_p.text_color=c_purple;}}}}if(target_data.hp<=0){global.battle_state="check_win_loss";alarm[0]=5;break;}}}}global.enemy_turn_index+=1;global.battle_state="waiting_next_enemy";alarm[0]=30;}else{global.battle_state="check_win_loss";}
    }
    break; // End enemy_turn


    default: break;
} // End Switch
