/// obj_battle_manager :: Step Event
/// @description Manages battle state, actions, UI visibility, status effects, party turn order, and target selection.

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
        break;

    case "TargetSelect":
    {
        var _enemy_count = ds_list_size(global.battle_enemies);
        if (_enemy_count <= 0) {
            global.battle_state = "check_win_loss";
        } else {
            var P = 0;
            var _up    = keyboard_check_pressed(vk_up)   || gamepad_button_check_pressed(P, gp_padu);
            var _down  = keyboard_check_pressed(vk_down) || gamepad_button_check_pressed(P, gp_padd);
            var _conf  = keyboard_check_pressed(vk_enter)|| keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(P, gp_face1);
            var _cancel= keyboard_check_pressed(vk_escape)|| gamepad_button_check_pressed(P, gp_face2);

            if (_down)  global.battle_target = (global.battle_target + 1) % _enemy_count;
            else if (_up) global.battle_target = (global.battle_target - 1 + _enemy_count) % _enemy_count;
            else if (_conf) {
                if (global.battle_target >= 0 && global.battle_target < _enemy_count) {
                    selected_target_id = global.battle_enemies[| global.battle_target];
                    if (instance_exists(selected_target_id)) {
                        global.battle_state = "ExecutingAction";
                        break;
                    }
                }
                selected_target_id = noone;
                global.battle_target = 0;
            }
            else if (_cancel) {
                var _prev = "player_input";
                if (is_struct(stored_action_data)) {
                    if      (variable_struct_exists(stored_action_data, "usable_in_battle")) _prev="item_select";
                    else if (variable_struct_exists(stored_action_data, "cost"))             _prev="skill_select";
                }
                global.battle_state = _prev;
                stored_action_data  = undefined;
                selected_target_id  = noone;
                break;
            }
        }
    }
    break;

    case "ExecutingAction":
    {
        var _action_performed = false;
        var _player_actor     = noone;
        if (ds_list_size(global.battle_party) > global.active_party_member_index) {
            _player_actor = global.battle_party[| global.active_party_member_index];
        }

        if (instance_exists(_player_actor) && variable_instance_exists(_player_actor, "data") && is_struct(_player_actor.data)) {
            var _pd = _player_actor.data;

            // Bind skip
            if (_pd.status == "bind" && irandom(99) < 50) {
                var popB = instance_create_layer(_player_actor.x, _player_actor.y - 64, "Instances", obj_popup_damage);
                if (popB != noone) { popB.damage_amount = "Bound!"; popB.text_color = c_gray; }
                show_debug_message("   ❌ " + string(_player_actor) + " is Bound! Turn skipped.");
                _action_performed = true;
            }
            // Blind miss
            else if (_pd.status == "blind" && irandom(99) < 50) {
                var popM = instance_create_layer(_player_actor.x, _player_actor.y - 64, "Instances", obj_popup_damage);
                if (popM != noone) { popM.damage_amount = "Miss!"; popM.text_color = c_white; }
                show_debug_message("   ❌ " + string(_player_actor) + " is Blind! Attack missed.");
                _action_performed = true;
            }
            // Attack
            else if (stored_action_data == "Attack") {
                if (selected_target_id != noone && instance_exists(selected_target_id)) {
                    var _ti = selected_target_id;
                    if (variable_instance_exists(_ti, "data") && is_struct(_ti.data)) {
                        var _td = _ti.data;
                        var pa  = _pd.atk;
                        var td  = _td.def;
                        var pl  = _pd.luk;
                        var cc  = 5 + floor(pl / 4);
                        var ic  = (irandom(99) < cc);
                        var cm  = 1.5;
                        var dmg = max(1, pa - td);
                        if (ic) dmg = floor(dmg * cm);
                        if (variable_struct_exists(_td, "is_defending") && _td.is_defending) dmg = floor(dmg / 2);

                        _td.hp = max(0, _td.hp - dmg);

                        if (object_exists(obj_popup_damage)) {
                            var pop = instance_create_layer(_ti.x, _ti.y - 64, "Instances", obj_popup_damage);
                            if (pop != noone) {
                                pop.damage_amount = string(dmg);
                                if (ic) {
                                    pop.damage_amount = "CRIT! " + pop.damage_amount;
                                    pop.text_color     = c_yellow;
                                }
                            }
                        }
                        _action_performed = true;
                    }
                }
            }
            // Item
            else if (is_struct(stored_action_data) && variable_struct_exists(stored_action_data, "usable_in_battle")) {
                var _item = stored_action_data;
                var _t    = selected_target_id;
                var _ok   = false;
                switch (_item.effect) {
                    case "heal_hp":
                        if (instance_exists(_t) && variable_instance_exists(_t,"data") && is_struct(_t.data)) {
                            var _d = _t.data;
                            if (variable_struct_exists(_d,"hp") && variable_struct_exists(_d,"maxhp")) {
                                var old = _d.hp;
                                _d.hp = min(_d.maxhp, _d.hp + _item.value);
                                var hld = _d.hp - old;
                                if (hld > 0) {
                                    if (object_exists(obj_popup_damage)) {
                                        var pop = instance_create_layer(_t.x, _t.y - 64, "Instances", obj_popup_damage);
                                        if (pop != noone) {
                                            pop.damage_amount = "+" + string(hld);
                                            pop.text_color    = c_lime;
                                        }
                                    }
                                }
                                _ok = true;
                            }
                        }
                        break;
                    case "damage_enemy":
                        if (instance_exists(_t) && variable_instance_exists(_t,"data") && is_struct(_t.data)) {
                            var _d = _t.data;
                            if (variable_struct_exists(_d,"hp")) {
                                _d.hp = max(0, _d.hp - _item.value);
                                if (object_exists(obj_popup_damage)) {
                                    var pop = instance_create_layer(_t.x, _t.y - 64, "Instances", obj_popup_damage);
                                    if (pop != noone) pop.damage_amount = string(_item.value);
                                }
                                _ok = true;
                            }
                        }
                        break;
                    case "cure_status":
                        if (instance_exists(_t) && variable_instance_exists(_t,"data") && is_struct(_t.data)) {
                            var _d = _t.data;
                            if (_d.status == _item.value) {
                                _d.status = "none";
                                if (object_exists(obj_popup_damage)) {
                                    var pop = instance_create_layer(_t.x, _t.y - 64, "Instances", obj_popup_damage);
                                    if (pop != noone) {
                                        pop.damage_amount = "Cured!";
                                        pop.text_color    = c_aqua;
                                    }
                                }
                            }
                            _ok = true;
                        }
                        break;
                    default:
                        _ok = true;
                        break;
                }
                _action_performed = _ok;
            }
            // Skill
            else if (is_struct(stored_action_data)) {
                _action_performed = scr_CastSkill(_player_actor, stored_action_data, selected_target_id);
            }
            // Defend
            else if (stored_action_data == "Defend") {
                _pd.is_defending = true;
                var popD = instance_create_layer(_player_actor.x, _player_actor.y - 64, "Instances", obj_popup_damage);
                if (popD != noone) {
                    popD.damage_amount = "DEFEND";
                    popD.text_color    = c_aqua;
                }
                _action_performed = true;
            }
        }

        // Clear for next
        stored_action_data = undefined;
        selected_target_id = noone;

        // Advance turns
        if (_action_performed) {
            global.active_party_member_index++;
            if (global.active_party_member_index >= ds_list_size(global.battle_party)) {
                global.active_party_member_index = 0;
                global.enemy_turn_index         = 0;
                global.battle_state             = "waiting_enemy";
                alarm[0]                        = 30;
            } else {
                global.battle_state = "player_input";
            }
        } else {
            global.battle_state = "player_input";
        }
    }
    break;

    case "waiting_after_player":
        alarm[0] = -1;
        global.battle_state = "check_win_loss";
        break;

    case "waiting_next_enemy":
    case "waiting_enemy":
        break;

    case "check_win_loss":
    {
        // Poison on party
        for (var i = 0; i < ds_list_size(global.battle_party); i++) {
            var p = global.battle_party[| i];
            if (instance_exists(p) && p.data.status == "poison") {
                var dmg = max(1, floor(p.data.maxhp * 0.05));
                p.data.hp = max(0, p.data.hp - dmg);
                if (object_exists(obj_popup_damage)) {
                    var pop = instance_create_layer(p.x, p.y - 64, "Instances", obj_popup_damage);
                    if (pop != noone) pop.damage_amount = string(dmg);
                }
            }
        }
        // Poison on enemies
        for (var i = 0; i < ds_list_size(global.battle_enemies); i++) {
            var e = global.battle_enemies[| i];
            if (instance_exists(e) && e.data.status == "poison") {
                var dmg = max(1, floor(e.data.maxhp * 0.05));
                e.data.hp = max(0, e.data.hp - dmg);
                if (object_exists(obj_popup_damage)) {
                    var pop = instance_create_layer(e.x, e.y - 64, "Instances", obj_popup_damage);
                    if (pop != noone) pop.damage_amount = string(dmg);
                }
            }
        }

        // Decrement statuses (party)
        for (var i = 0; i < ds_list_size(global.battle_party); i++) {
            var p = global.battle_party[| i];
            if (instance_exists(p) && variable_struct_exists(p.data, "status_turns")) {
                p.data.status_turns--;
                if (p.data.status_turns <= 0) {
                    p.data.status = "none";
                    show_debug_message("   ✨ Cleared status on party " + string(p));
                }
            }
        }
        // Decrement statuses (enemies)
        for (var i = 0; i < ds_list_size(global.battle_enemies); i++) {
            var e = global.battle_enemies[| i];
            if (instance_exists(e) && variable_struct_exists(e.data, "status_turns")) {
                e.data.status_turns--;
                if (e.data.status_turns <= 0) {
                    e.data.status = "none";
                    show_debug_message("   ✨ Cleared status on enemy " + string(e));
                }
            }
        }

        // Check kills and XP
        var xp = 0;
        for (var i = ds_list_size(global.battle_enemies)-1; i >= 0; i--) {
            var e = global.battle_enemies[| i];
            if (instance_exists(e) && e.data.hp <= 0) {
                if (variable_struct_exists(e.data,"xp")) xp += e.data.xp;
                instance_destroy(e);
                ds_list_delete(global.battle_enemies, i);
            }
        }
        if (xp > 0) total_xp_from_battle += xp;

        // Check win/loss
        var anyAliveP = false;
        for (var i = 0; i < ds_list_size(global.battle_party); i++) {
            if (global.battle_party[|i].data.hp > 0) anyAliveP = true;
        }
        var anyAliveE = ds_list_size(global.battle_enemies) > 0;

        if (!anyAliveE) {
            global.battle_state = "victory"; alarm[0] = 30;
        } else if (!anyAliveP) {
            global.battle_state = "defeat";  alarm[0] = 30;
        } else {
            if (global.enemy_turn_index >= ds_list_size(global.battle_enemies)) {
                global.active_party_member_index = 0;
                global.enemy_turn_index         = 0;
                global.battle_state             = "player_input";
                global.battle_target            = clamp(global.battle_target,0,ds_list_size(global.battle_enemies)-1);
            } else {
                global.battle_state = "waiting_enemy"; alarm[0] = 30;
            }
        }
    }
    break;

    case "enemy_turn":
    {
        var _complete = false;
        var _sz       = ds_list_size(global.battle_enemies);

        if (global.enemy_turn_index < _sz) {
            var e = global.battle_enemies[| global.enemy_turn_index];
            if (instance_exists(e) && e.data.hp > 0) {
                // Bind skip
                if (e.data.status == "bind" && irandom(99) < 50) {
                    var popB = instance_create_layer(e.x, e.y-64,"Instances",obj_popup_damage);
                    if (popB!=noone) { popB.damage_amount="Bound!"; popB.text_color=c_gray; }
                    _complete = true;
                }
                // Blind miss
                else if (e.data.status == "blind" && irandom(99) < 50) {
                    var popM = instance_create_layer(e.x,e.y-64,"Instances",obj_popup_damage);
                    if (popM!=noone) { popM.damage_amount="Miss!"; popM.text_color=c_white; }
                    _complete = true;
                }
                else {
                    // Attack random party member
                    var living = [];
                    for (var i=0; i<ds_list_size(global.battle_party); i++) {
                        var p = global.battle_party[|i];
                        if (p.data.hp>0) array_push(living,p);
                    }
                    if (array_length(living)>0) {
                        var tgt = living[irandom(array_length(living)-1)];
                        var dmg = max(1, e.data.atk - tgt.data.def);
                        if (tgt.data.is_defending) dmg = floor(dmg/2);
                        tgt.data.hp = max(0,tgt.data.hp - dmg);
                        if (object_exists(obj_popup_damage)) {
                            var pop = instance_create_layer(tgt.x,tgt.y-64,"Instances",obj_popup_damage);
                            if (pop!=noone) pop.damage_amount=string(dmg);
                        }
                        tgt.data.is_defending = false;
                    }
                    _complete = true;
                }
            } else {
                _complete = true;
            }

            if (_complete) {
                global.enemy_turn_index++;
                if (global.enemy_turn_index >= _sz) {
                    global.battle_state = "check_win_loss";
                } else {
                    global.battle_state = "waiting_next_enemy";
                    alarm[0]            = 30;
                }
            }
        } else {
            global.battle_state = "check_win_loss";
        }
    }
    break;

    default:
        show_debug_message("WARNING: obj_battle_manager in unknown state: " + string(global.battle_state));
    break;
}
