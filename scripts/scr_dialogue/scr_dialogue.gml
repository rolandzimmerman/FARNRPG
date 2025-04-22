/// scr_dialogue (or create_dialog)
// Contains function(s) for managing the dialog system.

/// @function create_dialog(_messages)
/// @description Creates a dialog box instance if one doesn't exist and passes it the message array.
/// @param {array[struct]} _messages Array of message structs, each with 'name' and 'msg'.
function create_dialog(_messages){
    // Prevent creating multiple dialog boxes
    if (instance_exists(obj_dialog)) {
        show_debug_message("Dialog Info: Instance of obj_dialog already exists. Call ignored.");
        return; // Exit if a dialog box is already active
    }

    // Validate input: Check if _messages is an array and not empty
    if (!is_array(_messages) || array_length(_messages) == 0) {
         show_debug_message("Dialog Error: create_dialog called with invalid or empty message array.");
         return; // Exit if messages are invalid
    }

    show_debug_message("Dialog Info: Creating obj_dialog instance.");
    // Create the dialog object instance
    // Using depth 0 might be okay, but consider using layers for better control
    // var _layer = "Instances_GUI"; // Or your dedicated UI layer
    // var _inst = instance_create_layer(0, 0, _layer, obj_dialog);
    // Using depth for simplicity as in original:
    var _inst = instance_create_depth(0, 0, -9999, obj_dialog); // Use a very high depth (low number) to draw on top

    // Check if instance creation failed
    if (_inst == noone) {
        show_debug_message("Dialog Error: Failed to create obj_dialog instance!");
        return;
    }

    // Pass the messages to the instance and initialize it
    _inst.messages = _messages;
    _inst.current_message = 0; // Start at the first message
    _inst.current_char = 0;    // Reset character position for text crawl
    _inst.draw_message = "";   // Reset drawn message string

    show_debug_message("   -> Assigned " + string(array_length(_messages)) + " messages to instance ID: " + string(_inst));
}

// Removed data definitions (char_colors, welcome_dialog, claude_diag, etc.)
// Those should be defined elsewhere (e.g., global.char_colors in obj_init,
// dialog arrays in NPC objects or dedicated data scripts).
