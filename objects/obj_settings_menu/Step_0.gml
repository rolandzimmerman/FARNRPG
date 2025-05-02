if (!menu_active) exit;

var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);

input_cooldown = max(0, input_cooldown - 1);

var up      = keyboard_check_pressed(vk_up)    || (gamepad_button_check_pressed(0, gp_padu) && input_cooldown == 0);
var down    = keyboard_check_pressed(vk_down)  || (gamepad_button_check_pressed(0, gp_padd) && input_cooldown == 0);
var left    = keyboard_check_pressed(vk_left)  || gamepad_button_check_pressed(0, gp_padl);
var right   = keyboard_check_pressed(vk_right) || gamepad_button_check_pressed(0, gp_padr);
var confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(0, gp_face1);
var back    = keyboard_check_pressed(vk_escape)|| gamepad_button_check_pressed(0, gp_face2);

if (up) {
    settings_index = (settings_index - 1 + array_length(settings_items)) mod array_length(settings_items);
    input_cooldown = 8;
}
if (down) {
    settings_index = (settings_index + 1) mod array_length(settings_items);
    input_cooldown = 8;
}

// --- Confirm / Enter selection ---
if (confirm) {
    switch (settings_items[settings_index]) {
        case "Back":
            instance_destroy();
            with (obj_pause_menu) active = true;
            break;
        case "Display Mode":
            dropdown_display_open = !dropdown_display_open;
            dropdown_resolution_open = false;
            break;
        case "Resolution":
            dropdown_resolution_open = !dropdown_resolution_open;
            dropdown_display_open = false;
            break;
    }
}

// --- Back out of menu ---
if (back) {
    instance_destroy();
    with (obj_pause_menu) active = true;
}

// --- Controller change sliders ---
switch (settings_items[settings_index]) {
    case "SFX Volume":
        if (left) {
            global.sfx_volume = max(0, global.sfx_volume - 0.05);
            save_settings_ini();
        }
        if (right) {
            global.sfx_volume = min(1, global.sfx_volume + 0.05);
            save_settings_ini();
        }
        break;

    case "Music Volume":
        if (left) {
            global.music_volume = max(0, global.music_volume - 0.05);
            save_settings_ini();
        }
        if (right) {
            global.music_volume = min(1, global.music_volume + 0.05);
            save_settings_ini();
        }
        break;
}

// --- Controller select from dropdown (simulate arrow navigation) ---
if (dropdown_display_open && (up || down)) {
    dropdown_display_index = (dropdown_display_index + (down - up) + array_length(dropdown_display_options)) mod array_length(dropdown_display_options);
    global.display_mode = dropdown_display_options[dropdown_display_index];
    apply_display_mode(global.display_mode);
    save_settings_ini();
}
if (dropdown_resolution_open && (up || down)) {
    global.resolution_index = (global.resolution_index + (down - up) + array_length(global.resolution_options)) mod array_length(global.resolution_options);
    var res = global.resolution_options[global.resolution_index];
    apply_resolution(res[0], res[1]);
    save_settings_ini();
}
