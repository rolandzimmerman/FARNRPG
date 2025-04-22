/// obj_battle_player :: Step Event
// Handles player input during battle turns, including item selection.

// Exit check - Added item_select to valid states
if (global.battle_state != "player_input" &&
    global.battle_state != "skill_select" &&
    global.battle_state != "item_select")
{
    exit;
}

// Ensure data struct exists and is valid
if (!variable_instance_exists(id,"data") || !is_struct(data)) {
    show_debug_message("Player Step ERROR: Missing or invalid data struct!");
    exit;
}
var d = data; // Use shorthand for battle player's temporary data

// Initialize item_index if it doesn't exist in the battle data
if (!variable_struct_exists(d, "item_index")) {
    d.item_index = 0;
}
// Initialize skill_index if it doesn't exist
if (!variable_struct_exists(d, "skill_index")) {
    d.skill_index = 0;
}


// Grab buttons
var P = 0; // Assuming player 0
var A = gamepad_button_check_pressed(P, gp_face1) || keyboard_check_pressed(vk_space); // Confirm
var B = gamepad_button_check_pressed(P, gp_face2) || keyboard_check_pressed(vk_escape); // Cancel
var X = gamepad_button_check_pressed(P, gp_face3) || keyboard_check_pressed(ord("X"));    // Skill Menu Open
var Y = gamepad_button_check_pressed(P, gp_face4) || keyboard_check_pressed(ord("Y"));    // Item Menu Open
var U = gamepad_button_check_pressed(P, gp_padu)   || keyboard_check_pressed(vk_up);    // Up
var D = gamepad_button_check_pressed(P, gp_padd)   || keyboard_check_pressed(vk_down);  // Down


// Get skill info from this battle instance's data struct
var skills = (variable_struct_exists(d, "skills") && is_array(d.skills)) ? d.skills : [];
var tot_skills = array_length(skills);
// Clamp skill index
if (tot_skills > 0) d.skill_index = clamp(d.skill_index, 0, tot_skills - 1); else d.skill_index = 0;


// Get inventory info from the PERSISTENT player object
var current_inventory = []; // Default empty
if (instance_exists(obj_player) && variable_instance_exists(obj_player, "inventory") && is_array(obj_player.inventory)) {
    current_inventory = obj_player.inventory;
}
var tot_items = array_length(current_inventory);
// Clamp item index based on current inventory size
if (tot_items > 0) d.item_index = clamp(d.item_index, 0, tot_items - 1); else d.item_index = 0;


// === State-Specific Input Handling ===

