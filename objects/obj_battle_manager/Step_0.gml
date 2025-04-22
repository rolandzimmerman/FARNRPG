/// obj_battle_manager :: Step Event
// Manages battle state, actions (incl. critical hits), UI visibility, status effects.
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
            // show_debug_message("Set Layer (ID:" + string(_layer_id) + ") Visible: " + string(_should_be_visible));
        }
    } // else { /* Warning: Layer no longer exists */ }
} // else { /* Warning: Global ID not set */ }
// --- End UI Layer Control ---


// Process current battle state
switch (global.battle_state) {

    case "player_input":
    case "skill_select":
    case "item_select":
        // Manager waits
        break;

    case "TargetSelect": {
        // --- Target Select Logic ---
        var _ec=ds_list_size(global.battle_enemies);if(_ec==0){global.battle_state="check_win_loss";break;}var _u=keyboard_check_pressed(vk_up)||gamepad_button_check_pressed(0,gp_padu);var _d=keyboard_check_pressed(vk_down)||gamepad_button_check_pressed(0,gp_padd);var _c=keyboard_check_pressed(vk_enter)||keyboard_check_pressed(vk_space)||gamepad_button_check_pressed(0,gp_face1);var _x=keyboard_check_pressed(vk_escape)||gamepad_button_check_pressed(0,gp_face2);if(_d)global.battle_target=(_ec>0)?(global.battle_target+1)%_ec:0;if(_u)global.battle_target=(_ec>0)?(global.battle_target-1+_ec)%_ec:0;if(_c){if(global.battle_target>=0&&global.battle_target<_ec){selected_target_id=global.battle_enemies[|global.battle_target];if(instance_exists(selected_target_id)){global.battle_state="ExecutingAction";}else{selected_target_id=noone;global.battle_target=0;}}else{selected_target_id=noone;global.battle_target=0;}break;}if(_x){var _prev="player_input";if(is_struct(stored_action_data)){if(variable_struct_exists(stored_action_data,"usable_in_battle"))_prev="item_select";else if(variable_struct_exists(stored_action_data,"cost"))_prev="skill_select";}global.battle_state=_prev;stored_action_data=undefined;selected_target_id=noone;break;}
    }
    break; // End TargetSelect


     case "ExecutingAction": {
         show_debug_message("--> START ExecutingAction");
         var _action_performed = false;
         var _player_actor = (ds_list_size(global.battle_party) > 0) ? global.battle_party[| 0] : noone;

         if (instance_exists(_player_actor) && variable_instance_exists(_player_actor, "data") && is_struct(_player_actor.data)) {
              var _player_data = _player_actor.data; // Player's battle data

              // --- ACTION LOGIC ---
              if (stored_action_data == "Attack") { // Physical Attack
                   if (selected_target_id != noone && instance_exists(selected_target_id)) {
                       var _t_inst = selected_target_id;
                       if (variable_instance_exists(_t_inst,"data") && is_struct(_t_inst.data)) {
                           var _t_data = _t_inst.data;
                           var player_atk = variable_struct_exists(_player_data, "atk") ? _player_data.atk : 1;
                           var target_def = variable_struct_exists(_t_data, "def") ? _t_data.def : 0;
                           var player_luk = variable_struct_exists(_player_data, "luk") ? _player_data.luk : 0; // Get player luck

                           // --- Critical Hit Check ---
                           var crit_chance = 50; // <<< TEST VALUE: 50% chance
                           // var crit_chance = 5 + floor(player_luk / 4); // Example LUK-based formula (Base 5% + 1% per 4 LUK)
                           var is_crit = (irandom(99) < crit_chance); // Roll 0-99
                           var crit_multiplier = 1.5; // Damage multiplier for crits
                           // --- End Crit Check ---

                           var dmg = max(1, player_atk - target_def); // Base damage

                           if (is_crit) {
                               dmg = floor(dmg * crit_multiplier); // Apply crit multiplier
                               show_debug_message("   CRITICAL HIT!");
                           }

                           if (variable_struct_exists(_t_data, "is_defending") && _t_data.is_defending) { dmg = floor(dmg/2); } // Apply defense

                           _t_data.hp -= dmg; _t_data.hp = max(0, _t_data.hp); // Apply damage

                           // Create Damage Popup - Indicate Crit
                           if (object_exists(obj_popup_damage)) {
                               var pop = instance_create_layer(_t_inst.x, _t_inst.y-64, "Instances", obj_popup_damage);
                               if (pop != noone) {
                                   pop.damage_amount = string(dmg);
                                   if (is_crit) {
                                       pop.damage_amount = "CRIT! " + pop.damage_amount; // Add text
                                       pop.text_color = c_yellow; // Change color
                                       // Optional: Add other effects like bigger size, shake? (Needs code in obj_popup_damage)
                                       // pop.is_critical = true;
                                   }
                               }
                           }
                           _action_performed = true;
                       } else { show_debug_message("   -> Attack Error: Target missing data struct."); }
                   } else { show_debug_message("   -> Attack Error: Target " + string(selected_target_id) + " invalid."); }
              }
              // --- Item Logic ---
              else if (is_struct(stored_action_data) && variable_struct_exists(stored_action_data, "usable_in_battle")) {
                   var _item = stored_action_data; var _target_inst = selected_target_id;
                   switch (_item.effect) {
                       case "heal_hp": if (instance_exists(_target_inst) && variable_instance_exists(_target_inst, "data") && is_struct(_target_inst.data)) { var _td = _target_inst.data; if (variable_struct_exists(_td, "hp") && variable_struct_exists(_td, "maxhp")) { var ohp = _td.hp; _td.hp = min(_td.hp + _item.value, _td.maxhp); var hld = _td.hp - ohp; if (object_exists(obj_popup_damage)) { var pop = instance_create_layer(_target_inst.x, _target_inst.y - 64, "Instances", obj_popup_damage); if (pop != noone) {pop.damage_amount = "+" + string(hld); pop.text_color = c_lime;} } _action_performed = true; } } break;
                       case "damage_enemy": if (instance_exists(_target_inst) && variable_instance_exists(_target_inst, "data") && is_struct(_target_inst.data)) { var _td = _target_inst.data; if (variable_struct_exists(_td, "hp")) { var dmg = _item.value; _td.hp = max(0, _td.hp - dmg); if (object_exists(obj_popup_damage)) { var pop = instance_create_layer(_target_inst.x, _target_inst.y - 64, "Instances", obj_popup_damage); if (pop != noone) pop.damage_amount = string(dmg); } _action_performed = true; } } break;
                       case "cure_status": if (instance_exists(_target_inst) && variable_instance_exists(_target_inst, "data") && is_struct(_target_inst.data)) { var _td = _target_inst.data; var stc = _item.value; if (variable_struct_exists(_td, "status") && _td.status == stc) { _td.status = "none"; if (object_exists(obj_popup_damage)) { var pop = instance_create_layer(_target_inst.x, _target_inst.y - 64, "Instances", obj_popup_damage); if (pop != noone) {pop.damage_amount = "Cured!"; pop.text_color = c_aqua;} } _action_performed = true; } else { _action_performed = true; } } break;
                       default: _action_performed = true; break;
                   }
              }
              // --- Skill Logic ---
              else if (is_struct(stored_action_data)) {
                   _action_performed = scr_CastSkill(_player_actor.id, stored_action_data, selected_target_id);
              }
              // --- Defend Logic ---
               else if (stored_action_data == "Defend") {
                 _player_data.is_defending = true; var pop = instance_create_layer(_player_actor.x, _player_actor.y - 64, "Instances", obj_popup_damage); if (pop != noone) { pop.damage_amount = "DEFEND"; pop.text_color = c_aqua; } _action_performed = true;
              }
         } else { show_debug_message("Execute Error: Player battle instance or its data not found!"); }

         // Cleanup and transition
         stored_action_data = undefined; selected_target_id = noone;
         if (_action_performed) { global.battle_state = "waiting_after_player"; alarm[0] = 30; }
         else { global.battle_state = "player_input"; }
         show_debug_message("<-- END ExecutingAction (State->" + global.battle_state +")");
     }
     break; // End ExecutingAction


     case "waiting_after_player": case "waiting_next_enemy": case "waiting_enemy": break; // Wait states


    case "check_win_loss": {
        // ... (check_win_loss logic with status damage - OK) ...
        show_debug_message("--> START check_win_loss Step");var enemies_remaining=false;var players_remaining=false;var xp_gained=0;if(ds_list_size(global.battle_party)>0){var _pi=global.battle_party[|0];if(instance_exists(_pi)&&variable_instance_exists(_pi,"data")&&is_struct(_pi.data)){var _pd=_pi.data;if(variable_struct_exists(_pd,"status")&&_pd.status=="poison"){var psn_dmg=max(1,floor(_pd.maxhp*0.05));_pd.hp=max(0,_pd.hp-psn_dmg);if(object_exists(obj_popup_damage)){var pop=instance_create_layer(_pi.x,_pi.y-64,"Instances",obj_popup_damage);if(pop!=noone){pop.damage_amount=string(psn_dmg);pop.text_color=c_purple;}}}}}var _esc=ds_list_size(global.battle_enemies);for(var i=0;i<_esc;i++){var _ei=global.battle_enemies[|i];if(instance_exists(_ei)&&variable_instance_exists(_ei,"data")&&is_struct(_ei.data)){var _ed=_ei.data;if(variable_struct_exists(_ed,"status")&&_ed.status=="poison"){var psn_dmg=max(1,floor(_ed.maxhp*0.05));_ed.hp=max(0,_ed.hp-psn_dmg);if(object_exists(obj_popup_damage)){var pop=instance_create_layer(_ei.x,_ei.y-64,"Instances",obj_popup_damage);if(pop!=noone){pop.damage_amount=string(psn_dmg);pop.text_color=c_purple;}}}}}var _ec=ds_list_size(global.battle_enemies);for(var i=_ec-1;i>=0;i--){if(i>=ds_list_size(global.battle_enemies))continue;var e=global.battle_enemies[|i];if(instance_exists(e)&&variable_instance_exists(e,"data")&&is_struct(e.data)&&variable_struct_exists(e.data,"hp")){if(e.data.hp<=0){if(variable_struct_exists(e.data,"xp"))xp_gained+=e.data.xp;instance_destroy(e);ds_list_delete(global.battle_enemies,i);}else{enemies_remaining=true;}}else{ds_list_delete(global.battle_enemies,i);}}if(xp_gained>0)total_xp_from_battle+=xp_gained;if(enemies_remaining){var _ps=ds_list_size(global.battle_party);for(var i=0;i<_ps;i++){var p=global.battle_party[|i];if(instance_exists(p)&&variable_instance_exists(p,"data")&&is_struct(p.data)&&p.data.hp>0){players_remaining=true;break;}}}else{players_remaining=true;} if(!enemies_remaining){global.battle_state="victory";alarm[0]=30;}else if(!players_remaining){global.battle_state="defeat";alarm[0]=30;}else{if(global.enemy_turn_index>=ds_list_size(global.battle_enemies)){global.battle_state="player_input";var _nes=ds_list_size(global.battle_enemies);if(_nes>0)global.battle_target=clamp(global.battle_target,0,_nes-1);else global.battle_target=0;global.enemy_turn_index=0;}else{global.battle_state="waiting_enemy";global.enemy_turn_index=0;alarm[0]=30;}}show_debug_message("<-- END check_win_loss (New State Set: "+string(global.battle_state)+")");
    }
    break; // End check_win_loss


    case "enemy_turn": {
        // ... (enemy_turn logic - OK, includes poison chance) ...
         var _ci=global.enemy_turn_index;var _es=ds_list_size(global.battle_enemies); if(_ci<_es){var enemy_inst=global.battle_enemies[|_ci];if(instance_exists(enemy_inst)&&variable_instance_exists(enemy_inst,"data")&&is_struct(enemy_inst.data)&&enemy_inst.data.hp>0){var enemy_data=enemy_inst.data;if(ds_list_size(global.battle_party)>0){var target_player=global.battle_party[|0];if(instance_exists(target_player)&&variable_instance_exists(target_player,"data")&&is_struct(target_player.data)){var target_data=target_player.data;var enemy_atk=variable_struct_exists(enemy_data,"atk")?enemy_data.atk:1;var player_def=variable_struct_exists(target_data,"def")?target_data.def:0;var dmg=max(1,enemy_atk-player_def);if(variable_struct_exists(target_data,"is_defending")&&target_data.is_defending){dmg=floor(dmg/2);}target_data.hp-=dmg;target_data.hp=max(0,target_data.hp);var pop=instance_create_layer(target_player.x,target_player.y-64,"Instances",obj_popup_damage);if(pop!=noone)pop.damage_amount=string(dmg);target_data.is_defending=false;if(irandom(99)<25){if(variable_struct_exists(target_data,"status")&&target_data.status=="none"){target_data.status="poison";if(object_exists(obj_popup_damage)){var pop_p=instance_create_layer(target_player.x,target_player.y-96,"Instances",obj_popup_damage);if(pop_p!=noone){pop_p.damage_amount="Poison!";pop_p.text_color=c_purple;}}}}if(target_data.hp<=0){global.battle_state="check_win_loss";alarm[0]=5;break;}}}}global.enemy_turn_index+=1;global.battle_state="waiting_next_enemy";alarm[0]=30;}else{global.battle_state="check_win_loss";}
    }
    break; // End enemy_turn


    default: break;
} // End Switch