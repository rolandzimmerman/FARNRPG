/// obj_dialog :: Step Event
/// Typewriter + advance key + per‐line callbacks + clean destroy

// 1) Bail out if dialog hasn’t started
if (current_message < 0) {
    return;
}

// 2) Grab this line’s data
var entry    = messages[current_message];
var fullText = entry.msg;

// 3) Typewriter effect: reveal more chars each step
if (current_char < string_length(fullText)) {
    // Speed up when holding Space (or face1)
    var fast = keyboard_check(vk_space) || gamepad_button_check(0, gp_face1);
    current_char += char_speed * (fast ? 2 : 1);
    current_char = min(current_char, string_length(fullText));
    draw_message = string_copy(fullText, 1, current_char);
    return;
}

// 4) Wait for a fresh press of the advance key
if (!keyboard_check_pressed(vk_space) && !gamepad_button_check_pressed(0, gp_face1)) {
    return;
}

// 5) Fire any `callback` you attached to this entry (once)
var flagName = "cb_done_" + string(current_message);
if (!variable_instance_exists(id, flagName)
 && variable_struct_exists(entry, "callback"))
{
    var fn   = entry.callback;
    var args = variable_struct_exists(entry, "callback_args") 
             ? entry.callback_args 
             : [];

    switch (array_length(args)) {
        case 0: script_execute(fn);                                        break;
        case 1: script_execute(fn, args[0]);                               break;
        case 2: script_execute(fn, args[0], args[1]);                      break;
        case 3: script_execute(fn, args[0], args[1], args[2]);             break;
        default: script_execute(fn, args[0], args[1], args[2], args[3]);   break;
    }
    variable_instance_set(id, flagName, true);
}

// 6) Advance to the next line
current_message += 1;
current_char     = 0;
draw_message     = "";

// 7) If we’re out of lines, destroy the dialog cleanly
if (current_message >= array_length(messages)) {
    instance_destroy();
}
