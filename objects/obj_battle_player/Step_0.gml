/// obj_battle_player :: Step Event
/// Handles sprite assignment (once) and player input ONLY for the active party member during menu states.

// --- HP Debug Log ---
if (variable_instance_exists(id, "data") && is_struct(data)) {
    show_debug_message("Player Step " + string(id) + ": Current HP = " + string(data.hp));
} else {
    show_debug_message("Player Step " + string(id) + ": NO data YET");
}

// --- One-Time Sprite Assignment ---
if (!sprite_assigned && variable_instance_exists(id, "data") && is_struct(data)) {
    if (variable_struct_exists(data, "character_key")) {
        var _char_key = data.character_key;
        var base_data = scr_FetchCharacterInfo(_char_key);
        if (is_struct(base_data) && variable_struct_exists(base_data, "battle_sprite")) {
            var spr = base_data.battle_sprite;
            if (sprite_exists(spr)) {
                sprite_index = spr;
                image_index  = 0;
                image_speed  = 0.2;
            }
        }
    }
    sprite_assigned = true;
}

// --- Active Turn & State Checks ---
if (!variable_global_exists("active_party_member_index")
 || !variable_global_exists("battle_state")
 || !variable_instance_exists(id, "data")
 || !is_struct(data)
 || !variable_struct_exists(data, "party_slot_index")) {
    exit;
}

var mySlot   = data.party_slot_index;
var turnSlot = global.active_party_member_index;
var st       = global.battle_state;

if (mySlot != turnSlot) exit;
if (st != "player_input" && st != "skill_select" && st != "item_select") exit;

show_debug_message(">>> Player " + string(id) + " (slot " + string(mySlot) + 
                   ") INPUT in state: " + st);

// --- Shortcut & Init ---
var d = data;
if (!variable_struct_exists(d, "item_index"))  d.item_index  = 0;
if (!variable_struct_exists(d, "skill_index")) d.skill_index = 0;

// --- Read Inputs ---
var P = 0;
var A = keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter) || gamepad_button_check_pressed(P, gp_face1);
var B = keyboard_check_pressed(vk_escape) || gamepad_button_check_pressed(P, gp_face2);
var X = keyboard_check_pressed(ord("X"))    || gamepad_button_check_pressed(P, gp_face3);
var Y = keyboard_check_pressed(ord("Y"))    || gamepad_button_check_pressed(P, gp_face4);
var U = keyboard_check_pressed(vk_up)       || gamepad_button_check_pressed(P, gp_padu);
var D = keyboard_check_pressed(vk_down)     || gamepad_button_check_pressed(P, gp_padd);

// --- State Machine ---
switch (st) {
    // PLAYER INPUT
    case "player_input":
        var hasEnemies = ds_exists(global.battle_enemies, ds_type_list) 
                       && ds_list_size(global.battle_enemies) > 0;
        if (A && hasEnemies) {
            obj_battle_manager.stored_action_data = "Attack";
            global.battle_target = 0;
            global.battle_state  = "TargetSelect";
        }
        else if (B) {
            obj_battle_manager.stored_action_data   = "Defend";
            obj_battle_manager.selected_target_id   = noone;
            global.battle_state = "ExecutingAction";
        }
        else if (X) {
            var skills = (variable_struct_exists(d, "skills") && is_array(d.skills)) ? d.skills : [];
            if (array_length(skills) > 0) {
                d.skill_index      = 0;
                global.battle_state = "skill_select";
            }
        }
        else if (Y) {
            // build global usable items list
            global.battle_usable_items = [];
            var inv = (variable_global_exists("party_inventory") && is_array(global.party_inventory))
                    ? global.party_inventory : [];
            for (var i = 0; i < array_length(inv); i++) {
                var e = inv[i];
                if (!is_struct(e) 
                 || !variable_struct_exists(e, "item_key") 
                 || !variable_struct_exists(e, "quantity") 
                 || e.quantity <= 0) continue;
                var key = e.item_key;
                var it  = scr_GetItemData(key);
                if (is_struct(it) 
                 && variable_struct_exists(it, "usable_in_battle") 
                 && it.usable_in_battle) {
                    array_push(global.battle_usable_items, {
                        item_key: key,
                        quantity: e.quantity,
                        name:     it.name ?? "???"
                    });
                }
            }
            if (array_length(global.battle_usable_items) > 0) {
                d.item_index       = 0;
                global.battle_state = "item_select";
            }
        }
        break;

    // SKILL SELECT
    case "skill_select":
        var skills = (variable_struct_exists(d, "skills") && is_array(d.skills)) ? d.skills : [];
        var cnt    = array_length(skills);
        if (cnt > 0) {
            if (U) d.skill_index = (d.skill_index - 1 + cnt) mod cnt;
            if (D) d.skill_index = (d.skill_index + 1) mod cnt;
            if (A) {
                var s = skills[d.skill_index];
                if (is_struct(s) && d.mp >= (s.cost ?? 0)) {
                    obj_battle_manager.stored_action_data = s;
                    if (s.requires_target ?? true) {
                        global.battle_target = 0;
                        global.battle_state  = "TargetSelect";
                    } else {
                        obj_battle_manager.selected_target_id = id;
                        global.battle_state  = "ExecutingAction";
                    }
                }
            }
        }
        if (B) global.battle_state = "player_input";
        break;

    // ITEM SELECT (fixed requires_target check)
    case "item_select":
        var items = global.battle_usable_items;
        var c     = array_length(items);
        if (c > 0) {
            if (U) d.item_index = (d.item_index - 1 + c) mod c;
            if (D) d.item_index = (d.item_index + 1) mod c;
            if (A) {
                var info = items[d.item_index];
                var it   = scr_GetItemData(info.item_key);
                if (is_struct(it)) {
                    obj_battle_manager.stored_action_data = it;
                    // use variable_struct_exists instead of direct field
                    var need_tgt = variable_struct_exists(it, "requires_target") 
                                 ? it.requires_target 
                                 : true;
                    if (need_tgt) {
                        global.battle_target = 0;
                        global.battle_state  = "TargetSelect";
                    } else {
                        obj_battle_manager.selected_target_id = id;
                        global.battle_state  = "ExecutingAction";
                    }
                }
            }
        }
        if (B) {
            global.battle_usable_items = [];
            global.battle_state        = "player_input";
        }
        break;
}
// --- End Switch ---
