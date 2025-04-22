/// obj_npc_parent :: User Event 0
// Generic interaction logic triggered by player action.

// Prevent triggering new dialog if one is already active
if (instance_exists(obj_dialog)) {
    exit; // Ignore interaction if dialogue box exists
}

// Select the appropriate dialog variable based on interaction history
var _dialog_variable_to_use = undefined;

if (!has_spoken_to) {
    _dialog_variable_to_use = dialog_initial; // Use initial dialogue first time
} else {
    _dialog_variable_to_use = dialog_repeat; // Use repeat dialogue subsequent times
}

// Validate and Show Dialog
if (is_array(_dialog_variable_to_use) && array_length(_dialog_variable_to_use) > 0) {
    // Dialog data looks valid, create the dialog box
    // Ensure create_dialog script/function exists and works
    create_dialog(_dialog_variable_to_use);

    // Mark that the initial conversation happened (if this was the first time)
    if (!has_spoken_to) {
        has_spoken_to = true;
    }
} else {
    // Log an error if the expected dialogue data is missing for this NPC
    var _missing_dialog_type = (!has_spoken_to) ? "dialog_initial" : "dialog_repeat";
    // Use a flag to prevent spamming this error for the same NPC instance
    if (!variable_instance_exists(id, "_warned_missing_" + _missing_dialog_type)) {
         show_debug_message("ERROR: Interaction failed - '" + _missing_dialog_type + "' is missing or empty for NPC: " + object_get_name(object_index) + " (ID: " + string(id) + ")");
         variable_instance_set(id, "_warned_missing_" + _missing_dialog_type, true);
    }
    // Optionally, provide fallback dialog:
    // create_dialog([{ name: "System", msg: object_get_name(object_index) + " has nothing to say." }]);
}