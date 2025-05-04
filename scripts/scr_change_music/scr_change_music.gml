// Script: scr_change_music
// Description: Fades out current music (if any) and fades in a new track.
// Argument0: new_music_asset
// Argument1: loop (defaults true)
// Argument2: priority (defaults 10)
// Argument3: fade_milliseconds (defaults to manager's fade_time_ms)

function scr_change_music(_new_asset, _loop = true, _priority = 10, _fade_ms = -1) {

    if (!instance_exists(obj_music_manager)) { return; } // Manager required
    var _manager = obj_music_manager;
    var _new_asset_name = audio_get_name(_new_asset);

    // Use manager's default fade time if none provided
    if (_fade_ms < 0) {
        _fade_ms = _manager.fade_time_ms;
    }
    show_debug_message("scr_change_music: Request for [" + _new_asset_name + "] | Fade Time: " + string(_fade_ms) + "ms");

    // --- Check if already playing/fading IN the requested asset ---
    if (_new_asset == _manager.current_music_asset) {
        if (_manager.current_music_instance != noone && audio_is_playing(_manager.current_music_instance)) {
            // If it's already playing, maybe ensure it's at full volume? Or just ignore.
            show_debug_message(" -> Music asset [" + _new_asset_name + "] requested is already playing. Ensuring volume.");
             // Ensure gain is correct (in case it was fading) - use global volume
             if (variable_global_exists("music_volume")) {
                  audio_sound_gain(_manager.current_music_instance, clamp(global.music_volume, 0, 1), 0); // Instant gain set
             } else {
                  audio_sound_gain(_manager.current_music_instance, 1.0, 0); // Fallback
             }
            // Stop any potential lingering fade out from a rapid switch
            if (_manager.instance_fading_out != noone && audio_exists(_manager.instance_fading_out)) {
                audio_stop_sound(_manager.instance_fading_out);
                _manager.instance_fading_out = noone;
            }
            return; // Exit
        }
         _manager.current_music_instance = noone; // Asset matches, but not playing - allow replay
    }

    // --- Stop any previously fading out track ---
    // If a new track is requested before the old one finished fading, stop the old one immediately.
    if (_manager.instance_fading_out != noone && audio_exists(_manager.instance_fading_out)) {
        show_debug_message(" -> New music requested while previous fading out. Stopping instance [" + string(_manager.instance_fading_out) + "] immediately.");
        audio_stop_sound(_manager.instance_fading_out);
        _manager.instance_fading_out = noone;
    }

    // --- Start Fade Out of Current Music ---
    if (_manager.current_music_instance != noone && audio_exists(_manager.current_music_instance)) {
         _manager.instance_fading_out = _manager.current_music_instance; // Store instance to fade
         var _fading_asset_name = audio_get_name(_manager.current_music_asset);
         show_debug_message(" -> Fading out [" + _fading_asset_name + "] (Instance: " + string(_manager.instance_fading_out) + ") over " + string(_fade_ms) + "ms");
         audio_sound_gain(_manager.instance_fading_out, 0, _fade_ms); // Fade gain to 0 over time
         // Optional: Set an alarm to fully stop the sound after fading if desired
         // alarm[0] = (_fade_ms / 1000) * room_speed + 1; // +1 frame buffer
    } else {
        _manager.instance_fading_out = noone; // Ensure no lingering fade instance
    }

    // Clear current trackers before playing new
    _manager.current_music_instance = noone;
    _manager.current_music_asset = noone;

    // --- Play and Fade In New Music ---
    if (_new_asset != noone) {
        if (audio_exists(_new_asset)) {
            var _music_asset_group_id = audio_group_music; // Use correct group name
            var _group_name_for_log = audio_get_name(_music_asset_group_id);

            if (audio_group_is_loaded(_music_asset_group_id)) {
                show_debug_message(" -> Group [" + _group_name_for_log + "] is loaded. Playing [" + _new_asset_name + "]");

                var _played_id = audio_play_sound(_new_asset, _priority, _loop);
                show_debug_message(" -> audio_play_sound returned Instance ID: [" + string(_played_id) + "]");

                var _instance_is_valid = (is_real(_played_id) && _played_id >= 0 && audio_exists(_played_id));

                if (_instance_is_valid) {
                    _manager.current_music_instance = _played_id;
                    _manager.current_music_asset = _new_asset;

                    // Set initial gain to 0 INSTANTLY
                    audio_sound_gain(_manager.current_music_instance, 0, 0);

                    // Start fade IN to target volume
                    if (variable_global_exists("music_volume")) {
                        var _target_vol = clamp(global.music_volume, 0, 1);
                        show_debug_message(" -> Fading in instance [" + string(_manager.current_music_instance) + "] to volume [" + string(_target_vol) + "] over " + string(_fade_ms) + "ms");
                        audio_sound_gain(_manager.current_music_instance, _target_vol, _fade_ms);
                    } else { // Fallback if global volume missing
                        show_debug_message(" -> Fading in instance [" + string(_manager.current_music_instance) + "] to volume [1.0] over " + string(_fade_ms) + "ms (global.music_volume missing)");
                        audio_sound_gain(_manager.current_music_instance, 1.0, _fade_ms);
                    }
                } else {
                    show_debug_message("!!! ERROR: audio_play_sound failed for [" + _new_asset_name + "] !!!");
                    _manager.current_music_instance = noone;
                    _manager.current_music_asset = noone;
                }
            } else {
                show_debug_message("!!! WARNING: Audio group [" + _group_name_for_log + "] for asset [" + _new_asset_name + "] is NOT loaded yet. Cannot play. !!!");
            }
        } else {
            show_debug_message("!!! ERROR: Audio asset [" + _new_asset_name + "] does not exist! !!!");
        }
    } else {
         show_debug_message(" -> No new music requested (asset was 'noone'). Only fading out old track.");
    }
} // End function scr_change_music