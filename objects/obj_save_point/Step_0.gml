/// obj_save_point :: Step Event
/// Handle fade‐out, left/right to select, A to confirm, save (if Yes), heal, then fade‐in

// Input checks: keyboard left/right, gamepad d‐pad left/right
var left    = keyboard_check_pressed(vk_left)
           || gamepad_button_check_pressed(0, gp_padl);
var right   = keyboard_check_pressed(vk_right)
           || gamepad_button_check_pressed(0, gp_padr);
var confirm = keyboard_check_pressed(vk_enter)
           || keyboard_check_pressed(vk_space)
           || gamepad_button_check_pressed(0, gp_face1);

switch (state) {

    case "idle":
        // Overlap & A to start fade‐out
        if (place_meeting(x, y, obj_player) && confirm) {
            state      = "fading_out";
            fade_alpha = 0;
            audio_play_sound(snd_sleep, 1, false);
        }
        break;

    case "fading_out":
        // Fade to black
        fade_alpha = min(fade_alpha + 0.05, 1);
        if (fade_alpha >= 1) {
            state = "menu";
        }
        break;

    case "menu":
        // LEFT/RIGHT to toggle Yes(0)/No(1)
        if (left  && menu_choice > 0) menu_choice--;
        if (right && menu_choice < 1) menu_choice++;

        // A to confirm
        if (confirm) {
            // If Yes, save game
            if (menu_choice == 0) {
                scr_save_game(save_filename);
            }

            // Heal DS‐map entries for party stats
            if (variable_global_exists("party_current_stats")
                && ds_exists(global.party_current_stats, ds_type_map)) {
                var m   = global.party_current_stats;
                var cnt = ds_map_size(m);
                var key = cnt > 0 ? ds_map_find_first(m) : undefined;
                repeat(cnt) {
                    var st = ds_map_find_value(m, key);
                    if (is_struct(st)) {
                        if (variable_struct_exists(st, "maxhp")) st.hp = st.maxhp;
                        if (variable_struct_exists(st, "maxmp")) st.mp = st.maxmp;
                        ds_map_replace(m, key, st);
                    }
                    key = ds_map_find_next(m, key);
                }
            }

            // Heal live party instances
            if (variable_global_exists("party_members") && is_array(global.party_members)) {
                for (var i = 0; i < array_length(global.party_members); i++) {
                    var p = global.party_members[i];
                    if (is_real(p) && instance_exists(p)
                     && variable_instance_exists(p, "data")
                     && is_struct(p.data)) {
                        if (variable_struct_exists(p.data, "maxhp")) p.data.hp = p.data.maxhp;
                        if (variable_struct_exists(p.data, "maxmp")) p.data.mp = p.data.maxmp;
                    }
                }
            }

            // Immediately fade back in
            state = "fading_in";
        }
        break;

    case "fading_in":
        // Fade back to gameplay
        fade_alpha = max(fade_alpha - 0.05, 0);
        if (fade_alpha <= 0) {
            fade_alpha = 0;
            state      = "idle";
        }
        break;
}
