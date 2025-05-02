persistent = true;

// Load settings from INI
if (file_exists("settings.ini")) {
    ini_open("settings.ini");

    global.sfx_volume       = ini_read_real("Audio", "SFX_Volume", 1);
    global.music_volume     = ini_read_real("Audio", "Music_Volume", 1);
    global.display_mode     = ini_read_string("Display", "Mode", "Windowed");
    global.resolution_index = ini_read_real("Display", "ResolutionIndex", 3);

    ini_close();
} else {
    global.sfx_volume = 1;
    global.music_volume = 1;
    global.display_mode = "Windowed";
    global.resolution_index = 3;
}

if (!variable_global_exists("resolution_options")) {
    global.resolution_options = [
        [640, 360],
        [800, 600],
        [1024, 768],
        [1280, 720],
        [1600, 900],
        [1920, 1080]
    ];
}

// Load audio groups
audio_group_load(audio_group_sfx);
audio_group_load(audio_group_music);

// Apply volumes
audio_group_set_gain(audio_group_sfx, global.sfx_volume, 0);
audio_group_set_gain(audio_group_music, global.music_volume, 0);

// Apply resolution and display mode
var res = global.resolution_options[global.resolution_index];
apply_display_mode(global.display_mode);
apply_resolution(res[0], res[1]);
