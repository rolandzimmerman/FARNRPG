/// @function scr_AddBattleLog(_message)
/// @description Appends a line to the battle‐log object, if one exists.
function scr_AddBattleLog(_message) {
    // Find the first instance of obj_battle_log in the room
    var logInst = instance_find(obj_battle_log, 0);
    if (logInst != noone) {
        // Ensure the array exists
        if (!is_array(logInst.logEntries)) {
            logInst.logEntries = [];
            logInst.currentIndex = -1;
            logInst.timer = 0;
        }
        // Push the new message
        array_push(logInst.logEntries, string(_message));
    }
}
