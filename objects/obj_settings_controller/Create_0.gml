/// obj_settings_controller :: Create Event
/// Loads game settings and initializes audio groups/volumes using correct asset IDs.

persistent = true;

show_debug_message("===== Settings Loader START =====");

// Audio Bus indices are removed as we are not using the bus system based on your feedback
// global.music_bus_index = 1; // REMOVED
// global.sfx_bus_index = 2;   // REMOVED

// --- Load settings from INI file ---
var _ini_file = "settings.ini";
if (file_exists(_ini_file)) {
    ini_open(_ini_file);
    show_debug_message(" -> Reading settings from " + _ini_file);
    global.sfx_volume        = clamp(ini_read_real("Audio", "SFX_Volume", 1.0), 0, 1);
    global.music_volume      = clamp(ini_read_real("Audio", "Music_Volume", 1.0), 0, 1);
    global.display_mode      = ini_read_string("Display", "Mode", "Windowed");
    global.resolution_index  = ini_read_real("Display", "ResolutionIndex", 3);
    ini_close();
} else {
    show_debug_message(" -> " + _ini_file + " not found, using default settings.");
    global.sfx_volume = 1.0;
    global.music_volume = 1.0;
    global.display_mode = "Windowed";
    global.resolution_index = 3;
}
show_debug_message(" -> Loaded Settings: SFX Vol=" + string(global.sfx_volume) + " | Music Vol=" + string(global.music_volume) + " | Display=" + global.display_mode + " | Res Index=" + string(global.resolution_index));

// --- Setup Resolution Options ---
if (!variable_global_exists("resolution_options")) {
    global.resolution_options = [ [640, 360], [800, 600], [1024, 768], [1280, 720], [1600, 900], [1920, 1080] ];
    show_debug_message(" -> Initialized default resolution options array.");
}
global.resolution_index = clamp(global.resolution_index, 0, array_length(global.resolution_options) - 1);

// --- Audio Group Setup & Loading ---
// <<< ASSIGN YOUR ACTUAL ASSET GROUP RESOURCES HERE >>>
// These names MUST exactly match the names in your Asset Browser -> Audio Groups
// If these assets don't exist, GMS should ideally give a compile error.
var sfx_group_id = audio_group_sfx;   // Replace 'audio_group_sfx' if necessary
var music_group_id = audio_group_music; // Replace 'audio_group_music' if necessary
// <<< END ASSET GROUP ASSIGNMENT >>>

// Log the names and IDs being used
var sfx_group_name_string = audio_get_name(sfx_group_id);
show_debug_message(" -> Preparing SFX Group: Name=[" + sfx_group_name_string + "] ID=[" + string(sfx_group_id) + "]");
var music_group_name_string = audio_get_name(music_group_id);
show_debug_message(" -> Preparing Music Group: Name=[" + music_group_name_string + "] ID=[" + string(music_group_id) + "]");

// Start loading audio ASSET groups asynchronously using their IDs
show_debug_message("     -> Initiating load for SFX Group ID: " + string(sfx_group_id));
audio_group_load(sfx_group_id);

show_debug_message("     -> Initiating load for Music Group ID: " + string(music_group_id));
audio_group_load(music_group_id);


// --- Apply volumes using audio_group_set_gain ---
// We apply this now; the sounds played later will inherit this gain setting for the group.
show_debug_message(" -> Setting SFX Group [" + sfx_group_name_string + "] Gain: " + string(global.sfx_volume));
audio_group_set_gain(sfx_group_id, global.sfx_volume, 0); // 0 = immediate time

show_debug_message(" -> Setting Music Group [" + music_group_name_string + "] Gain: " + string(global.music_volume));
audio_group_set_gain(music_group_id, global.music_volume, 0); // 0 = immediate time


// --- Apply Initial Display Settings ---
if (script_exists(apply_display_mode) && script_exists(apply_resolution)) {
    var res = global.resolution_options[global.resolution_index];
    show_debug_message(" -> Applying Display Mode: " + global.display_mode);
    apply_display_mode(global.display_mode);
    show_debug_message(" -> Applying Resolution: " + string(res[0]) + "x" + string(res[1]));
    apply_resolution(res[0], res[1]);
} else {
     show_debug_message("!!! WARNING: apply_display_mode or apply_resolution script missing! Cannot apply display settings. !!!");
}

show_debug_message("===== Settings Loader END =====");