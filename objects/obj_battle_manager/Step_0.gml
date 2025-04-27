/// obj_battle_manager :: Step Event

switch (global.battle_state) {

    case "player_input":
    case "skill_select":
    case "item_select":
        break;

    case "TargetSelect":
    {
        show_debug_message("Manager Step: In TargetSelect State");
        if (!variable_global_exists("battle_enemies") || !ds_exists(global.battle_enemies, ds_type_list)) {
             global.battle_state = "check_win_loss";
             break;
        }
        var _enemy_count = ds_list_size(global.battle_enemies);

        if (_enemy_count <= 0) {
            global.battle_state = "check_win_loss";
            stored_action_data = undefined;
            selected_target_id = noone;
        } else {
            var P = 0;
            var _up = keyboard_check_pressed(vk_up) || gamepad_button_check_pressed(P, gp_padu);
            var _down = keyboard_check_pressed(vk_down) || gamepad_button_check_pressed(P, gp_padd);
            var _conf = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(P, gp_face1);
            var _cancel = keyboard_check_pressed(vk_escape)|| gamepad_button_check_pressed(P, gp_face2);

            if (_up) show_debug_message(" -> TargetSelect: UP pressed");
            if (_down) show_debug_message(" -> TargetSelect: DOWN pressed");
            if (_conf) show_debug_message(" -> TargetSelect: CONFIRM pressed");
            if (_cancel) show_debug_message(" -> TargetSelect: CANCEL pressed");

            if (_down) {
                global.battle_target = (global.battle_target + 1) % _enemy_count;
            }
            else if (_up) {
                global.battle_target = (global.battle_target - 1 + _enemy_count) mod _enemy_count;
            }
            else if (_conf) {
                show_debug_message(" -> Target Confirmed! Target index: " + string(global.battle_target));
                if (global.battle_target >= 0 && global.battle_target < _enemy_count) {
                    selected_target_id = global.battle_enemies[| global.battle_target];
                    if (instance_exists(selected_target_id)) {
                        show_debug_message(" -> Valid target instance found (ID: " + string(selected_target_id) + "). Changing state to ExecutingAction.");
                        global.battle_state = "ExecutingAction";
                    } else { // Target instance invalidated
                        show_debug_message(" -> ERROR: Selected target instance does not exist! Returning.");
                        var _prev = "player_input";
                        if (is_struct(stored_action_data)) {
                             if (variable_struct_exists(stored_action_data, "usable_in_battle")) { _prev="item_select"; }
                             else if (variable_struct_exists(stored_action_data, "cost")) { _prev="skill_select"; }
                        }
                        // If returning to item select due to invalid target, add item back
                        if (_prev == "item_select" && script_exists(scr_AddInventoryItem) && is_struct(stored_action_data) && variable_struct_exists(stored_action_data, "item_key")) {
                             scr_AddInventoryItem(stored_action_data.item_key, 1);
                        }
                        global.battle_state = _prev;
                        stored_action_data = undefined;
                        selected_target_id = noone;
                        global.battle_target = 0; // Reset target index
                    } // End else (instance_exists check)
                } else { // Index somehow invalid
                     show_debug_message(" -> ERROR: global.battle_target index invalid! Resetting.");
                     selected_target_id = noone;
                     global.battle_target = 0;
                     global.battle_state = "player_input"; // Go back to safety
                     stored_action_data = undefined;
                } // End else (index validity check)
            } // End else if (_conf)
            else if (_cancel) {
                show_debug_message(" -> Target selection Cancelled. Returning.");
                var _prev = "player_input";
                if (is_struct(stored_action_data)) {
                    if (variable_struct_exists(stored_action_data, "usable_in_battle")) {
                        _prev="item_select";
                        // Add item back if cancelled AFTER selection
                        if (script_exists(scr_AddInventoryItem) && variable_struct_exists(stored_action_data, "item_key")) {
                            scr_AddInventoryItem(stored_action_data.item_key, 1);
                            show_debug_message(" -> Restored item '" + stored_action_data.item_key + "'.");
                        }
                    } else if (variable_struct_exists(stored_action_data, "cost")) {
                         _prev="skill_select";
                    }
                }
                global.battle_state = _prev;
                stored_action_data = undefined;
                selected_target_id = noone;
            } // End else if (_cancel)
        } // End else (_enemy_count > 0)
    } // End case block scope
    break; // End TargetSelect

    case "ExecutingAction":
    {
        show_debug_message("Manager Step: In ExecutingAction State");
        var _action_performed = false; var _player_actor = noone;
        if (variable_global_exists("active_party_member_index") && variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) { if (ds_list_size(global.battle_party) > global.active_party_member_index && global.active_party_member_index >= 0) { _player_actor = global.battle_party[| global.active_party_member_index]; } }
        show_debug_message(" -> Stored Action Data: " + string(stored_action_data)); show_debug_message(" -> Selected Target ID: " + string(selected_target_id));

        if (instance_exists(_player_actor)) {
            var user_status_info = script_exists(scr_GetStatus) ? scr_GetStatus(_player_actor) : undefined;
            if (is_struct(user_status_info)) { if (user_status_info.effect == "shame") { _action_performed = true; } else if (user_status_info.effect == "bind" && irandom(99) < 50) { _action_performed = true; } }

            if (!_action_performed) {
                var _pd = _player_actor.data;
                if (stored_action_data == "Attack") { if (script_exists(scr_PerformAttack)) { _action_performed = scr_PerformAttack(_player_actor, selected_target_id); } else { _action_performed = false; } }
                else if (is_struct(stored_action_data) && variable_struct_exists(stored_action_data, "usable_in_battle")) { if (script_exists(scr_UseItem)) { _action_performed = scr_UseItem(_player_actor, stored_action_data, selected_target_id); } else { _action_performed = false; } }
                else if (is_struct(stored_action_data) && variable_struct_exists(stored_action_data, "effect")) { if (script_exists(scr_CastSkill)) { _action_performed = scr_CastSkill(_player_actor, stored_action_data, selected_target_id); } else { _action_performed = false; } }
                else if (stored_action_data == "Defend") { if (variable_struct_exists(_pd, "is_defending")) { _pd.is_defending = true; } _action_performed = true; }
                else { _action_performed = false; }
            }
        } else { _action_performed = false; }

        stored_action_data = undefined; selected_target_id = noone;
        show_debug_message(" -> Final Action Performed Flag: " + string(_action_performed));
        if (_action_performed) {
            if(instance_exists(_player_actor) && variable_instance_exists(_player_actor,"data") && is_struct(_player_actor.data) && variable_struct_exists(_player_actor.data,"is_defending")) { _player_actor.data.is_defending = false; }
            global.active_party_member_index++;
            if (ds_exists(global.battle_party, ds_type_list) && global.active_party_member_index >= ds_list_size(global.battle_party)) { global.active_party_member_index = 0; global.enemy_turn_index = 0; global.battle_state = "waiting_enemy"; alarm[0] = 30; }
            else { global.battle_state = "player_input"; }
        } else { global.battle_state = "player_input"; }
    }
    break; // End ExecutingAction

    case "waiting_after_player": alarm[0] = -1; global.battle_state = "check_win_loss"; break;
    case "waiting_next_enemy": break;
    case "waiting_enemy": break;

    case "enemy_turn":
    {
        if (alarm[0] > 0) break;
        show_debug_message("Manager Step: In enemy_turn State (Index: " + string(global.enemy_turn_index) + ")");
        var _enemy_acted = false;
        if (!ds_exists(global.battle_enemies, ds_type_list)) { global.battle_state = "check_win_loss"; break;}
        var _sz = ds_list_size(global.battle_enemies);
        show_debug_message("  Enemy List Size: " + string(_sz));

        if (global.enemy_turn_index < _sz) {
            var e_inst = global.battle_enemies[| global.enemy_turn_index];
            show_debug_message("  Processing Enemy Instance ID: " + string(e_inst));
            if (instance_exists(e_inst) && variable_instance_exists(e_inst,"data") && is_struct(e_inst.data) && variable_struct_exists(e_inst.data,"hp") && e_inst.data.hp > 0) {
                 show_debug_message("   -> Enemy is valid and alive (HP: " + string(e_inst.data.hp) + ")");
                 var enemy_status_info = script_exists(scr_GetStatus) ? scr_GetStatus(e_inst) : undefined;
                 show_debug_message("   -> Enemy Status Check result: " + string(enemy_status_info));
                 if (is_struct(enemy_status_info) && enemy_status_info.effect == "bind" && irandom(99) < 50) { _enemy_acted = true; }
                 else { if (script_exists(scr_EnemyAttackRandom)) { _enemy_acted = scr_EnemyAttackRandom(e_inst); show_debug_message("   -> scr_EnemyAttackRandom returned: " + string(_enemy_acted)); } else { _enemy_acted = true; } }
             } else { _enemy_acted = true; }
             show_debug_message("  -> Enemy Acted Flag for index " + string(global.enemy_turn_index) + ": " + string(_enemy_acted));
             if (_enemy_acted) { global.enemy_turn_index++; show_debug_message("  -> Incremented enemy_turn_index to: " + string(global.enemy_turn_index)); if (global.enemy_turn_index >= _sz) { global.battle_state = "check_win_loss"; show_debug_message("   -> End of enemy phase. Switching to check_win_loss."); } else { global.battle_state = "waiting_next_enemy"; alarm[0] = 30; show_debug_message("   -> Moving to next enemy. Switching to waiting_next_enemy."); } }
             else { alarm[0] = 5; }
        } else { global.battle_state = "check_win_loss"; }
    }
    break; // End enemy_turn

    case "check_win_loss":
    {
        show_debug_message("Manager Step: In check_win_loss State");
        if (script_exists(scr_UpdateStatusEffects)) { scr_UpdateStatusEffects(); } else { show_debug_message("ERROR: scr_UpdateStatusEffects script missing!"); }
        var xp_gained_this_check = 0; if (ds_exists(global.battle_enemies, ds_type_list)) { for (var i = ds_list_size(global.battle_enemies) - 1; i >= 0; i--) { var e=global.battle_enemies[|i]; if(instance_exists(e)){ if (variable_instance_exists(e,"data") && is_struct(e.data) && variable_struct_exists(e.data,"hp") && e.data.hp <= 0){ var xp_val = variable_struct_exists(e.data,"xp_value")?e.data.xp_value : (variable_struct_exists(e.data,"xp")?e.data.xp : 0); xp_gained_this_check += xp_val; instance_destroy(e); ds_list_delete(global.battle_enemies, i); } } else { ds_list_delete(global.battle_enemies,i); } } } total_xp_from_battle += xp_gained_this_check;
        show_debug_message(" -> CheckWinLoss: XP gained this check = " + string(xp_gained_this_check) + ", Total XP = " + string(total_xp_from_battle));
        var any_party_alive = false; if(ds_exists(global.battle_party,ds_type_list)){for(var i=0;i<ds_list_size(global.battle_party); i++){var p=global.battle_party[|i]; if(instance_exists(p) && variable_instance_exists(p,"data") && is_struct(p.data) && p.data.hp > 0){any_party_alive=true; break;}}}
        var any_enemies_alive = (ds_exists(global.battle_enemies, ds_type_list) && ds_list_size(global.battle_enemies) > 0);
        if (!any_enemies_alive && any_party_alive) { show_debug_message(" -> Condition: Victory!"); global.battle_state = "victory"; alarm[0] = 60; }
        else if (!any_party_alive) { show_debug_message(" -> Condition: Defeat!"); global.battle_state = "defeat"; alarm[0] = 60; }
        else { show_debug_message(" -> Battle continues. Starting player turn."); global.active_party_member_index = 0; global.enemy_turn_index=0; global.battle_state = "player_input"; if(!any_enemies_alive) global.battle_target = -1; else global.battle_target = 0; }
    }
    break; // End check_win_loss

    case "victory": case "defeat": case "return_to_field": break;
    default: if (get_timer() mod 60 == 0) { show_debug_message("WARNING: obj_battle_manager in unknown state: " + string(global.battle_state)); } break;
} // End Switch