// Skill Menu Input Handling
if (global.battle_state == "skill_select") {
    if (tot_skills > 0) { // Navigate skills
        if (U) { d.skill_index = (d.skill_index - 1 + tot_skills) mod tot_skills; }
        if (D) { d.skill_index = (d.skill_index + 1) mod tot_skills; }
    }

    if (A) { // --- Select Skill ---
        if (tot_skills > 0) {
            var _selected_skill_data = skills[d.skill_index];
            if (is_struct(_selected_skill_data) && variable_struct_exists(_selected_skill_data,"cost")) {
                 if (d.mp >= _selected_skill_data.cost) { // Use battle instance MP
                     var _skill_needs_target = variable_struct_exists(_selected_skill_data, "requires_target") ? _selected_skill_data.requires_target : true;
                     if (_skill_needs_target) {
                          if (ds_list_size(global.battle_enemies) > 0) {
                               obj_battle_manager.stored_action_data = _selected_skill_data; global.battle_target = 0; global.battle_state = "TargetSelect";
                          } else { /* No targets */ show_debug_message("Skill requires target, but no enemies exist!"); }
                     } else { // No target needed
                          obj_battle_manager.stored_action_data = _selected_skill_data; obj_battle_manager.selected_target_id = noone; global.battle_state = "ExecutingAction";
                     }
                 } else { show_debug_message("Not enough MP for " + _selected_skill_data.name + "!"); }
            } else { show_debug_message("Invalid skill data selected."); }
        } else { show_debug_message("No skills available."); }
    } else if (B) { // Cancel Skill Menu
        global.battle_state = "player_input";
    }
}
// Item Menu Input Handling
else if (global.battle_state == "item_select") {
     if (tot_items > 0) { // Navigate items
         if (U) { d.item_index = (d.item_index - 1 + tot_items) mod tot_items; }
         if (D) { d.item_index = (d.item_index + 1) mod tot_items; }
     }

     if (A) { // --- Select Item ---
         if (tot_items > 0) {
             var _selected_inv_entry = current_inventory[d.item_index]; // Get {item_key, quantity} struct
             var _item_data = scr_GetItemData(_selected_inv_entry.item_key); // Get item definition from database

             if (is_struct(_item_data) && _item_data.usable_in_battle) {
                 show_debug_message("Selected Item: " + _item_data.name);

                 // Store the *ITEM DEFINITION STRUCT* for the manager
                 obj_battle_manager.stored_action_data = _item_data;

                 // Determine target based on item definition
                 var _target_type = _item_data.target; // e.g., "enemy", "ally"

                 // --- Set next state based on target type ---
                 var _next_state = global.battle_state; // Default to no change
                 if (_target_type == "enemy") {
                     if (ds_list_size(global.battle_enemies) > 0) {
                         global.battle_target = 0; // Reset target cursor
                         _next_state = "TargetSelect";
                     } else {
                         show_debug_message("Cannot use item: No enemies!");
                         obj_battle_manager.stored_action_data = undefined; // Clear action
                         _next_state = "item_select"; // Stay in item menu
                     }
                 } else if (_target_type == "ally") {
                     // For now, assume self-target
                     // TODO: Implement ally targeting menu if needed
                     obj_battle_manager.selected_target_id = id; // Target this battle player instance
                     _next_state = "ExecutingAction";
                 } else { // Self or no target needed (e.g., status cure)
                      obj_battle_manager.selected_target_id = id; // Assume self target for now
                      _next_state = "ExecutingAction";
                 }

                 // --- Decrease quantity ONLY if state changed (meaning item use is proceeding) ---
                 if (_next_state != "item_select") {
                      // Decrease quantity in the PERSISTENT inventory
                      _selected_inv_entry.quantity -= 1;
                      show_debug_message("Decreased " + _selected_inv_entry.item_key + " quantity to " + string(_selected_inv_entry.quantity));

                      // Remove entry from persistent inventory if quantity is zero
                      if (_selected_inv_entry.quantity <= 0) {
                          // --- FIX: Added third argument '1' ---
                          array_delete(obj_player.inventory, d.item_index, 1); // Remove 1 element at index
                          // --- End Fix ---
                          show_debug_message("Removed item entry from inventory.");
                          // Adjust index if needed after deletion to avoid out-of-bounds
                          d.item_index = max(0, d.item_index - 1);
                      }
                      // Set the final state
                      global.battle_state = _next_state;
                 }
                 // Else: State didn't change (e.g., no target), don't consume item

             } else { show_debug_message("Item not usable in battle or invalid data."); }
         } else { show_debug_message("No items to select."); }
     } else if (B) { // Cancel Item Menu
         global.battle_state = "player_input";
     }
}
// Main Input Handling
else if (global.battle_state == "player_input") {
    if (X) { // Open Skill Menu
        global.battle_state = "skill_select";
        d.skill_index = 0; // Reset skill selection index
    }
    else if (Y) { // --- Open Item Menu ---
        if (tot_items > 0) { // Only open if inventory isn't empty
             global.battle_state = "item_select";
             d.item_index = 0; // Reset item selection index
        } else {
             show_debug_message("Inventory is empty!");
             // Maybe play a sound effect?
        }
    }
    else if (A) { // Attack Action
        if (ds_list_size(global.battle_enemies) > 0) { obj_battle_manager.stored_action_data = "Attack"; global.battle_target = 0; global.battle_state = "TargetSelect"; }
        else { show_debug_message("No enemies to attack!"); }
    }
    else if (B) { // Defend Action
        obj_battle_manager.stored_action_data = "Defend"; obj_battle_manager.selected_target_id = noone; global.battle_state = "ExecutingAction";
    }
}