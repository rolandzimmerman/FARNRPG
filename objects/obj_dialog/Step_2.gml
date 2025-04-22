//obj_dialog.endstep
if (current_message < 0) exit;
    
var _str = messages[current_message].msg;

if (current_char < string_length(_str))
{
    current_char += char_speed * (1 + (keyboard_check_pressed(input_key) || gamepad_button_check_pressed(0, gp_face1)));
    draw_message = string_copy(_str, 0, current_char);
}
else if ((keyboard_check_pressed(input_key) || gamepad_button_check_pressed(0, gp_face1))) 
{
    	current_message++;
        if(current_message >= array_length(messages))
{
    instance_destroy();
} 
    else
{
    current_char = 0;
}
}