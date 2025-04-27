/// @function scr_UseItem(_user_inst, _item_data, _target_inst)
/// @description Applies an item's effect, consumes it from inventory, returns true if successful.
/// @param {Instance} _user_inst      The instance using the item.
/// @param {Struct}   _item_data      The item data struct (from item database).
/// @param {Instance} _target_inst    The target instance (can be user or enemy).
/// @returns {Bool} True if item was successfully used (turn advances), false otherwise.
function scr_UseItem(_user_inst, _item_data, _target_inst) {
    show_debug_message("--- scr_UseItem START ---");
    show_debug_message(" User: " + string(_user_inst));
    show_debug_message(" Item: " + string(_item_data));
    show_debug_message(" Target: " + string(_target_inst));

    // 1. Validate Inputs
    if (!instance_exists(_user_inst)) { show_debug_message(" Error: Invalid user."); return false; }
    if (!is_struct(_item_data) || !variable_struct_exists(_item_data, "effect") || !variable_struct_exists(_item_data, "item_key")) { show_debug_message(" Error: Invalid item data."); return false; }
    // Target validation happens within the effect cases where needed

    var item_effect = _item_data.effect;
    var item_value  = variable_struct_exists(_item_data, "value") ? _item_data.value : 0;
    var item_key    = _item_data.item_key;

    var success = false; // Did the item effect apply successfully?
    var show_popup = true;
    var popup_text = "";
    var popup_color = c_white;
    var popup_target = _target_inst; // Default popup target

    // 2. Apply Effect based on item_effect string
    switch (item_effect) {
        case "heal_hp":
            if (instance_exists(_target_inst) && variable_instance_exists(_target_inst, "data") && is_struct(_target_inst.data)) {
                var td = _target_inst.data;
                if (variable_struct_exists(td, "hp") && variable_struct_exists(td, "maxhp")) {
                    var old_hp = td.hp; td.hp = min(td.maxhp, td.hp + item_value); var actual_healed = td.hp - old_hp;
                    if (actual_healed > 0) { popup_text = string(actual_healed); popup_color = c_lime; success = true; }
                    else { success = true; show_popup = false; } // Succeeded even if no change
                } else { success = false; show_popup = false; }
            } else { success = false; show_popup = false; }
            break;

        case "damage_enemy":
             if (instance_exists(_target_inst) && variable_instance_exists(_target_inst, "data") && is_struct(_target_inst.data)) {
                var td = _target_inst.data;
                if (variable_struct_exists(td, "hp")) {
                    var dmg = item_value;
                    if (variable_struct_exists(td, "is_defending") && td.is_defending) dmg = floor(dmg / 2); dmg = max(1, dmg);
                    td.hp = max(0, td.hp - dmg);
                    popup_text = string(dmg); popup_color = c_white; success = true;
                } else { success = false; show_popup = false; }
            } else { success = true; show_popup = false; } // Count as success if target gone
            break;

        case "cure_status":
            // Uses INSTANCE variables status_effect / status_duration
            if (instance_exists(_target_inst) && variable_instance_exists(_target_inst, "status_effect")) {
                var status_to_cure = item_value; // Assumes item.value holds the status name like "poison"
                if (_target_inst.status_effect == status_to_cure) {
                    _target_inst.status_effect = "none";
                    if (variable_instance_exists(_target_inst,"status_duration")) { _target_inst.status_duration = 0; }
                    popup_text = string_capitalize(status_to_cure) + " Cured!"; popup_color = c_aqua; success = true;
                } else {
                     show_debug_message(" -> Target did not have status: " + string(status_to_cure));
                     success = true; show_popup = false; // Item used even if no status present
                }
            } else { show_debug_message(" -> Cure target invalid or missing status_effect var"); success = false; show_popup = false; }
            break;

        // ADD MORE CASES HERE FOR OTHER ITEM EFFECTS (MP Restore, Buffs, etc.)

        default:
            show_debug_message("WARNING [scr_UseItem]: Unknown item effect '" + item_effect + "' for item '" + item_key + "'.");
            success = false; // Fail if effect not implemented
            show_popup = false;
            break;
    }

    // 3. Consume Item if successful
    if (success) {
        if (script_exists(scr_RemoveInventoryItem)) {
            var removed = scr_RemoveInventoryItem(item_key, 1);
            if (!removed) { show_debug_message("ERROR [scr_UseItem]: Failed to remove item '" + item_key + "' from inventory (was it already gone?)"); }
        } else { show_debug_message("ERROR [scr_UseItem]: scr_RemoveInventoryItem script missing!"); }
    }

    // 4. Show Popup
    if (show_popup && popup_text != "" && object_exists(obj_popup_damage) && instance_exists(popup_target)) {
        var pop = instance_create_layer(popup_target.x, popup_target.y - 64, "Instances", obj_popup_damage);
        if (pop != noone) { pop.damage_amount = popup_text; pop.text_color = popup_color; }
    }

    show_debug_message("--- scr_UseItem END --- Returning: " + string(success));
    return success; // Return true if item was used successfully (consumes turn)
}