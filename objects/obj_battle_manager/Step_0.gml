/// obj_battle_manager :: Step Event
// Manages battle state, executes actions (Attack, Skill, Item), controls UI visibility.
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
            show_debug_message("Set Layer (ID:" + string(_layer_id) + ") Visible: " + string(_should_be_visible) + " (State: "+string(global.battle_state)+")");
        }
    } else { show_debug_message("WARNING (Manager Step): Layer with stored ID " + string(_layer_id) + " no longer exists!"); }
} else { show_debug_message("WARNING (Manager Step): global.layer_id_radial_menu not set or invalid!"); }
// --- End UI Layer Control ---


// Process current battle state
switch (global.battle_state) {

    case "player_input":
    case "skill_select":
    case "item_select": // Added item_select here - manager waits for input
        // Manager waits - Input handled elsewhere (obj_battle_player)
        break;

    case "TargetSelect": {
        // ... (Target select logic - OK) ...
        var _ec=ds_list_size(global.battle_enemies);if(_ec==0){global.battle_state="check_win_loss";break;}var _u=keyboard_check_pressed(vk_up)||gamepad_button_check_pressed(0,gp_padu);var _d=keyboard_check_pressed(vk_down)||gamepad_button_check_pressed(0,gp_padd);var _c=keyboard_check_pressed(vk_enter)||keyboard_check_pressed(vk_space)||gamepad_button_check_pressed(0,gp_face1);var _x=keyboard_check_pressed(vk_escape)||gamepad_button_check_pressed(0,gp_face2);if(_d)global.battle_target=(_ec>0)?(global.battle_target+1)%_ec:0;if(_u)global.battle_target=(_ec>0)?(global.battle_target-1+_ec)%_ec:0;if(_c){if(global.battle_target>=0&&global.battle_target<_ec){selected_target_id=global.battle_enemies[|global.battle_target];if(instance_exists(selected_target_id)){global.battle_state="ExecutingAction";}else{selected_target_id=noone;global.battle_target=0;}}else{selected_target_id=noone;global.battle_target=0;}break;}if(_x){if(is_struct(stored_action_data)&&variable_struct_exists(stored_action_data,"usable_in_battle")){global.battle_state="item_select";}else{global.battle_state="player_input";}stored_action_data=undefined;selected_target_id=noone;} // Go back to item/skill/player input
    }
    break;


     case "ExecutingAction": {
         show_debug_message("--> START ExecutingAction");
         var _action_performed = false;
         var _player_actor = (ds_list_size(global.battle_party) > 0) ? global.battle_party[| 0] : noone; // Battle player instance

         if (instance_exists(_player_actor) && variable_instance_exists(_player_actor, "data") && is_struct(_player_actor.data)) {
              var _player_data = _player_actor.data; // Player's battle data

              // --- ACTION LOGIC ---
              if (stored_action_data == "Attack") {
                   if (selected_target_id != noone && instance_exists(selected_target_id)) { var _t = selected_target_id; if (variable_instance_exists(_t,"data") && is_struct(_t.data)) { var dmg = max(1, _player_data.atk - _t.data.def); if (variable_struct_exists(_t.data, "is_defending") && _t.data.is_defending) { dmg = floor(dmg/2); } _t.data.hp -= dmg; _t.data.hp = max(0, _t.data.hp); var pop = instance_create_layer(_t.x, _t.y-64, "Instances", obj_popup_damage); if (pop != noone) pop.damage_amount = string(dmg); _action_performed = true; } }
              }
              // --- Check if it's an Item Struct (has 'usable_in_battle' property) ---
              else if (is_struct(stored_action_data) && variable_struct_exists(stored_action_data, "usable_in_battle")) {
                   var _item = stored_action_data; // It's an item definition struct
                   var _target_inst = selected_target_id; // Target chosen in TargetSelect or set in item menu
                   show_debug_message("  -> Executing Item: " + _item.name + " | Target: " + string(_target_inst));

                   // Apply item effect based on item definition
                   switch (_item.effect) {
                       case "heal_hp":
                           if (instance_exists(_target_inst) && variable_instance_exists(_target_inst, "data") && is_struct(_target_inst.data)) {
                               var _target_data = _target_inst.data;
                               if (variable_struct_exists(_target_data, "hp") && variable_struct_exists(_target_data, "maxhp")) {
                                   var old_hp = _target_data.hp;
                                   _target_data.hp = min(_target_data.hp + _item.value, _target_data.maxhp);
                                   var healed = _target_data.hp - old_hp;
                                   if (object_exists(obj_popup_damage)) { var pop = instance_create_layer(_target_inst.x, _target_inst.y - 64, "Instances", obj_popup_damage); if (pop != noone) {pop.damage_amount = "+" + string(healed); pop.text_color = c_lime;} }
                                   show_debug_message("     Used " + _item.name + ", healed " + string(healed) + " HP.");
                                   _action_performed = true; // Mark action as done
                               } else { show_debug_message("     Item Heal Error: Target missing hp/maxhp."); }
                           } else { show_debug_message("     Item Heal Error: Invalid target instance/data."); }
                           break;

                       case "damage_enemy":
                            if (instance_exists(_target_inst) && variable_instance_exists(_target_inst, "data") && is_struct(_target_inst.data)) {
                                var _target_data = _target_inst.data;
                                if (variable_struct_exists(_target_data, "hp")) {
                                    var dmg = _item.value;
                                    // TODO: Add elemental weakness/resistance checks?
                                    _target_data.hp = max(0, _target_data.hp - dmg);
                                     if (object_exists(obj_popup_damage)) { var pop = instance_create_layer(_target_inst.x, _target_inst.y - 64, "Instances", obj_popup_damage); if (pop != noone) pop.damage_amount = string(dmg); }
                                    show_debug_message("     Used " + _item.name + ", dealt " + string(dmg) + " damage. Target HP: " + string(_target_data.hp));
                                    _action_performed = true; // Mark action as done
                                } else { show_debug_message("     Item Damage Error: Target missing hp."); }
                            } else { show_debug_message("     Item Damage Error: Invalid target instance/data."); }
                           break;

                       case "cure_status":
                            if (instance_exists(_target_inst) && variable_instance_exists(_target_inst, "data") && is_struct(_target_inst.data)) {
                                var _target_data = _target_inst.data;
                                var status_to_cure = _item.value;
                                // TODO: Implement status effect system and removal logic
                                // e.g., if (variable_struct_exists(_target_data, "status") && _target_data.status == status_to_cure) { _target_data.status = "none"; _action_performed = true; }
                                show_debug_message("     Used " + _item.name + " to cure " + string(status_to_cure) + " (Effect logic not fully implemented).");
                                _action_performed = true; // Mark as performed even if logic pending
                            } else { show_debug_message("     Item Cure Error: Invalid target instance/data."); }
                           break;

                       default:
                           show_debug_message("     WARNING: Unknown item effect '" + string(_item.effect) + "'");
                           _action_performed = true; // Assume action happened to prevent loop
                           break;
                   }
              }
              // --- Check if it's a Skill Struct (doesn't have 'usable_in_battle') ---
              else if (is_struct(stored_action_data)) {
                   var _skill = stored_action_data;
                   var _target_id = selected_target_id;
                   var _caster_id = _player_actor.id;
                   show_debug_message("  -> Calling scr_CastSkill for skill: " + string(_skill.name));
                   _action_performed = scr_CastSkill(_caster_id, _skill, _target_id); // Call script, returns true/false
                   show_debug_message("  -> scr_CastSkill returned: " + string(_action_performed));
              }
              // --- Defend Action ---
               else if (stored_action_data == "Defend") {
                 _player_data.is_defending = true;
                 var pop = instance_create_layer(_player_actor.x, _player_actor.y - 64, "Instances", obj_popup_damage); if (pop != noone) { pop.damage_amount = "DEFEND"; pop.text_color = c_aqua; }
                 _action_performed = true;
              }
              // --- End Action Logic ---
         } else { show_debug_message("Execute Error: Player battle instance or its data not found!"); }

         // Cleanup and transition
         stored_action_data = undefined;
         selected_target_id = noone;
         if (_action_performed) { // Action was performed (Attack, Skill, Item, Defend)
              global.battle_state = "waiting_after_player"; // Go to wait state before check
              alarm[0] = 30; // Set delay
         } else { // Action failed (e.g., not enough MP, invalid target for skill/item)
              global.battle_state = "player_input"; // Go back to player immediately
         }
         show_debug_message("<-- END ExecutingAction (State->" + global.battle_state +")");
     }
     break; // End ExecutingAction


     case "waiting_after_player": case "waiting_next_enemy": case "waiting_enemy": break; // Wait states


    case "check_win_loss": {
        // ... (check_win_loss logic remains the same) ...
        show_debug_message("--> START check_win_loss Step");var enemies_remaining=false;var players_remaining=false;var xp_gained=0;var _ec=ds_list_size(global.battle_enemies);for(var i=_ec-1;i>=0;i--){if(i>=ds_list_size(global.battle_enemies))continue;var e=global.battle_enemies[|i];if(instance_exists(e)&&variable_instance_exists(e,"data")&&is_struct(e.data)&&variable_struct_exists(e.data,"hp")){if(e.data.hp<=0){if(variable_struct_exists(e.data,"xp"))xp_gained+=e.data.xp;instance_destroy(e);ds_list_delete(global.battle_enemies,i);}else{enemies_remaining=true;}}else{ds_list_delete(global.battle_enemies,i);}}if(xp_gained>0)total_xp_from_battle+=xp_gained;if(enemies_remaining){var _ps=ds_list_size(global.battle_party);for(var i=0;i<_ps;i++){var p=global.battle_party[|i];if(instance_exists(p)&&variable_instance_exists(p,"data")&&is_struct(p.data)&&p.data.hp>0){players_remaining=true;break;}}}else{players_remaining=true;} show_debug_message("    Check Results: Enemies="+string(enemies_remaining)+", Players="+string(players_remaining));if(!enemies_remaining){global.battle_state="victory";alarm[0]=30;}else if(!players_remaining){global.battle_state="defeat";alarm[0]=30;}else{if(global.enemy_turn_index>=ds_list_size(global.battle_enemies)){global.battle_state="player_input";var _nes=ds_list_size(global.battle_enemies);if(_nes>0)global.battle_target=clamp(global.battle_target,0,_nes-1);else global.battle_target=0;global.enemy_turn_index=0;}else{global.battle_state="waiting_enemy";global.enemy_turn_index=0;alarm[0]=30;}}show_debug_message("<-- END check_win_loss (New State Set: "+string(global.battle_state)+")");
    }
    break; // End check_win_loss


    case "enemy_turn": {
        // ... (enemy_turn logic remains the same) ...
         var _ci=global.enemy_turn_index;var _es=ds_list_size(global.battle_enemies); show_debug_message("--> START enemy_turn | Index="+string(_ci)+" | Size="+string(_es)); if(_ci<_es){var enemy=global.battle_enemies[|_ci];if(instance_exists(enemy)&&variable_instance_exists(enemy,"data")&&is_struct(enemy.data)&&enemy.data.hp>0){if(ds_list_size(global.battle_party)>0){var target=global.battle_party[|0];if(instance_exists(target)&&variable_instance_exists(target,"data")&&is_struct(target.data)){var td=target.data;var dmg=max(1,enemy.data.atk-td.def);if(variable_struct_exists(td,"is_defending")&&td.is_defending)dmg=floor(dmg/2);td.hp-=dmg;td.hp=max(0,td.hp);var pop=instance_create_layer(target.x,target.y-64,"Instances",obj_popup_damage);if(pop!=noone)pop.damage_amount=string(dmg);td.is_defending=false;if(td.hp<=0){global.battle_state="check_win_loss";alarm[0]=5;break;}}}} global.enemy_turn_index+=1;global.battle_state="waiting_next_enemy";alarm[0]=30;}else{show_debug_message("🏁 All enemies processed this round. Going back to check win/loss."); global.battle_state="check_win_loss";}
    }
    break; // End enemy_turn


    default: break;
} // End Switch