/// obj_music_manager :: Room Start Event
/// Handles music changes: starting battle, resuming after battle, or changing normally with fades.

var _current_room_name = room_get_name(room);
show_debug_message("Music Manager: Room Start Event - Entered Room: [" + _current_room_name + "]");

var _was_pre_battle_asset = pre_battle_music_asset;
var _was_pre_battle_pos = pre_battle_music_position;
var _was_pre_battle_room = pre_battle_room;

// Clear pre-battle state *unless* entering battle room again immediately
if (room != rm_battle) {
    pre_battle_music_asset = noone;
    pre_battle_music_position = 0;
    pre_battle_room = noone;
}

// --- Determine Action Based on Current Room ---

if (room == rm_battle) {
    // --- ENTERING BATTLE ---
    show_debug_message(" -> Entering Battle Room.");
    if (current_music_instance != noone && audio_is_playing(current_music_instance)) {
        // Store state BEFORE calling scr_change_music (which fades out current)
        pre_battle_music_asset = current_music_asset;
        pre_battle_music_position = audio_sound_get_track_position(current_music_instance);
        if (variable_global_exists("previous_room")) { pre_battle_room = global.previous_room; } else { pre_battle_room = noone; }
        show_debug_message(" -> Storing Pre-Battle Music: Asset=[" + audio_get_name(pre_battle_music_asset) + "], Pos=[" + string(pre_battle_music_position) + "], From Room=[" + room_get_name(pre_battle_room) + "]");
        // No need to stop sound here, scr_change_music will fade it out
    } else {
        // No music playing, just store return room
         if (variable_global_exists("previous_room")) { pre_battle_room = global.previous_room; } else { pre_battle_room = noone; }
        pre_battle_music_asset = noone; pre_battle_music_position = 0;
        show_debug_message(" -> No music playing before battle. Storing return room: [" + room_get_name(pre_battle_room) + "]");
    }
    // Play battle music with fade
    var _battle_music = noone; // <<< SET YOUR BATTLE MUSIC ASSET HERE
    scr_change_music(_battle_music, true, 15, fade_time_ms); // Pass fade time

} else if (_was_pre_battle_asset != noone) {
    // --- RETURNING FROM BATTLE ---
    show_debug_message(" -> Returning From Battle (Detected stored music).");
    // Resume stored music with fade
    if (script_exists(scr_resume_music)) {
        scr_resume_music(_was_pre_battle_asset, _was_pre_battle_pos, fade_time_ms); // Pass fade time
    } else { show_debug_message("!!! ERROR: scr_resume_music script missing! !!!"); }
    // Clear pre-battle state now that we've used it
    pre_battle_music_asset = noone; pre_battle_music_position = 0; pre_battle_room = noone;

} else {
    // --- NORMAL ROOM CHANGE ---
    show_debug_message(" -> Normal Room Change.");
    pre_battle_music_asset = noone; pre_battle_music_position = 0; pre_battle_room = noone; // Clear just in case
    var _new_music = noone;
    switch (room) {
        case Room2: _new_music = noone; break;
        //case Room1: noone;
        case Room1: _new_music = NighttimeintheCity; break;
        //case rm_dungeon1: _new_music = mus_dungeon_theme; break;
        // Add other rooms
    }
    // Change to new room music with fade
    if (script_exists(scr_change_music)) {
        scr_change_music(_new_music, true, 10, fade_time_ms); // Pass fade time
    } else { show_debug_message("!!! ERROR: scr_change_music script not found! !!!"); }
}