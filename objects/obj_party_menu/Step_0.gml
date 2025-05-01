/// obj_party_menu :: Step Event
if (!active) return;

// input
var device  = 0;
var up      = keyboard_check_pressed(vk_up)    || gamepad_button_check_pressed(device, gp_padu);
var down    = keyboard_check_pressed(vk_down)  || gamepad_button_check_pressed(device, gp_padd);
var confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(device, gp_face1);
var back    = keyboard_check_pressed(vk_escape)|| gamepad_button_check_pressed(device, gp_face2);

var count = array_length(global.party_members);

switch (menu_state) {
    // ── Pick the first slot ───────────────────────────────────────────────
    case "choose_first":
        if (up)   member_index = (member_index - 1 + count) mod count;
        if (down) member_index = (member_index + 1) mod count;

        if (confirm) {
            selected_index = member_index;
            menu_state     = "choose_second";
            show_debug_message("Party: first slot = " + string(selected_index));
        }
        break;

    // ── Pick the second slot and swap ─────────────────────────────────────
    case "choose_second":
        if (up)   member_index = (member_index - 1 + count) mod count;
        if (down) member_index = (member_index + 1) mod count;

        if (confirm) {
            if (member_index != selected_index) {
                // swap in the global array
                var a = global.party_members[selected_index];
                global.party_members[selected_index] = global.party_members[member_index];
                global.party_members[member_index]  = a;
                audio_play_sound(snd_menu_select, 1, false);
                show_debug_message("Party: swapped " + string(selected_index) + " ↔ " + string(member_index));
            }
            // return to pause
            if (instance_exists(calling_menu)) calling_menu.active = true;
            else if (instance_exists(obj_game_manager)) obj_game_manager.game_state = "playing";
            instance_destroy();
        }
        break;
}

// cancel back to pause
if (back) {
    show_debug_message("Party Menu: canceled");
    if (instance_exists(calling_menu)) calling_menu.active = true;
    else if (instance_exists(obj_game_manager)) obj_game_manager.game_state = "playing";
    instance_destroy();
}
