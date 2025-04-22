/// obj_battle_manager :: Step Event
// Manages battle state flow. UI Layer visibility handled by obj_battle_menu Draw GUI event.
// NO STATIC VARIABLES USED.

// Log state every step (Optional)
// show_debug_message("--- Manager Step Start --- State: " + string(global.battle_state));

// --- UI Layer Visibility Control REMOVED ---


// Process current battle state
switch (global.battle_state) {

    case "player_input":
    case "skill_select":
        // Manager waits
        break;

    case "TargetSelect": {
        // ... (Target select logic) ...
        var _ec=ds_list_size(global.battle_enemies);if(_ec==0){global.battle_state="check_win_loss";break;}var _u=keyboard_check_pressed(vk_up)||gamepad_button_check_pressed(0,gp_padu);var _d=keyboard_check_pressed(vk_down)||gamepad_button_check_pressed(0,gp_padd);var _c=keyboard_check_pressed(vk_enter)||keyboard_check_pressed(vk_space)||gamepad_button_check_pressed(0,gp_face1);var _x=keyboard_check_pressed(vk_escape)||gamepad_button_check_pressed(0,gp_face2);if(_d)global.battle_target=(_ec>0)?(global.battle_target+1)%_ec:0;if(_u)global.battle_target=(_ec>0)?(global.battle_target-1+_ec)%_ec:0;if(_c){if(global.battle_target>=0&&global.battle_target<_ec){selected_target_id=global.battle_enemies[|global.battle_target];if(instance_exists(selected_target_id)){global.battle_state="ExecutingAction";}else{selected_target_id=noone;global.battle_target=0;}}else{selected_target_id=noone;global.battle_target=0;}break;}if(_x){global.battle_state="player_input";stored_action_data=undefined;selected_target_id=noone;}
    }
    break;


     case "ExecutingAction": {
        // ... (ExecutingAction logic) ...
         var _a=false;var _pa=(ds_list_size(global.battle_party)>0)?global.battle_party[|0]:noone;if(instance_exists(_pa)&&variable_instance_exists(_pa,"data")&&is_struct(_pa.data)){var _pd=_pa.data;if(stored_action_data=="Attack"){if(selected_target_id!=noone && instance_exists(selected_target_id)){var _t=selected_target_id;if(variable_instance_exists(_t,"data")&&is_struct(_t.data)){var dmg=max(1,_pd.atk-_t.data.def);if(variable_struct_exists(_t.data,"is_defending")&&_t.data.is_defending)dmg=floor(dmg/2);_t.data.hp-=dmg;_t.data.hp=max(0,_t.data.hp);var pop=instance_create_layer(_t.x,_t.y-64,"Instances",obj_popup_damage);if(pop!=noone)pop.damage_amount=string(dmg);_a=true;}}}else if(is_struct(stored_action_data)){_a=scr_CastSkill(_pa.id,stored_action_data,selected_target_id);}else if(stored_action_data=="Defend"){_pd.is_defending=true;var pop=instance_create_layer(_pa.x,_pa.y-64,"Instances",obj_popup_damage);if(pop!=noone){pop.damage_amount="DEFEND";pop.text_color=c_aqua;}_a=true;}}stored_action_data=undefined;selected_target_id=noone;if(_a){global.battle_state="waiting_after_player";alarm[0]=30;}else{global.battle_state="player_input";}
     }
     break;


     case "waiting_after_player": case "waiting_next_enemy": case "waiting_enemy": break;


    case "check_win_loss": {
        // ... (check_win_loss logic) ...
        var enemies_remaining=false;var players_remaining=false;var xp_gained=0;var _ec=ds_list_size(global.battle_enemies);for(var i=_ec-1;i>=0;i--){if(i>=ds_list_size(global.battle_enemies))continue;var e=global.battle_enemies[|i];if(instance_exists(e)&&variable_instance_exists(e,"data")&&is_struct(e.data)&&variable_struct_exists(e.data,"hp")){if(e.data.hp<=0){if(variable_struct_exists(e.data,"xp"))xp_gained+=e.data.xp;instance_destroy(e);ds_list_delete(global.battle_enemies,i);}else{enemies_remaining=true;}}else{ds_list_delete(global.battle_enemies,i);}}if(xp_gained>0)total_xp_from_battle+=xp_gained;if(enemies_remaining){var _ps=ds_list_size(global.battle_party);for(var i=0;i<_ps;i++){var p=global.battle_party[|i];if(instance_exists(p)&&variable_instance_exists(p,"data")&&is_struct(p.data)&&p.data.hp>0){players_remaining=true;break;}}}else{players_remaining=true;} if(!enemies_remaining){global.battle_state="victory";alarm[0]=30;}else if(!players_remaining){global.battle_state="defeat";alarm[0]=30;}else{if(global.enemy_turn_index>=ds_list_size(global.battle_enemies)){global.battle_state="player_input";var _nes=ds_list_size(global.battle_enemies);if(_nes>0)global.battle_target=clamp(global.battle_target,0,_nes-1);else global.battle_target=0;global.enemy_turn_index=0;}else{global.battle_state="waiting_enemy";global.enemy_turn_index=0;alarm[0]=30;}}
    }
    break;


    case "enemy_turn": {
        // ... (enemy_turn logic) ...
         var _ci=global.enemy_turn_index;var _es=ds_list_size(global.battle_enemies); if(_ci<_es){var enemy=global.battle_enemies[|_ci];if(instance_exists(enemy)&&variable_instance_exists(enemy,"data")&&is_struct(enemy.data)&&enemy.data.hp>0){if(ds_list_size(global.battle_party)>0){var target=global.battle_party[|0];if(instance_exists(target)&&variable_instance_exists(target,"data")&&is_struct(target.data)){var td=target.data;var dmg=max(1,enemy.data.atk-td.def);if(variable_struct_exists(td,"is_defending")&&td.is_defending)dmg=floor(dmg/2);td.hp-=dmg;td.hp=max(0,td.hp);var pop=instance_create_layer(target.x,target.y-64,"Instances",obj_popup_damage);if(pop!=noone)pop.damage_amount=string(dmg);td.is_defending=false;if(td.hp<=0){global.battle_state="check_win_loss";alarm[0]=5;break;}}}} global.enemy_turn_index+=1;global.battle_state="waiting_next_enemy";alarm[0]=30;}else{global.battle_state="check_win_loss";}
    }
    break;


    default: break;
} // End Switch
