// obj_dialog.endstep
if (current_message < 0) exit;

var _str = messages[current_message].msg;
var _len = string_length(_str);

// --- Text Crawling ---
if (current_char < _len)
{
    var _input_pressed = (keyboard_check_pressed(input_key) || gamepad_button_check_pressed(0, gp_face1));
    current_char += char_speed * (1 + _input_pressed);
    current_char = min(current_char, _len);
    draw_message = string_copy(_str, 0, current_char);
}
// --- Advance Dialogue ---
else if ((keyboard_check_pressed(input_key) || gamepad_button_check_pressed(0, gp_face1)))
{
    // --- SCRIPT EXECUTION ---
    var _completed_message_index = current_message;
    var _msg_data = messages[_completed_message_index];

    // Check if a script should run after this message
    if (variable_struct_exists(_msg_data, "script_to_run"))
    {
        var _script = _msg_data.script_to_run; // Get the script index

        if (script_exists(_script))
        {
            // --- Argument Handling ---
            var _args_array = undefined; // Default to no arguments

            // Check if script_args exists AND is an array
            if (variable_struct_exists(_msg_data, "script_args")) {
                var _potential_args = _msg_data.script_args;
                if (is_array(_potential_args)) {
                    _args_array = _potential_args; // Store the array if valid
                     show_debug_message("Dialog: Found arguments for script " + script_get_name(_script) + ": " + string(_args_array));
                } else {
                     show_debug_message("Dialog Warning: script_args found for message " + string(_completed_message_index) + " but it's not an array. Ignoring args.");
                }
            }

            // --- Execute Script ---
            show_debug_message("Dialog: Executing script '" + script_get_name(_script) + "' after message index " + string(_completed_message_index));

            if (_args_array != undefined)
            {
                // --- Execute with Arguments (Manual Handling for older GMS versions) ---
                // We manually check the array length and call script_execute accordingly.
                var _num_args = array_length(_args_array);
                show_debug_message(" -> Script expects " + string(_num_args) + " arguments.");

                switch (_num_args) {
                    case 0:
                        script_execute(_script);
                        break;
                    case 1:
                        script_execute(_script, _args_array[0]);
                        break;
                    case 2: // Handles scr_AddInventoryItem("potion", 1)
                        script_execute(_script, _args_array[0], _args_array[1]);
                        break;
                    case 3:
                        script_execute(_script, _args_array[0], _args_array[1], _args_array[2]);
                        break;
                    // Add more cases here if you have scripts that take more arguments
                    // case 4: script_execute(_script, _args_array[0], _args_array[1], _args_array[2], _args_array[3]); break;
                    default:
                        // Handle cases with more arguments than explicitly listed or fallback
                        show_debug_message("Dialog Warning: Too many arguments (" + string(_num_args) + ") for explicit handling in obj_dialog End Step. Check the switch statement if >3 args needed.");
                        // Attempt to execute with first 3 as a fallback, or just run with none if preferred.
                        if (_num_args >= 3) {
                           script_execute(_script, _args_array[0], _args_array[1], _args_array[2]);
                        } else if (_num_args == 2) { // Should be caught by case 2, but for safety
                           script_execute(_script, _args_array[0], _args_array[1]);
                        } else if (_num_args == 1) { // Should be caught by case 1
                           script_execute(_script, _args_array[0]);
                        } else {
                           script_execute(_script); // Execute without args if something went wrong
                        }
                        break;
                }
            } else {
                // Execute the script without arguments (if script_args was missing or invalid)
                script_execute(_script);
            }
        }
        else if (_script != undefined && _script != -1 && _script != noone)
        {
             // Warning for non-existent script
             show_debug_message("Dialog Warning: Script specified for message " + string(_completed_message_index) + " (value: " + string(_script) + ") does not exist!");
        }
    }

    // --- Advance to next message or end ---
    current_message++;

    if (current_message >= array_length(messages))
    {
        instance_destroy();
    }
    else
    {
        current_char = 0;
        draw_message = "";
    }
}