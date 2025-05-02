/// obj_pause_menu :: Step Event
/// Handles navigation and actions within the main pause menu.

// — only run if this menu is active —
if (!variable_instance_exists(id, "active") || !active) exit;

// --- SAFETY CHECK: Ensure game is actually paused ---
var _gm = instance_exists(obj_game_manager) ? obj_game_manager : noone;
if (_gm == noone || !variable_instance_exists(_gm, "game_state") || _gm.game_state != "paused") {
    show_debug_message("Pause Menu Step: Game not paused or GM missing. Destroying self.");
    instance_activate_all(); instance_destroy(); exit;
}

// --- INPUT ---
var device = 0;
var up      = keyboard_check_pressed(vk_up)    || gamepad_button_check_pressed(device, gp_padu);
var down    = keyboard_check_pressed(vk_down)  || gamepad_button_check_pressed(device, gp_padd);
var confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(device, gp_face1);
var back    = keyboard_check_pressed(vk_escape)|| gamepad_button_check_pressed(device, gp_face2)|| gamepad_button_check_pressed(device, gp_start); 

// --- Initialize menu variables (Safety Check) ---
if (!variable_instance_exists(id, "menu_options"))    menu_options = ["Resume"]; // Minimal fallback
if (!variable_instance_exists(id, "menu_item_count")) menu_item_count = array_length(menu_options);
if (!variable_instance_exists(id, "menu_index"))      menu_index = 0;
// Ensure index is valid after potential option changes
menu_index = clamp(menu_index, 0, max(0, menu_item_count - 1)); 


// --- NAVIGATION ---
if (up) {
    menu_index = (menu_index - 1 + menu_item_count) mod menu_item_count;
    // audio_play_sound(snd_menu_cursor, 1, false); 
}
if (down) {
    menu_index = (menu_index + 1) mod menu_item_count;
    // audio_play_sound(snd_menu_cursor, 1, false); 
}


// --- RESUME / CLOSE PAUSE MENU ---
if (back || (confirm && menu_options[menu_index] == "Resume")) {
    // audio_play_sound(snd_menu_cancel, 1, false); 
    _gm.game_state = "playing"; 
    instance_activate_all();
    instance_destroy();
    exit; 
}


// --- CONFIRM ACTIONS (Other Menu Options) ---
if (confirm) { // This block only runs if 'Resume' was NOT the selected option
    var opt = menu_options[menu_index];
    // audio_play_sound(snd_menu_select, 1, false); 

    switch (opt) {
        
        // --- <<< ADDED: Items Case >>> ---
        case "Items":
            show_debug_message("Pause Menu: Items selected.");
            // Attempt to open an item menu for field use
            if (!instance_exists(obj_item_menu_field)) { // Check if specific field item menu exists
                var layer_id = layer_get_id("Instances_GUI") != -1 ? layer_get_id("Instances_GUI") : layer_get_id("Instances");
                if (layer_id != -1) {
                     var item_menu = instance_create_layer(0, 0, layer_id, obj_item_menu_field); // <<< NEEDS obj_item_menu_field TO EXIST
                     if (instance_exists(item_menu)) {
                          item_menu.calling_menu = id; // Tell it who called it
                          active = false; // Deactivate this menu
                          show_debug_message(" -> Created obj_item_menu_field, deactivated pause menu.");
                     } else { show_debug_message(" -> ERROR: Failed to create obj_item_menu_field!"); }
                } else { show_debug_message(" -> ERROR: No suitable layer for item menu!"); }
            } else { show_debug_message(" -> WARNING: Field item menu already exists!"); }
            break;
            
        // --- <<< ADDED: Spells Case >>> ---
        case "Spells":
            show_debug_message("Pause Menu: Spells selected.");
             // Attempt to open a spell menu for field use
            if (!instance_exists(obj_spell_menu_field)) { // Check if specific field spell menu exists
                var layer_id = layer_get_id("Instances_GUI") != -1 ? layer_get_id("Instances_GUI") : layer_get_id("Instances");
                if (layer_id != -1) {
                     var spell_menu = instance_create_layer(0, 0, layer_id, obj_spell_menu_field); // <<< NEEDS obj_spell_menu_field TO EXIST
                     if (instance_exists(spell_menu)) {
                          spell_menu.calling_menu = id; // Tell it who called it
                          active = false; // Deactivate this menu
                          show_debug_message(" -> Created obj_spell_menu_field, deactivated pause menu.");
                     } else { show_debug_message(" -> ERROR: Failed to create obj_spell_menu_field!"); }
                } else { show_debug_message(" -> ERROR: No suitable layer for spell menu!"); }
            } else { show_debug_message(" -> WARNING: Field spell menu already exists!"); }
            break;

        // --- <<< REMOVED: Save Game Case >>> ---
        // case "Save Game": 
        //     /* ... save logic ... */
        //     break;
        case "Party":
            show_debug_message("Pause Menu: Party selected.");
            if (!instance_exists(obj_party_menu)) {
                var layer_id = layer_get_id("Instances_GUI");
                if (layer_id == -1) layer_id = layer_get_id("Instances");
                var pm = instance_create_layer(0, 0, layer_id, obj_party_menu);
                if (instance_exists(pm)) {
                    pm.calling_menu = id;
                    active = false;
                    show_debug_message(" -> Created obj_party_menu, pause menu deactivated.");
                }
            }
            break;
        case "Load Game":
            show_debug_message("Pause Menu: Load Game selected.");
             instance_activate_all(); // Ensure needed objects are active
             if (script_exists(scr_load_game)) {
                 scr_load_game("mysave.json"); // Load script should handle transitions
             } else { show_debug_message(" -> ERROR: scr_load_game script not found!"); }
            break;

        case "Quit":
            show_debug_message("Pause Menu: Quit selected.");
            game_end(); 
            break;

        case "Equipment":
             show_debug_message("Pause Menu: Equipment selected.");
             if (!instance_exists(obj_equipment_menu)) {
                 var layer_id = layer_get_id("Instances_GUI") != -1 ? layer_get_id("Instances_GUI") : layer_get_id("Instances");
                 if (layer_id != -1) {
                     var em = instance_create_layer(0, 0, layer_id, obj_equipment_menu);
                     if (instance_exists(em)) { 
                          em.calling_menu = id; 
                          active = false; 
                          show_debug_message(" -> Created obj_equipment_menu, deactivated pause menu.");
                     } else { show_debug_message(" -> ERROR: Failed to create obj_equipment_menu instance!"); }
                 } else { show_debug_message("ERROR: Cannot find layer for equipment menu!"); break; }
             } else { show_debug_message(" -> WARNING: Equipment menu already exists!"); }
            break; 
        case "Settings":
            show_debug_message("Pause Menu: Settings selected.");
            var layer_id = layer_get_id("Instances_GUI");
            if (layer_id == -1) layer_id = layer_get_id("Instances");
            var sm = instance_create_layer(0, 0, layer_id, obj_settings_menu);
            if (instance_exists(sm)) {
                sm.calling_menu = id;
                active = false;
            }
            break;
            
        // Note: "Resume" is handled by the 'back' check earlier, so no case needed here.
            
    } // End Switch
} // End if(confirm)