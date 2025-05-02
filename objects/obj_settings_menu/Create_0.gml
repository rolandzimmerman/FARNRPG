settings_index = 0;
settings_items = ["Display Mode", "Resolution", "SFX Volume", "Music Volume", "Back"];
dropdown_display_open = false;
dropdown_resolution_open = false;

dropdown_display_options = ["Windowed", "Fullscreen", "Borderless"];
dropdown_display_index = 0;

for (var i = 0; i < array_length(dropdown_display_options); i++) {
    if (dropdown_display_options[i] == global.display_mode) {
        dropdown_display_index = i;
        break;
    }
}

menu_active = true;
input_cooldown = 0;
