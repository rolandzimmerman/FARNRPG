/// @function load_settings_ini()
/// Loads settings from an ini file, if it exists

if (file_exists("settings.ini")) {
    ini_open("settings.ini");

    global.sfx_volume = ini_read_real("Audio", "SFX_Volume", 1);
    global.music_volume = ini_read_real("Audio", "Music_Volume", 1);

    global.display_mode = ini_read_string("Display", "Mode", "Windowed");
    global.resolution_index = ini_read_real("Display", "ResolutionIndex", 3);

    ini_close();
}
