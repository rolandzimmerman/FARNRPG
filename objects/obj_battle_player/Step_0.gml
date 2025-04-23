/// obj_battle_player :: Step Event
// Handles sprite assignment (once) and player input ONLY for the active party member during menu states.

// --- One-Time Sprite Assignment ---
if (!sprite_assigned && variable_instance_exists(id, "data") && is_struct(data)) {
    if (variable_struct_exists(data, "character_key")) {
        var _char_key = data.character_key;
        var base_data = scr_FetchCharacterInfo(_char_key);
        if (is_struct(base_data) && variable_struct_exists(base_data, "battle_sprite")) {
            var spr = base_data.battle_sprite;
            if (sprite_exists(spr)) {
                sprite_index = spr; image_index = 0; image_speed = 0.2;
                sprite_assigned = true;
            }
        }
    }
}
// --- End One-Time Sprite Assignment ---


// --- Active Turn Check ---
if (!variable_global_exists("active_party_member_index") || !variable_instance_exists(id,"data") || !is_struct(data) || !variable_struct_exists(data, "party_slot_index")) { exit; }
if (data.party_slot_index != global.active_party_member_index) { exit; }
// --- End Turn Check ---


// Exit check for battle state - This object ONLY handles menu input now
if (global.battle_state != "player_input" &&
    global.battle_state != "skill_select" &&
    global.battle_state != "item_select")
{
    exit;
}

var d = data; // Use shorthand

// Initialize indices if needed
if (!variable_struct_exists(d, "item_index")) d.item_index = 0;
if (!variable_struct_exists(d, "skill_index")) d.skill_index = 0;


// Grab buttons
var P = 0; var A = gamepad_button_check_pressed(P, gp_face1) || keyboard_check_pressed(vk_space); var B = gamepad_button_check_pressed(P, gp_face2) || keyboard_check_pressed(vk_escape); var X = gamepad_button_check_pressed(P, gp_face3) || keyboard_check_pressed(ord("X")); var Y = gamepad_button_check_pressed(P, gp_face4) || keyboard_check_pressed(ord("Y")); var U = gamepad_button_check_pressed(P, gp_padu) || keyboard_check_pressed(vk_up); var D = gamepad_button_check_pressed(P, gp_padd) || keyboard_check_pressed(vk_down);


// Get skill info & clamp index
var skills = (variable_struct_exists(d, "skills") && is_array(d.skills)) ? d.skills : [];
var tot_skills = array_length(skills);
if (tot_skills > 0) d.skill_index = clamp(d.skill_index, 0, tot_skills - 1); else d.skill_index = 0;

// Get inventory info & clamp index
var current_inventory = []; if (instance_exists(obj_player) && variable_instance_exists(obj_player, "inventory") && is_array(obj_player.inventory)) { current_inventory = obj_player.inventory; }
var tot_items = array_length(current_inventory);
if (tot_items > 0) d.item_index = clamp(d.item_index, 0, tot_items - 1); else d.item_index = 0;


// === State-Specific Input Handling (for Active Player in Menus) ===
if (global.battle_state == "skill_select") {
    // --- Skill Menu Input ---
    if (tot_skills > 0) { if (U) d.skill_index=(d.skill_index-1+tot_skills)%tot_skills; if (D) d.skill_index=(d.skill_index+1)%tot_skills; }
    if (A) { if (tot_skills > 0) { var _s = skills[d.skill_index]; if (is_struct(_s) && variable_struct_exists(_s,"cost")) { if (d.mp >= _s.cost) { var _nt = variable_struct_exists(_s, "requires_target") ? _s.requires_target : true; if (_nt) { if (ds_list_size(global.battle_enemies) > 0) { obj_battle_manager.stored_action_data = _s; global.battle_target = 0; global.battle_state = "TargetSelect"; show_debug_message("Player Input: Skill selected -> TargetSelect"); } } else { obj_battle_manager.stored_action_data = _s; obj_battle_manager.selected_target_id = noone; global.battle_state = "ExecutingAction"; show_debug_message("Player Input: Skill selected -> ExecutingAction"); } } else { /* Not enough MP */ } } } }
    else if (B) { global.battle_state = "player_input"; show_debug_message("Player Input: Cancelled Skill Menu -> player_input"); }
}
else if (global.battle_state == "item_select") {
    // --- Item Menu Input ---
     if (tot_items > 0) { if (U) d.item_index = (d.item_index - 1 + tot_items) mod tot_items; if (D) d.item_index = (d.item_index + 1) mod tot_items; }
     if (A) { if (tot_items > 0) { var _inv_entry = current_inventory[d.item_index]; var _item_data = scr_GetItemData(_inv_entry.item_key); if (is_struct(_item_data) && _item_data.usable_in_battle) { obj_battle_manager.stored_action_data = _item_data; var _target_type = _item_data.target; var _next_state = global.battle_state; if (_target_type == "enemy") { if (ds_list_size(global.battle_enemies) > 0) { global.battle_target = 0; _next_state = "TargetSelect"; show_debug_message("Player Input: Item selected -> TargetSelect"); } else { obj_battle_manager.stored_action_data = undefined; _next_state = "item_select"; /* No target */ } } else { obj_battle_manager.selected_target_id = id; _next_state = "ExecutingAction"; show_debug_message("Player Input: Item selected -> ExecutingAction"); } if (_next_state != "item_select") { _inv_entry.quantity -= 1; if (_inv_entry.quantity <= 0) { array_delete(obj_player.inventory, d.item_index, 1); d.item_index = max(0, d.item_index - 1); } global.battle_state = _next_state; } } } }
     else if (B) { global.battle_state = "player_input"; show_debug_message("Player Input: Cancelled Item Menu -> player_input"); }
}
else if (global.battle_state == "player_input") {
    // --- Main Menu Input ---
    if (X) { global.battle_state = "skill_select"; d.skill_index = 0; show_debug_message("Player Input: X pressed -> skill_select"); }
    else if (Y) { if (tot_items > 0) { global.battle_state = "item_select"; d.item_index = 0; show_debug_message("Player Input: Y pressed -> item_select"); } else { show_debug_message("Player Input: Y pressed -> Inventory Empty"); } }
    else if (A) { if (ds_list_size(global.battle_enemies) > 0) { obj_battle_manager.stored_action_data = "Attack"; global.battle_target = 0; global.battle_state = "TargetSelect"; show_debug_message("Player Input: A pressed -> TargetSelect (Attack)"); } }
    else if (B) { obj_battle_manager.stored_action_data = "Defend"; obj_battle_manager.selected_target_id = noone; global.battle_state = "ExecutingAction"; show_debug_message("Player Input: B pressed -> ExecutingAction (Defend)"); }
}