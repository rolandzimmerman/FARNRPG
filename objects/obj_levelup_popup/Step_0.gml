/// obj_levelup_popup :: Step Event
/// — Wait for A/Enter, then advance or finish
if (keyboard_check_pressed(vk_enter)
 || keyboard_check_pressed(vk_space)
 || gamepad_button_check_pressed(0, gp_face1)) {

    // destroy this popup
    instance_destroy();

    // advance to next character
    global.battle_levelup_index += 1;

    if (global.battle_levelup_index < array_length(global.battle_level_up_infos)) {
        // spawn the next popup on your UI layer
        instance_create_layer(0, 0, "Instances", obj_levelup_popup);
    } else {
        // no more, return to field
        global.battle_state = "return_to_field";
        with (obj_battle_manager) alarm[0] = 60;
    }
}
