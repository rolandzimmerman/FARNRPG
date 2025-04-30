/// @description Handle navigation and actions for field item menu

if (!active) return; // Only run if active

// --- Input ---
var device = 0;
var up      = keyboard_check_pressed(vk_up)    || gamepad_button_check_pressed(device, gp_padu);
var down    = keyboard_check_pressed(vk_down)  || gamepad_button_check_pressed(device, gp_padd);
var confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(device, gp_face1);
var back    = keyboard_check_pressed(vk_escape)|| gamepad_button_check_pressed(device, gp_face2);

// --- State Machine ---
switch (menu_state) {
    case "item_select":
        var item_count = array_length(usable_items);
        if (item_count > 0) { 
            // Navigation
            if (up) { item_index = (item_index - 1 + item_count) mod item_count; /* Play Sound */ }
            if (down) { item_index = (item_index + 1) mod item_count; /* Play Sound */ }
            
            // Confirmation
            if (confirm && item_index != -1) { 
                 var selected_item_info = usable_items[item_index];
                 var item_data = scr_GetItemData(selected_item_info.item_key);
                 if (is_struct(item_data)) {
                      var itemTargetType = item_data.target ?? "none"; 
                      if (itemTargetType == "ally" || itemTargetType == "self") {
                           target_party_index = 0; 
                           menu_state = "target_select"; 
                           show_debug_message(" -> Transitioning to target_select state.");
                      } 
                      else if (itemTargetType == "all_allies") { 
                          show_debug_message(" -> Applying item to all allies...");
                          // ... (Call UseItem loop - requires UseItem update) ...
                          // ... (Consume item AFTER successful use)...
                      } 
                      else { show_debug_message(" -> Item cannot be used on allies from the menu."); }
                 } else { show_debug_message(" -> ERROR: Could not get item data for " + selected_item_info.item_key); }
            } 
        } 
        
        // --- Handle Back/Cancel ---
        if (back) {
             show_debug_message("Item Menu Field: Back pressed in item_select state.");
             show_debug_message(" -> Attempting to return to calling menu: " + string(calling_menu));
             
             // --- <<< MODIFICATION: Try activating ALL then setting flag >>> ---
             // Activate all instances that might have been deactivated by the pause system
             instance_activate_all(); 
             show_debug_message("    -> Called instance_activate_all()."); 
             // --- <<< END MODIFICATION >>> ---

             if (instance_exists(calling_menu)) { 
                 show_debug_message("    -> Calling menu instance exists.");
                 // Set the calling menu (pause menu) to active
                 if(variable_instance_exists(calling_menu, "active")) { 
                     calling_menu.active = true; 
                     show_debug_message("    -> Set calling_menu.active = true");
                 } else { show_debug_message("    -> WARNING: calling_menu missing 'active' variable!");}
                 // No longer need to activate individual objects here as activate_all was used
                 // instance_activate_object(calling_menu); 
                 // if (instance_exists(obj_game_manager)) instance_activate_object(obj_game_manager);
                 
             } else { 
                  // Fallback if the pause menu somehow got destroyed
                  show_debug_message("    -> Calling menu instance does NOT exist! Unpausing game.");
                  if(instance_exists(obj_game_manager)) { obj_game_manager.game_state = "playing"; }
                  // instance_activate_all(); // Already called above
             }
             show_debug_message("    -> Destroying self (obj_item_menu_field).");
             instance_destroy(); // Destroy this item menu
             exit; // Stop executing code in this destroyed instance
        }
        break; // End item_select state
        
    case "target_select":
         var party_list_keys = variable_global_exists("party_members") ? global.party_members : [];
         var party_count = array_length(party_list_keys);
         if (party_count == 0) { menu_state = "item_select"; break; }
         target_party_index = clamp(target_party_index, 0, max(0, party_count - 1)); 

         // Navigation (Using Up/Down)
         if (up) { target_party_index = (target_party_index - 1 + party_count) mod party_count; /* Skip KO'd? */ }
         if (down) { target_party_index = (target_party_index + 1) mod party_count; /* Skip KO'd? */ }
         
         // Confirmation
         if (confirm) {
             // ... (Your existing target confirmation logic: get target, validate, call scr_UseItem) ...
             menu_state = "item_select"; // Return to item list after using/attempting
         } 
         
         // Handle Cancellation - Returns to Item Select screen
         if (back) {
              show_debug_message("Item Menu Field Target: Back pressed. Returning to item_select state.");
              menu_state = "item_select";
         }
         break; // End target_select state
}