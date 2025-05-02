/*draw_set_color(c_white);
draw_text(20, 20, "SFX Volume: " + string(global.sfx_volume));
draw_text(20, 40, "Music Volume: " + string(global.music_volume));
draw_text(20, 60, "Mode: " + global.display_mode);

var res = global.resolution_options[global.resolution_index];
draw_text(20, 80, "Resolution: " + string(res[0]) + "x" + string(res[1]));

draw_text(20, 100, "snd_attack group: " + string(audio_sound_get_audio_group(snd_sfx_fire)));
