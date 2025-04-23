/// obj_battle_manager :: Step Event
// Manages battle state, actions, UI visibility, status effects, party turn order, and target selection.

// --- Declare temporary variables for the event ---
// NOTE: _action_performed MUST be declared inside ExecutingAction if using 'var'.

// --- Control UI Layer Visibility ---
if (variable_global_exists("layer_id_radial_menu") && global.layer_id_radial_menu != -1) {
    var _lid = global.layer_id_radial_menu;
    if (layer_exists(_lid)) {
        var _sv = (global.battle_state == "player_input");
        if (layer_get_visible(_lid) != _sv) {
            layer_set_visible(_lid, _sv);
        }
    }
}

// Process current battle state
switch (global.battle_state) {

    case "player_input":
    case "skill_select":
    case "item_select":
        // Manager waits - Input handled by the active obj_battle_player instance
    break; // Break for these waiting states

    case "TargetSelect":
    { // Braces optional but help readability
        var _enemy_count = ds_list_size(global.battle_enemies);
        if (_enemy_count <= 0) {
            global.battle_state = "check_win_loss";
            // State changed, rely on outer break
        } else {
            // Read Input
            var P = 0;
            var _up_pressed = keyboard_check_pressed(vk_up) || gamepad_button_check_pressed(P, gp_padu);
            var _down_pressed = keyboard_check_pressed(vk_down) || gamepad_button_check_pressed(P, gp_padd);
            var _confirm_pressed = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(P, gp_face1);
            var _cancel_pressed = keyboard_check_pressed(vk_escape) || gamepad_button_check_pressed(P, gp_face2);

            // Handle Input
            if (_down_pressed) { global.battle_target = (global.battle_target + 1) % _enemy_count; }
            else if (_up_pressed) { global.battle_target = (global.battle_target - 1 + _enemy_count) % _enemy_count; }
            else if (_confirm_pressed) {
                if (global.battle_target >= 0 && global.battle_target < _enemy_count) {
                     selected_target_id = global.battle_enemies[| global.battle_target];
                     if (instance_exists(selected_target_id)) {
                         global.battle_state = "ExecutingAction"; // Change state
                     } else { selected_target_id = noone; global.battle_target = 0; }
                } else { selected_target_id = noone; global.battle_target = 0; }
                 // If state changed, next step will handle it.
            }
            else if (_cancel_pressed) {
                var _prev = "player_input"; if (is_struct(stored_action_data)) { if (variable_struct_exists(stored_action_data,"usable_in_battle")) _prev="item_select"; else if (variable_struct_exists(stored_action_data,"cost")) _prev="skill_select"; }
                global.battle_state = _prev; // Change state
                stored_action_data = undefined;
                selected_target_id = noone;
                 // If state changed, next step will handle it.
            }
        }
    } // End of TargetSelect case logic block
    break; // <<< Break for TargetSelect case


     case "ExecutingAction":
     { // Braces optional but help readability
         var _action_performed = false; // <<< Declare INSIDE case scope
         // show_debug_message("--> START ExecutingAction for Party Member Index: " + string(global.active_party_member_index));
         var _player_actor = noone; if (ds_list_size(global.battle_party) > global.active_party_member_index) { _player_actor = global.battle_party[| global.active_party_member_index]; }

         if (instance_exists(_player_actor) && variable_instance_exists(_player_actor, "data") && is_struct(_player_actor.data)) {
              var _player_data = _player_actor.data;
              // show_debug_message("    Actor: " + _player_data.name);
              // --- ACTION LOGIC ---
              if (stored_action_data == "Attack") { if (selected_target_id != noone && instance_exists(selected_target_id)) { var _ti=selected_target_id; if (variable_instance_exists(_ti,"data") && is_struct(_ti.data)) { var _td=_ti.data; var pa=_player_data.atk; var td=_td.def; var pl=_player_data.luk; var cc=5+floor(pl/4); var ic=(irandom(99)<cc); var cm=1.5; var dmg=max(1,pa-td); if(ic)dmg=floor(dmg*cm); if(variable_struct_exists(_td,"is_defending")&&_td.is_defending)dmg=floor(dmg/2); _td.hp-=dmg; _td.hp=max(0,_td.hp); if(object_exists(obj_popup_damage)){var pop=instance_create_layer(_ti.x,_ti.y-64,"Instances",obj_popup_damage); if(pop!=noone){pop.damage_amount=string(dmg);if(ic){pop.damage_amount="CRIT! "+pop.damage_amount;pop.text_color=c_yellow;}}} _action_performed=true; } else {_action_performed=false;} } else {_action_performed=false;} }
              else if (is_struct(stored_action_data) && variable_struct_exists(stored_action_data, "usable_in_battle")) { /* Item Logic */ var _item=stored_action_data;var _target_inst=selected_target_id;var _ie=false;switch(_item.effect){case "heal_hp":if(instance_exists(_target_inst)&&variable_instance_exists(_target_inst,"data")&&is_struct(_target_inst.data)){var _td=_target_inst.data;if(variable_struct_exists(_td,"hp")&&variable_struct_exists(_td,"maxhp")){var ohp=_td.hp;_td.hp=min(_td.hp+_item.value,_td.maxhp);var hld=_td.hp-ohp;if(hld>0){if(object_exists(obj_popup_damage)){var pop=instance_create_layer(_target_inst.x,_target_inst.y-64,"Instances",obj_popup_damage);if(pop!=noone){pop.damage_amount="+"+string(hld);pop.text_color=c_lime;}}_ie=true;}}}break;case "damage_enemy":if(instance_exists(_target_inst)&&variable_instance_exists(_target_inst,"data")&&is_struct(_target_inst.data)){var _td=_target_inst.data;if(variable_struct_exists(_td,"hp")){var dmg=_item.value;_td.hp=max(0,_td.hp-dmg);if(object_exists(obj_popup_damage)){var pop=instance_create_layer(_target_inst.x,_target_inst.y-64,"Instances",obj_popup_damage);if(pop!=noone)pop.damage_amount=string(dmg);}_ie=true;}}break;case "cure_status":if(instance_exists(_target_inst)&&variable_instance_exists(_target_inst,"data")&&is_struct(_target_inst.data)){var _td=_target_inst.data;var stc=_item.value;if(variable_struct_exists(_td,"status")&&_td.status==stc){_td.status="none";if(object_exists(obj_popup_damage)){var pop=instance_create_layer(_target_inst.x,_target_inst.y-64,"Instances",obj_popup_damage);if(pop!=noone){pop.damage_amount="Cured!";pop.text_color=c_aqua;}}_ie=true;}else{_ie=true;}}break;default:_ie=true;break;}_action_performed=_ie; }
              else if (is_struct(stored_action_data)) { _action_performed = scr_CastSkill(_player_actor.id, stored_action_data, selected_target_id); }
              else if (stored_action_data == "Defend") { _player_data.is_defending = true; var pop = instance_create_layer(_player_actor.x, _player_actor.y - 64, "Instances", obj_popup_damage); if (pop != noone) { pop.damage_amount = "DEFEND"; pop.text_color = c_aqua; } _action_performed = true; }
              else { _action_performed = false; }
         } else { _action_performed = false; }

         // --- Cleanup and Turn Progression ---
         stored_action_data = undefined; selected_target_id = noone;
         if (_action_performed) { global.active_party_member_index++; if (global.active_party_member_index >= ds_list_size(global.battle_party)) { global.active_party_member_index = 0; global.enemy_turn_index = 0; global.battle_state = "waiting_enemy"; alarm[0] = 30; } else { global.battle_state = "player_input"; } }
         else { global.battle_state = "player_input"; }
     } // End of ExecutingAction case logic block
     break; // <<< Break for ExecutingAction case


     case "waiting_after_player": alarm[0]=-1; global.battle_state="check_win_loss"; break;
     case "waiting_next_enemy": break; // Correct break
     case "waiting_enemy":      break; // Correct break


    case "check_win_loss": {
        // --- Check Win/Loss + Status Damage + Enemy Removal ---
        show_debug_message("--> START check_win_loss | Enemy Turn Index BEFORE check: " + string(global.enemy_turn_index));
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
                 if (e_data.hp <= 0) {
                     if (variable_struct_exists(e_data, "xp")) { xp_gained += e_data.xp; }
                     instance_destroy(e_inst); ds_list_delete(global.battle_enemies, i);
                 } else { enemies_remaining = true; }
            } else { if (instance_exists(e_inst)) { instance_destroy(e_inst); } ds_list_delete(global.battle_enemies, i); }
        }
        if (xp_gained > 0) total_xp_from_battle += xp_gained;

        // Check Players
        var players_remaining = false; if(enemies_remaining){var _ps=ds_list_size(global.battle_party);for(var i=0;i<_ps;i++){var p=global.battle_party[|i];if(instance_exists(p)&&variable_instance_exists(p,"data")&&is_struct(p.data)&&p.data.hp>0){players_remaining=true;break;}}}else{players_remaining=true;}

        // Determine outcome
        if (!enemies_remaining) { global.battle_state = "victory"; alarm[0] = 30; }
        else if (!players_remaining) { global.battle_state = "defeat"; alarm[0] = 30; }
        else { // Battle Continues
            // --- FIX: Check if enemy turn sequence just completed ---
            // We know enemies finished if the enemy index is >= the current count
            var _current_enemy_count = ds_list_size(global.battle_enemies); // Get count *after* potential defeats
            show_debug_message("    CheckWinLoss: Battle Continues. Checking enemy_turn_index (" + string(global.enemy_turn_index) + ") vs current enemy count (" + string(_current_enemy_count) + ")");
            if (global.enemy_turn_index >= _current_enemy_count) {
                 show_debug_message("    CheckWinLoss: Enemy round finished. Starting player round.");
                 global.active_party_member_index = 0; // Reset to first player
                 global.enemy_turn_index = 0;         // Reset enemy index for next round
                 global.battle_state = "player_input"; // Set state for player
                 var _nes=_current_enemy_count; if(_nes>0)global.battle_target=clamp(global.battle_target,0,_nes-1);else global.battle_target=0;
            } else {
                 // This means check_win_loss was called mid-enemy-turn (e.g., player died)
                 // OR after player turn but before first enemy. Go back to waiting.
                 show_debug_message("    CheckWinLoss: Enemy turn pending or interrupted. -> waiting_enemy");
                 global.battle_state = "waiting_enemy";
                 // Don't reset enemy_turn_index here
                 alarm[0] = 30; // Delay before next enemy action
            }
            // --- END FIX ---
        }
        show_debug_message("<-- END check_win_loss (New State Set: " + string(global.battle_state) + ")");
    }
    break; // <<< Correct break for check_win_loss case


    case "enemy_turn": {
         // --- Enemy Turn Logic ---
         // show_debug_message("--> START enemy_turn | Current Enemy Index: " + string(global.enemy_turn_index));
         var _enemy_action_complete = false;
         var _state_changed_during_action = false;

         var _es = ds_list_size(global.battle_enemies);
         if (global.enemy_turn_index < _es) {
             var enemy_inst = global.battle_enemies[| global.enemy_turn_index];
             // show_debug_message("    Processing Enemy Instance ID: " + string(enemy_inst));

             if (instance_exists(enemy_inst) && variable_instance_exists(enemy_inst,"data") && is_struct(enemy_inst.data) && enemy_inst.data.hp > 0) {
                 var enemy_data = enemy_inst.data;
                 // show_debug_message("    Enemy " + enemy_data.name + " (HP:" + string(enemy_data.hp) + ") acts...");
                 // --- Simple Attack AI ---
                 var party_size = ds_list_size(global.battle_party);
                 if (party_size > 0) {
                     var target_player = noone; for (var pt = 0; pt < party_size; pt++) { var temp_target = global.battle_party[| pt]; if (instance_exists(temp_target) && temp_target.data.hp > 0) { target_player = temp_target; break; } }
                     if (instance_exists(target_player)) {
                         var target_data = target_player.data; var enemy_atk = enemy_data.atk; var player_def = target_data.def; var dmg = max(1, enemy_atk - player_def); if (target_data.is_defending) dmg = floor(dmg/2); target_data.hp -= dmg; target_data.hp = max(0, target_data.hp); var pop = instance_create_layer(target_player.x, target_player.y-64, "Instances", obj_popup_damage); if (pop!=noone) pop.damage_amount=string(dmg); target_data.is_defending = false;
                         // show_debug_message("      Attacked " + target_data.name + " for " + string(dmg) + " damage. Target HP: " + string(target_data.hp));
                         if (irandom(99) < 25) { if (target_data.status == "none") { target_data.status = "poison"; /* Poison Popup */ } }
                         _enemy_action_complete = true;
                         if (target_data.hp <= 0) { global.battle_state = "check_win_loss"; alarm[0] = 5; _state_changed_during_action = true; }
                     } else { _enemy_action_complete = true; }
                 } else { _enemy_action_complete = true; }
                 // --- End Simple Attack AI ---
             } else { _enemy_action_complete = true; }

             // --- Advance to next enemy IF the state hasn't changed AND action completed ---
             if (!_state_changed_during_action) {
                 if (_enemy_action_complete) {
                      global.enemy_turn_index++;
                      // show_debug_message("    Incremented enemy_turn_index to: " + string(global.enemy_turn_index));
                      if (global.enemy_turn_index >= _es) {
                           show_debug_message("🏁 Enemy Turn: Last enemy acted. -> check_win_loss");
                           global.battle_state = "check_win_loss"; // Go check win/loss
                      } else {
                           global.battle_state = "waiting_next_enemy"; // Wait before next enemy acts
                           alarm[0] = 30;
                           // show_debug_message("    State -> waiting_next_enemy");
                      }
                 }
             } // else { show_debug_message("    State changed during enemy action."); }

        } else { // Index was already >= _es
            show_debug_message("🏁 Enemy Turn: Index >= Size check. -> check_win_loss");
            global.battle_state = "check_win_loss";
        }
    } // End of enemy_turn case logic block
    break; // <<< Correct break for enemy_turn case


    default:
        show_debug_message("WARNING: obj_battle_manager in unknown state: " + string(global.battle_state));
    break; // <<< Correct break for default case
} // End Switch