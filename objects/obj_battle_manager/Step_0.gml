/// @description obj_battle_manager Step Event
// Manages battle state, actions, UI visibility, status effects, party turn order, and target selection.

// --- Control UI Layer Visibility ---
if (variable_global_exists("layer_id_radial_menu") && global.layer_id_radial_menu != -1) { var _lid = global.layer_id_radial_menu; if (layer_exists(_lid)) { var _sv = (global.battle_state == "player_input"); if (layer_get_visible(_lid) != _sv) { layer_set_visible(_lid, _sv); } } }

// Process current battle state
switch (global.battle_state) {

    case "player_input":
    case "skill_select":
    case "item_select":
    break; // Break for these waiting states

    case "TargetSelect":
    { // Start TargetSelect case block
        var _enemy_count = ds_list_size(global.battle_enemies);
        if (_enemy_count <= 0) {
            global.battle_state = "check_win_loss";
        } else {
            var P = 0;
            var _up_pressed = keyboard_check_pressed(vk_up) || gamepad_button_check_pressed(P, gp_padu);
            var _down_pressed = keyboard_check_pressed(vk_down) || gamepad_button_check_pressed(P, gp_padd);
            var _confirm_pressed = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(P, gp_face1);
            var _cancel_pressed = keyboard_check_pressed(vk_escape) || gamepad_button_check_pressed(P, gp_face2);

            if (_down_pressed) { global.battle_target = (global.battle_target + 1) % _enemy_count; }
            else if (_up_pressed) { global.battle_target = (global.battle_target - 1 + _enemy_count) % _enemy_count; }
            else if (_confirm_pressed) {
                if (global.battle_target >= 0 && global.battle_target < _enemy_count) {
                     selected_target_id = global.battle_enemies[| global.battle_target];
                     if (instance_exists(selected_target_id)) { global.battle_state = "ExecutingAction"; break; } // Break after state change
                     else { selected_target_id = noone; global.battle_target = 0; }
                } else { selected_target_id = noone; global.battle_target = 0; }
            }
            else if (_cancel_pressed) {
                var _prev = "player_input"; if (is_struct(stored_action_data)) { if (variable_struct_exists(stored_action_data,"usable_in_battle")) _prev="item_select"; else if (variable_struct_exists(stored_action_data,"cost")) _prev="skill_select"; }
                global.battle_state = _prev; stored_action_data = undefined; selected_target_id = noone;
                break; // Break after state change
            }
        }
    } // End of TargetSelect case logic block
    break; // Break for TargetSelect case


     case "ExecutingAction":
     { // Start ExecutingAction case block
         var _action_performed = false;
         var _player_actor = noone; if (ds_list_size(global.battle_party) > global.active_party_member_index) { _player_actor = global.battle_party[| global.active_party_member_index]; }

         if (instance_exists(_player_actor) && variable_instance_exists(_player_actor, "data") && is_struct(_player_actor.data)) {
              var _player_data = _player_actor.data;
              if (stored_action_data == "Attack") { if (selected_target_id != noone && instance_exists(selected_target_id)) { var _ti=selected_target_id; if (variable_instance_exists(_ti,"data") && is_struct(_ti.data)) { var _td=_ti.data; var pa=_player_data.atk; var td=_td.def; var pl=_player_data.luk; var cc=5+floor(pl/4); var ic=(irandom(99)<cc); var cm=1.5; var dmg=max(1,pa-td); if(ic)dmg=floor(dmg*cm); if(variable_struct_exists(_td,"is_defending")&&_td.is_defending)dmg=floor(dmg/2); _td.hp-=dmg; _td.hp=max(0,_td.hp); if(object_exists(obj_popup_damage)){var pop=instance_create_layer(_ti.x,_ti.y-64,"Instances",obj_popup_damage); if(pop!=noone){pop.damage_amount=string(dmg);if(ic){pop.damage_amount="CRIT! "+pop.damage_amount;pop.text_color=c_yellow;}}} _action_performed=true; } else {_action_performed=false;} } else {_action_performed=false;} }
              else if (is_struct(stored_action_data) && variable_struct_exists(stored_action_data, "usable_in_battle")) { /* Item Logic */ var _item=stored_action_data;var _target_inst=selected_target_id;var _ie=false;switch(_item.effect){case "heal_hp":if(instance_exists(_target_inst)&&variable_instance_exists(_target_inst,"data")&&is_struct(_target_inst.data)){var _td=_target_inst.data;if(variable_struct_exists(_td,"hp")&&variable_struct_exists(_td,"maxhp")){var ohp=_td.hp;_td.hp=min(_td.hp+_item.value,_td.maxhp);var hld=_td.hp-ohp;if(hld>0){if(object_exists(obj_popup_damage)){var pop=instance_create_layer(_target_inst.x,_target_inst.y-64,"Instances",obj_popup_damage);if(pop!=noone){pop.damage_amount="+"+string(hld);pop.text_color=c_lime;}}_ie=true;}}}break;case "damage_enemy":if(instance_exists(_target_inst)&&variable_instance_exists(_target_inst,"data")&&is_struct(_target_inst.data)){var _td=_target_inst.data;if(variable_struct_exists(_td,"hp")){var dmg=_item.value;_td.hp=max(0,_td.hp-dmg);if(object_exists(obj_popup_damage)){var pop=instance_create_layer(_target_inst.x,_target_inst.y-64,"Instances",obj_popup_damage);if(pop!=noone)pop.damage_amount=string(dmg);}_ie=true;}}break;case "cure_status":if(instance_exists(_target_inst)&&variable_instance_exists(_target_inst,"data")&&is_struct(_target_inst.data)){var _td=_target_inst.data;var stc=_item.value;if(variable_struct_exists(_td,"status")&&_td.status==stc){_td.status="none";if(object_exists(obj_popup_damage)){var pop=instance_create_layer(_target_inst.x,_target_inst.y-64,"Instances",obj_popup_damage);if(pop!=noone){pop.damage_amount="Cured!";pop.text_color=c_aqua;}}_ie=true;}else{_ie=true;}}break;default:_ie=true;break;}_action_performed=_ie; }
              else if (is_struct(stored_action_data)) { _action_performed = scr_CastSkill(_player_actor.id, stored_action_data, selected_target_id); }
              else if (stored_action_data == "Defend") { _player_data.is_defending = true; var pop = instance_create_layer(_player_actor.x, _player_actor.y - 64, "Instances", obj_popup_damage); if (pop != noone) { pop.damage_amount = "DEFEND"; pop.text_color = c_aqua; } _action_performed = true; }
              else { _action_performed = false; }
         } else { _action_performed = false; }

         stored_action_data = undefined; selected_target_id = noone;
         if (_action_performed) { global.active_party_member_index++; if (global.active_party_member_index >= ds_list_size(global.battle_party)) { global.active_party_member_index = 0; global.enemy_turn_index = 0; global.battle_state = "waiting_enemy"; alarm[0] = 30; } else { global.battle_state = "player_input"; } }
         else { global.battle_state = "player_input"; }
     } // End of ExecutingAction case logic block
     break; // <<< Break for ExecutingAction case


     case "waiting_after_player": alarm[0]=-1; global.battle_state="check_win_loss"; break;
     case "waiting_next_enemy": break;
     case "waiting_enemy":      break;


    case "check_win_loss":
    { // Start check_win_loss case block
        // Status Damage...
        var _ps_status = ds_list_size(global.battle_party); for (var i = 0; i < _ps_status; i++) { var _pi = global.battle_party[| i]; if (instance_exists(_pi) && variable_instance_exists(_pi, "data") && is_struct(_pi.data)) { var _pd = _pi.data; if (variable_struct_exists(_pd, "status") && _pd.status == "poison") { var psn_dmg = max(1, floor(_pd.maxhp * 0.05)); _pd.hp = max(0, _pd.hp - psn_dmg); if (object_exists(obj_popup_damage)) { var pop = instance_create_layer(_pi.x, _pi.y - 64, "Instances", obj_popup_damage); if (pop != noone) {pop.damage_amount = string(psn_dmg); pop.text_color = c_purple;} } } } }
        var _esc = ds_list_size(global.battle_enemies); for (var i = 0; i < _esc; i++) { var _ei = global.battle_enemies[| i]; if (instance_exists(_ei) && variable_instance_exists(_ei, "data") && is_struct(_ei.data)) { var _ed = _ei.data; if (variable_struct_exists(_ed, "status") && _ed.status == "poison") { var psn_dmg = max(1, floor(_ed.maxhp * 0.05)); _ed.hp = max(0, _ed.hp - psn_dmg); if (object_exists(obj_popup_damage)) { var pop = instance_create_layer(_ei.x, _ei.y - 64, "Instances", obj_popup_damage); if (pop != noone) {pop.damage_amount = string(psn_dmg); pop.text_color = c_purple;} } } } }

        // Check Enemies
        var enemies_remaining = false; var xp_gained = 0;
        var initial_enemy_count = ds_list_size(global.battle_enemies);
        for (var i = initial_enemy_count - 1; i >= 0; i--) {
            if (i >= ds_list_size(global.battle_enemies)) continue;
            var e_inst = global.battle_enemies[| i];
            if (instance_exists(e_inst) && variable_instance_exists(e_inst, "data") && is_struct(e_inst.data) && variable_struct_exists(e_inst.data, "hp")) {
                 var e_data = e_inst.data;
                 if (e_data.hp <= 0) { if (variable_struct_exists(e_data, "xp")) { xp_gained += e_data.xp; } instance_destroy(e_inst); ds_list_delete(global.battle_enemies, i); } else { enemies_remaining = true; }
            } else { if (instance_exists(e_inst)) { instance_destroy(e_inst); } ds_list_delete(global.battle_enemies, i); }
        }
        if (xp_gained > 0) total_xp_from_battle += xp_gained;

        // Check Players
        var players_remaining = false; if(enemies_remaining){var _ps=ds_list_size(global.battle_party);for(var i=0;i<_ps;i++){var p=global.battle_party[|i];if(instance_exists(p)&&variable_instance_exists(p,"data")&&is_struct(p.data)&&p.data.hp>0){players_remaining=true;break;}}}else{players_remaining=true;}

        // Determine outcome
        if (!enemies_remaining) { global.battle_state = "victory"; alarm[0] = 30; }
        else if (!players_remaining) { global.battle_state = "defeat"; alarm[0] = 30; }
        else { // Battle Continues
            var _current_enemy_count = ds_list_size(global.battle_enemies);
            if (global.enemy_turn_index >= _current_enemy_count) {
                 global.active_party_member_index = 0; global.enemy_turn_index = 0;
                 global.battle_state = "player_input";
                 var _nes=_current_enemy_count; if(_nes>0)global.battle_target=clamp(global.battle_target,0,_nes-1);else global.battle_target=0;
            } else {
                 global.battle_state = "waiting_enemy"; alarm[0] = 30;
            }
        }
    } // End of check_win_loss case logic block
    break; // <<< Break for check_win_loss case


    case "enemy_turn":
    { // Start enemy_turn case block
         var _enemy_action_complete = false;
         var _state_changed_during_action = false;

         var _es = ds_list_size(global.battle_enemies);
         if (global.enemy_turn_index < _es) {
             var enemy_inst = global.battle_enemies[| global.enemy_turn_index];

             if (instance_exists(enemy_inst) && variable_instance_exists(enemy_inst,"data") && is_struct(enemy_inst.data) && enemy_inst.data.hp > 0) {
                 var enemy_data = enemy_inst.data;
                 var party_size = ds_list_size(global.battle_party);
                 if (party_size > 0) {
                     // --- Select a RANDOM LIVING target ---
                     var living_targets = [];
                     for (var pt = 0; pt < party_size; pt++) {
                         var temp_target = global.battle_party[| pt];
                         if (instance_exists(temp_target) && variable_instance_exists(temp_target, "data") && is_struct(temp_target.data) && temp_target.data.hp > 0) {
                             array_push(living_targets, temp_target);
                         }
                     }

                     var target_player = noone;
                     if (array_length(living_targets) > 0) {
                         var random_index = irandom(array_length(living_targets) - 1);
                         target_player = living_targets[random_index];
                         show_debug_message("      Enemy targeting random living player: " + target_player.data.name + " (Instance ID: " + string(target_player) + ")");
                     } else { show_debug_message("      No living players found for enemy to target!"); }
                     // --- END Targeting ---

                     if (instance_exists(target_player)) {
                         var target_data = target_player.data; var enemy_atk = enemy_data.atk; var player_def = target_data.def; var dmg = max(1, enemy_atk - player_def); if (target_data.is_defending) dmg = floor(dmg/2); target_data.hp -= dmg; target_data.hp = max(0, target_data.hp); var pop = instance_create_layer(target_player.x, target_player.y-64, "Instances", obj_popup_damage); if (pop!=noone) pop.damage_amount=string(dmg); target_data.is_defending = false;
                         _enemy_action_complete = true;
                         if (target_data.hp <= 0) { global.battle_state = "check_win_loss"; alarm[0] = 5; _state_changed_during_action = true; }
                     } else { _enemy_action_complete = true; }
                 } else { _enemy_action_complete = true; }
             } else { _enemy_action_complete = true; }

             // --- Advance turn logic ---
             if (!_state_changed_during_action) {
                 if (_enemy_action_complete) {
                      global.enemy_turn_index++;
                      if (global.enemy_turn_index >= _es) {
                           global.battle_state = "check_win_loss";
                      } else {
                           global.battle_state = "waiting_next_enemy";
                           alarm[0] = 30;
                      }
                 }
             }

        } else {
            global.battle_state = "check_win_loss";
        }
    } // End of enemy_turn case logic block
    break; // <<< Break for enemy_turn case


    default:
        show_debug_message("WARNING: obj_battle_manager in unknown state: " + string(global.battle_state));
    break; // <<< Break for default case
} // End Switch