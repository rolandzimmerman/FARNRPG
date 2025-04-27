/// obj_battle_player :: Step Event
// Handles sprite assignment (once) and player input ONLY for the active party member during menu states.
// Uses direct input checks.

// HP DEBUG LOG uses 'data'
if (variable_instance_exists(id, "data") && is_struct(data)) {
    show_debug_message("Player Step " + string(id) + ": Current HP = " + string(data.hp ?? "ERR"));
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
            if (sprite_exists(spr)) { sprite_index = spr; image_index = 0; image_speed = 0.2; sprite_assigned = true; }
        }
    }
    if (!sprite_assigned) { sprite_assigned = true; } // Mark as checked even if failed
}

// --- Active Turn Check ---
if (!variable_global_exists("active_party_member_index") || !variable_global_exists("battle_state") ||
    !variable_instance_exists(id,"data") || !is_struct(data) || !variable_struct_exists(data, "party_slot_index"))
{ exit; }
var _my_slot_index = data.party_slot_index; var _active_turn_index = global.active_party_member_index; var _current_battle_state = global.battle_state;
if (_my_slot_index != _active_turn_index) { exit; }

// --- Exit if not in a relevant menu state ---
if (_current_battle_state != "player_input" && _current_battle_state != "skill_select" && _current_battle_state != "item_select") { exit; }

show_debug_message(">>> Player Instance " + string(id) + " (Slot " + string(_my_slot_index) + ") PROCESSING INPUT in state: " + _current_battle_state);

// --- Local shorthand & index init ---
var d = data; // Use shorthand for 'data'
if (!variable_struct_exists(d, "item_index")) d.item_index = 0; if (!variable_struct_exists(d, "skill_index")) d.skill_index = 0;
if (!variable_instance_exists(id,"battle_usable_items")) battle_usable_items = [];

// --- Input Reading (Using direct checks like manager) ---
var P = 0;
var A_pressed = gamepad_button_check_pressed(P, gp_face1) || keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_enter); // Confirm
var B_pressed = gamepad_button_check_pressed(P, gp_face2) || keyboard_check_pressed(vk_escape); // Cancel
var X_pressed = gamepad_button_check_pressed(P, gp_face3) || keyboard_check_pressed(ord("X")); // Skill Menu (Example)
var Y_pressed = gamepad_button_check_pressed(P, gp_face4) || keyboard_check_pressed(ord("Y")); // Item Menu (Example)
var U_pressed = gamepad_button_check_pressed(P, gp_padu) || keyboard_check_pressed(vk_up);    // Up
var D_pressed = gamepad_button_check_pressed(P, gp_padd) || keyboard_check_pressed(vk_down);  // Down

