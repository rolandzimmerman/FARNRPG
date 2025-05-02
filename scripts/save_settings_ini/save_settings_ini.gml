function save_settings_ini() {
    ini_open("settings.ini");

    ini_write_real("Audio", "SFX_Volume", global.sfx_volume);
    ini_write_real("Audio", "Music_Volume", global.music_volume);
    ini_write_string("Display", "Mode", global.display_mode);
    ini_write_real("Display", "ResolutionIndex", global.resolution_index);

    ini_close();

    // Debug log
    show_debug_message("Settings saved:");
    show_debug_message(" - SFX: " + string(global.sfx_volume));
    show_debug_message(" - Music: " + string(global.music_volume));
    show_debug_message(" - Mode: " + global.display_mode);
    show_debug_message(" - Resolution Index: " + string(global.resolution_index));
}
