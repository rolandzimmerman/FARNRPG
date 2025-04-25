/// obj_pause_menu :: Step Event

// — only run if this menu is active —
if (!active) return;

// Debug (optional)
// show_debug_message("Pause Menu Step — active=" + string(active));

// --- SAFETY CHECK —————————————————————————————————————————————
var _gm = noone;
if (instance_exists(obj_game_manager)) _gm = obj_game_manager;
if (_gm == noone
 || !variable_instance_exists(_gm, "game_state")
 || _gm.game_state != "paused")
{
    // game unpaused/invalid: destroy menu
    instance_destroy();
    exit;
}

// --- INPUT ———————————————————————————————————————————————————
var up      = keyboard_check_pressed(vk_up)    || gamepad_button_check_pressed(0, gp_padu);
var down    = keyboard_check_pressed(vk_down)  || gamepad_button_check_pressed(0, gp_padd);
var confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(0, gp_face1);
var back    = keyboard_check_pressed(vk_escape)|| gamepad_button_check_pressed(0, gp_face2)|| gamepad_button_check_pressed(0, gp_start);

// --- NAVIGATION ————————————————————————————————————————————
if (down)  menu_index = (menu_index + 1) mod menu_item_count;
if (up)    menu_index = (menu_index - 1 + menu_item_count) mod menu_item_count;

// --- RESUME / CLOSE —————————————————————————————————————————
if (back || (confirm && menu_options[menu_index] == "Resume")) {
    // 1) Un-pause
    _gm.game_state = "playing";
    // 2) Reactivate gameplay objects
    instance_activate_all();
    // 3) Destroy menu
    instance_destroy();
    exit;
}

// --- CONFIRM ACTIONS ————————————————————————————————————————
if (confirm) {
    var opt = menu_options[menu_index];
    switch (opt) {
        case "Save Game":
            // temporarily reactivate so scr_save_game can see them
            instance_activate_object(obj_player);
            instance_activate_object(obj_npc_parent);
            scr_save_game("mysave.json");
            instance_deactivate_object(obj_player);
            instance_deactivate_object(obj_npc_parent);
            break;

        case "Load Game":
            instance_activate_all();
            scr_load_game("mysave.json");
            break;

        case "Quit":
            game_end();
            break;

        case "Equipment":
            // open equipment submenu
            if (!instance_exists(obj_equipment_menu)) {
                var layer_n = layer_exists("Instances_GUI") ? "Instances_GUI" : "Instances";
                var em = instance_create_layer(0, 0, layer_n, obj_equipment_menu);
                if (em != noone) {
                    em.calling_menu            = id;       // remember this pause menu
                    em.equipment_character_key = "hero";   // or whichever character
                    // deactivate pause menu until equipment closes
                    active = false;
                    instance_deactivate_object(id);
                }
            }
            break;
    }
}
