// Script: scr_resume_music
// Description: Fades in a specific music track starting from a given position.
//              Stops any currently playing/fading music first.
// Argument0: asset_to_resume
// Argument1: position_to_resume_at
// Argument2 (Optional): fade_milliseconds (defaults to manager's fade_time_ms)

function scr_resume_music(_asset_to_resume, _position_to_resume_at, _fade_ms = -1) {

    if (!instance_exists(obj_music_manager)) { return; }
    var _manager = obj_music_manager;
    var _asset_name = audio_get_name(_asset_to_resume);

    // Use manager's default fade time if none provided
    if (_fade_ms < 0) {
        _fade_ms = _manager.fade_time_ms;
    }
    show_debug_message("scr_resume_music: Resuming [" + _asset_name + "] at Pos [" + string(_position_to_resume_at) + "] | Fade: " + string(_fade_ms) + "ms");

    // --- Stop any previously playing/fading out track ---
    if (_manager.instance_fading_out != noone && audio_exists(_manager.instance_fading_out)) {
        show_debug_message(" -> Stopping lingering fade-out instance: [" + string(_manager.instance_fading_out) + "]");
        audio_stop_sound(_manager.instance_fading_out);
    }
     _manager.instance_fading_out = noone; // Clear fade out tracker

    if (_manager.current_music_instance != noone && audio_exists(_manager.current_music_instance)) {
         show_debug_message(" -> Stopping current music instance: [" + string(_manager.current_music_instance) + "]");
         audio_stop_sound(_manager.current_music_instance);
    }
    _manager.current_music_instance = noone; // Clear current tracker
    _manager.current_music_asset = noone;


    // --- Validate Asset and Load State ---
    if (_asset_to_resume != noone && audio_exists(_asset_to_resume)) {
        var _music_asset_group_id = audio_group_music; // Use correct group name
        var _group_name_for_log = audio_get_name(_music_asset_group_id);

        if (audio_group_is_loaded(_music_asset_group_id)) {
            show_debug_message(" -> Group [" + _group_name_for_log + "] is loaded. Playing...");

            // --- Play the sound (looping assumed) ---
            var _played_id = audio_play_sound(_asset_to_resume, 10, true);
            show_debug_message(" -> audio_play_sound returned Instance ID: [" + string(_played_id) + "]");

            var _instance_is_valid = (is_real(_played_id) && _played_id >= 0 && audio_exists(_played_id));

            if (_instance_is_valid) {
                _manager.current_music_instance = _played_id;
                _manager.current_music_asset = _asset_to_resume;

                // --- Set Position & Start Fade In ---
                show_debug_message(" -> Setting track position for [" + string(_played_id) + "] to: " + string(_position_to_resume_at));
                audio_sound_set_track_position(_played_id, _position_to_resume_at);

                // Set initial gain to 0 INSTANTLY before fading
                audio_sound_gain(_manager.current_music_instance, 0, 0);

                // Start fade IN
                if (variable_global_exists("music_volume")) {
                    var _target_vol = clamp(global.music_volume, 0, 1);
                    show_debug_message(" -> Fading in resumed instance [" + string(_manager.current_music_instance) + "] to volume [" + string(_target_vol) + "] over " + string(_fade_ms) + "ms");
                    audio_sound_gain(_manager.current_music_instance, _target_vol, _fade_ms);
                } else {
                    show_debug_message(" -> Fading in resumed instance [" + string(_manager.current_music_instance) + "] to volume [1.0] over " + string(_fade_ms) + "ms");
                    audio_sound_gain(_manager.current_music_instance, 1.0, _fade_ms);
                }
                 show_debug_message(" -> Music Resume Initiated.");

            } else {
                show_debug_message("!!! ERROR: Failed to create resume instance for [" + _asset_name + "] !!!");
                _manager.current_music_instance = noone;
                _manager.current_music_asset = noone;
            }
        } else {
            show_debug_message("!!! WARNING: Audio group for [" + _asset_name + "] not loaded. Cannot resume. !!!");
        }
    } else {
        show_debug_message("!!! ERROR: Cannot resume invalid asset [" + _asset_name + "] !!!");
    }
} // End function scr_resume_music