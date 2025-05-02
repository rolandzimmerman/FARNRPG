// Toggle with M key or Gamepad Select
if (keyboard_check_pressed(ord("M")) || gamepad_button_check_pressed(0, gp_select)) {
    visible = !visible;
}
