/// obj_battle_player :: Step Event
// Handles player input during battle turns using the 'data' struct.

// Exit check
if (global.battle_state != "player_input" && global.battle_state != "skill_select") {
    exit;
}

// Ensure data struct exists and is valid
if (!variable_instance_exists(id,"data") || !is_struct(data)) {
    show_debug_message("Player Step ERROR: Missing or invalid data struct!");
    exit;
}
var d = data; // Use shorthand for convenience

// Grab buttons
var P = 0;
var A = gamepad_button_check_pressed(P, gp_face1) || keyboard_check_pressed(vk_space); // Confirm
var B = gamepad_button_check_pressed(P, gp_face2) || keyboard_check_pressed(vk_escape); // Cancel
var X = gamepad_button_check_pressed(P, gp_face3) || keyboard_check_pressed(ord("X"));    // Skill Menu Open
var Y = gamepad_button_check_pressed(P, gp_face4) || keyboard_check_pressed(ord("Y"));    // Flee
var U = gamepad_button_check_pressed(P, gp_padu)   || keyboard_check_pressed(vk_up);    // Up
var D = gamepad_button_check_pressed(P, gp_padd)   || keyboard_check_pressed(vk_down);  // Down

// Get skill info from data struct
var skills = (variable_struct_exists(d, "skills") && is_array(d.skills)) ? d.skills : []; // Use d.skills
var tot_skills = array_length(skills);
if (!variable_struct_exists(d, "skill_index")) d.skill_index = 0; // Use d.skill_index
if (tot_skills > 0) d.skill_index = clamp(d.skill_index, 0, tot_skills - 1); else d.skill_index = 0;


// Skill Menu Input Handling
if (global.battle_state == "skill_select") {
    if (tot_skills > 0) { // Navigate skills
        if (U) { d.skill_index = (d.skill_index - 1 + tot_skills) mod tot_skills; } // Use d.skill_index
        if (D) { d.skill_index = (d.skill_index + 1) mod tot_skills; } // Use d.skill_index
    }

    if (A) { // --- Select Skill ---
        if (tot_skills > 0) {
            var _selected_skill_data = skills[d.skill_index]; // Use d.skill_index
            if (is_struct(_selected_skill_data) && variable_struct_exists(_selected_skill_data,"cost") && variable_struct_exists(_selected_skill_data,"name")) {
                 if (d.mp >= _selected_skill_data.cost) { // Use d.mp
                     var _skill_needs_target = variable_struct_exists(_selected_skill_data, "requires_target") ? _selected_skill_data.requires_target : true;
                     if (_skill_needs_target) {
                          if (ds_list_size(global.battle_enemies) > 0) {
                               obj_battle_manager.stored_action_data = _selected_skill_data; global.battle_target = 0; global.battle_state = "TargetSelect";
                          } else { /* No targets */ }
                     } else { // No target needed
                          obj_battle_manager.stored_action_data = _selected_skill_data; obj_battle_manager.selected_target_id = noone; global.battle_state = "ExecutingAction";
                     }
                 } else { /* Not enough MP */ }
            } else { /* Invalid skill data */ }
        } else { /* No skills */ }
    } else if (B) { // Cancel Skill Menu
        global.battle_state = "player_input";
    }
} // End "skill_select" state


// Main Input Handling
else if (global.battle_state == "player_input") {
    // --- Target switching (L/R) removed ---

    // --- Open Skill Menu (X button) ---
    if (X) {
        global.battle_state = "skill_select";
        d.skill_index = 0; // Use d.skill_index
    }
    // --- Attack Action (A button) ---
    else if (A) {
        if (ds_list_size(global.battle_enemies) > 0) { obj_battle_manager.stored_action_data = "Attack"; global.battle_target = 0; global.battle_state = "TargetSelect"; }
        else { /* No targets */ }
    }
    // --- Defend Action (B button) ---
    else if (B) {
        // Tell manager to execute Defend
        obj_battle_manager.stored_action_data = "Defend"; obj_battle_manager.selected_target_id = noone; global.battle_state = "ExecutingAction";
        // The 'is_defending = true' flag will be set on this instance's 'data' struct by the manager during execution
    }
    // --- Flee Action (Y button) ---
    else if (Y) {
        if (object_exists(obj_popup_damage)) { var pop = instance_create_layer(x, y - 64, "Instances", obj_popup_damage); if (pop != noone) { pop.damage_amount = "FLEE!"; pop.text_color = c_yellow;} }
        global.battle_state = "return_to_field"; if (instance_exists(obj_battle_manager)) { with(obj_battle_manager) alarm[0] = 20; }
    }
} // End "player_input" state