// --- State-Specific Input Handling ---
switch (_current_battle_state) {
    case "player_input":
        var enemies_exist = (ds_exists(global.battle_enemies, ds_type_list) && ds_list_size(global.battle_enemies) > 0); // Safe check
        if (A_pressed) { // Attack
            if (enemies_exist) { obj_battle_manager.stored_action_data = "Attack"; global.battle_target = 0; global.battle_state = "TargetSelect"; }
            else { show_debug_message("Cannot Attack: No enemies!"); /* Deny Sound? */ }
        }
        else if (B_pressed) { // Defend
             obj_battle_manager.stored_action_data = "Defend"; obj_battle_manager.selected_target_id = noone; global.battle_state = "ExecutingAction";
        }
        else if (X_pressed) { // Skill
             var skills = (variable_struct_exists(d, "skills") && is_array(d.skills)) ? d.skills : [];
             if (array_length(skills) > 0) { d.skill_index = 0; global.battle_state = "skill_select"; }
             else { show_debug_message("Cannot use Skill: No skills learned!"); /* Deny Sound? */ }
        }
        else if (Y_pressed) { // Item
            battle_usable_items = []; var _raw_inv = (variable_global_exists("party_inventory") && is_array(global.party_inventory)) ? global.party_inventory : [];
            for (var i = 0; i < array_length(_raw_inv); i++) { var entry = _raw_inv[i]; if (!is_struct(entry) || !variable_struct_exists(entry, "item_key") || !variable_struct_exists(entry, "quantity") || entry.quantity <= 0) continue; var item_key = entry.item_key; var item_data = scr_GetItemData(item_key); if (is_struct(item_data) && variable_struct_exists(item_data, "usable_in_battle") && item_data.usable_in_battle) { array_push(battle_usable_items, { item_key: item_key, quantity: entry.quantity, name: item_data.name ?? "???" }); } }
            if (array_length(battle_usable_items) > 0) { d.item_index = 0; global.battle_state = "item_select"; }
            else { show_debug_message("Cannot use Item: No usable items in inventory!"); /* Deny Sound? */ }
        }
        break;

    case "skill_select":
        var skills = (variable_struct_exists(d, "skills") && is_array(d.skills)) ? d.skills : [];
        var tot_skills = array_length(skills);
        if (tot_skills > 0) {
            // Navigation
            if (U_pressed) { d.skill_index = (d.skill_index - 1 + tot_skills) mod tot_skills; /* Play Sound */ }
            if (D_pressed) { d.skill_index = (d.skill_index + 1) mod tot_skills; /* Play Sound */ }
            // Confirmation
            if (A_pressed) {
                 var _s = skills[d.skill_index];
                 if (is_struct(_s)) {
                     var _cost = variable_struct_exists(_s, "cost") ? _s.cost : 0;
                     if (d.mp >= _cost) { // Check MP
                          obj_battle_manager.stored_action_data = _s; // Store skill struct
                          var _needs_target = variable_struct_exists(_s, "requires_target") ? _s.requires_target : true;
                          if (_needs_target) {
                               if (ds_exists(global.battle_enemies, ds_type_list) && ds_list_size(global.battle_enemies) > 0) { global.battle_target = 0; global.battle_state = "TargetSelect"; /* Select Sound */ }
                               else { obj_battle_manager.stored_action_data = undefined; /* Error Sound */ } // No enemies to target
                          } else {
                               obj_battle_manager.selected_target_id = id; global.battle_state = "ExecutingAction"; /* Select Sound */ // Target self
                          }
                     } else { show_debug_message("Not enough MP for " + string(_s.name)); /* Error Sound */ }
                 }
            }
        } else { if (A_pressed) { /* Error Sound - No skills */ } }
        // Cancel
        if (B_pressed) { global.battle_state = "player_input"; /* Cancel Sound */ }
        break;

    case "item_select":
        var _usable_item_count = array_length(battle_usable_items);
        if (_usable_item_count > 0) {
            // Navigation
            if (U_pressed) { d.item_index = (d.item_index - 1 + _usable_item_count) mod _usable_item_count; /* Sound */ }
            if (D_pressed) { d.item_index = (d.item_index + 1) mod _usable_item_count; /* Sound */ }
            // Confirmation
            if (A_pressed) {
                 var _selected_usable_item_info = battle_usable_items[d.item_index]; var _item_key = _selected_usable_item_info.item_key; var _item_data = scr_GetItemData(_item_key);
                 if (is_struct(_item_data)) {
                     obj_battle_manager.stored_action_data = _item_data; // Store full item data
                     var _target_type = variable_struct_exists(_item_data,"target") ? _item_data.target : "enemy";
                     var _next_state = "TargetSelect";
                     if (_target_type == "enemy") { if (ds_exists(global.battle_enemies, ds_type_list) && ds_list_size(global.battle_enemies) > 0) { global.battle_target = 0; _next_state = "TargetSelect"; /* Select Sound */ } else { obj_battle_manager.stored_action_data = undefined; _next_state = "item_select"; /* Error Sound */ } }
                     else if (_target_type == "ally") { obj_battle_manager.selected_target_id = id; _next_state = "ExecutingAction"; /* Select Sound */ } // Target self for now
                     else { obj_battle_manager.selected_target_id = id; _next_state = "ExecutingAction"; /* Select Sound */ } // Assume self if not enemy/ally
                     if (_next_state != "item_select") { global.battle_state = _next_state; } // Change state if valid
                 }
             }
        } else { if (A_pressed) { /* Error Sound - No usable items */ } }
        // Cancel
        if (B_pressed) { global.battle_state = "player_input"; battle_usable_items = []; /* Cancel Sound */ }
        break;

} // End Switch