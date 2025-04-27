/// obj_battle_player :: Step Event
/// Handles sprite assignment (once) and player input ONLY for the active party member.

//
// 1) Debug HP Log
//
if (variable_instance_exists(id, "data") && is_struct(data)) {
    show_debug_message("Player Step " + string(id) + ": Current HP = " + string(data.hp));
} else {
    show_debug_message("Player Step " + string(id) + ": NO data YET");
}

//
// 2) One‐Time Sprite Assignment
//
if (!variable_instance_exists(id,"sprite_assigned") && is_struct(data)) {
    sprite_assigned = true;
    if (variable_struct_exists(data, "character_key")) {
        var key = data.character_key;
        var base = scr_FetchCharacterInfo(key);
        if (is_struct(base) && variable_struct_exists(base, "battle_sprite")) {
            var spr = base.battle_sprite;
            if (sprite_exists(spr)) {
                sprite_index = spr;
                image_index  = 0;
                image_speed  = 0.2;
            }
        }
    }
}

//
// 3) Only the active slot handles input
//
if (!variable_global_exists("active_party_member_index") ||
    !variable_global_exists("battle_state") ||
    !is_struct(data) ||
    !variable_struct_exists(data, "party_slot_index")) {
    exit;
}

var mySlot = data.party_slot_index;
var active = global.active_party_member_index;
var state  = global.battle_state;
if (mySlot != active) exit;

//
// 4) Only during menu states
//
if (state != "player_input" &&
    state != "skill_select" &&
    state != "item_select") {
    exit;
}

//
// 5) Read input
//
var P = 0;
var A = keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter) || gamepad_button_check_pressed(P, gp_face1);
var B = keyboard_check_pressed(vk_escape)                 || gamepad_button_check_pressed(P, gp_face2);
var X = keyboard_check_pressed(ord("X"))                 || gamepad_button_check_pressed(P, gp_face3);
var Y = keyboard_check_pressed(ord("Y"))                 || gamepad_button_check_pressed(P, gp_face4);
var U = keyboard_check_pressed(vk_up)                    || gamepad_button_check_pressed(P, gp_padu);
var D = keyboard_check_pressed(vk_down)                  || gamepad_button_check_pressed(P, gp_padd);

//
// 6) Shorthand
//
var d = data;
if (!variable_struct_exists(d,"skill_index")) d.skill_index = 0;
if (!variable_struct_exists(d,"item_index"))  d.item_index  = 0;
if (!variable_instance_exists(id, "battle_usable_items")) battle_usable_items = [];

//
// 7) Handle states
//
switch (state) {
    case "player_input":
        var enemies = ds_exists(global.battle_enemies, ds_type_list) && ds_list_size(global.battle_enemies)>0;
        if (A && enemies) {
            obj_battle_manager.stored_action_data = "Attack";
            global.battle_target = 0;
            global.battle_state  = "TargetSelect";
        }
        else if (B) {
            obj_battle_manager.stored_action_data = "Defend";
            obj_battle_manager.selected_target_id = noone;
            global.battle_state = "ExecutingAction";
        }
        else if (X) {
            var skills = is_array(d.skills) ? d.skills : [];
            if (array_length(skills)>0) {
                d.skill_index     = 0;
                global.battle_state = "skill_select";
            }
        }
        else if (Y) {
            battle_usable_items = [];
            var inv = is_array(global.party_inventory) ? global.party_inventory : [];
            for (var i=0; i<array_length(inv); i++) {
                var e = inv[i];
                if (!is_struct(e) || e.quantity<=0) continue;
                var it = scr_GetItemData(e.item_key);
                if (is_struct(it) && it.usable_in_battle) {
                    array_push(battle_usable_items, {
                        item_key: e.item_key,
                        quantity: e.quantity,
                        name:     it.name
                    });
                }
            }
            if (array_length(battle_usable_items)>0) {
                d.item_index       = 0;
                global.battle_state = "item_select";
            }
        }
        break;

    case "skill_select":
        var sks = is_array(d.skills) ? d.skills : [];
        var cnt = array_length(sks);
        if (cnt>0) {
            if (U) d.skill_index = (d.skill_index - 1 + cnt) mod cnt;
            if (D) d.skill_index = (d.skill_index + 1) mod cnt;
            if (A) {
                var s = sks[d.skill_index]; // <-- correct array indexing
                if (is_struct(s)) {
                    var cost = s.cost ?? 0;
                    if (d.mp>=cost) {
                        obj_battle_manager.stored_action_data = s;
                        var needs = s.requires_target ?? true;
                        if (needs) {
                            global.battle_target = 0;
                            global.battle_state  = "TargetSelect";
                        } else {
                            obj_battle_manager.selected_target_id = id;
                            global.battle_state                   = "ExecutingAction";
                        }
                    }
                }
            }
        }
        if (B) global.battle_state = "player_input";
        break;

    case "item_select":
        var cnt = array_length(battle_usable_items);
        if (cnt>0) {
            if (U) d.item_index = (d.item_index - 1 + cnt) mod cnt;
            if (D) d.item_index = (d.item_index + 1) mod cnt;
            if (A) {
                var info = battle_usable_items[d.item_index];
                var it   = scr_GetItemData(info.item_key);
                if (is_struct(it)) {
                    obj_battle_manager.stored_action_data = it;
                    var tgt = it.target ?? "enemy";
                    if (tgt=="enemy") {
                        global.battle_target = 0;
                        global.battle_state  = "TargetSelect";
                    } else {
                        obj_battle_manager.selected_target_id = id;
                        global.battle_state                   = "ExecutingAction";
                    }
                }
            }
        }
        if (B) {
            global.battle_state    = "player_input";
            battle_usable_items = [];
        }
        break;
}
