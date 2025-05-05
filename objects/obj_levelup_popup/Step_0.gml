/// obj_levelup_popup :: Step Event
// Advance on confirm; when done, destroy popup and trigger return_to_field
if (keyboard_check_pressed(vk_enter)
 || keyboard_check_pressed(vk_space)
 || gamepad_button_check_pressed(0, gp_face1)) {

    // Next character in the list
    popupIndex++;

    // If we’ve shown them all...
    if (popupIndex >= array_length(levelUps)) {
        // Tell the manager to go to return_to_field immediately
        with (obj_battle_manager) {
            global.battle_state = "return_to_field";
            alarm[0] = 1; // fire your Alarm[0] on the very next step
        }
        // Remove this popup
        instance_destroy();
    }
}
