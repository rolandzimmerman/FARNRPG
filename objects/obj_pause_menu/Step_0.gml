/// obj_pause_menu :: Step Event

// Only run when our menu is active:
if (!menu_active) exit;

// Safety: Must still be in Paused state, otherwise close
var _gm = instance_exists(obj_game_manager) ? obj_game_manager : noone;
if (_gm == noone || !variable_instance_exists(_gm, "game_state") || _gm.game_state != "paused") {
    instance_destroy();
    exit;
}

// Input
var up    = keyboard_check_pressed(vk_up)   || gamepad_button_check_pressed(0, gp_padu);
var down  = keyboard_check_pressed(vk_down) || gamepad_button_check_pressed(0, gp_padd);
var conf  = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(0, gp_face1);
var canc  = keyboard_check_pressed(vk_escape)|| gamepad_button_check_pressed(0, gp_face2) || gamepad_button_check_pressed(0, gp_start);

// Navigate
if (down) menu_index = (menu_index + 1) mod menu_item_count;
if (up)   menu_index = (menu_index - 1 + menu_item_count) mod menu_item_count;

// Resume on Cancel or Confirm-Resume
if (canc || (conf && menu_options[menu_index] == "Resume")) {
    _gm.game_state = "playing";
    instance_activate_all();
    instance_destroy();
    exit;
}

if (conf) {
    var _opt = menu_options[menu_index];
    switch (_opt) {
        case "Save Game":
            scr_save_game("mysave.json");
            break;

        case "Load Game":
            instance_activate_all();
            scr_load_game("mysave.json");
            break;

        case "Equipment":
            if (!instance_exists(obj_equipment_menu)) {
                var layer_nm = layer_exists("Instances_GUI") ? "Instances_GUI" : "Instances";
                var eq = instance_create_layer(0, 0, layer_nm, obj_equipment_menu);
                if (eq != noone) {
                    eq.calling_menu            = id;      // so we can re-activate this menu later
                    eq.equipment_character_key = "hero";  // or whatever character you want
                    // deactivate *this* pause menu so it no longer receives input
                    instance_deactivate_object(id);
                }
            }
            break;

        case "Quit":
            game_end();
            break;
    }
}
