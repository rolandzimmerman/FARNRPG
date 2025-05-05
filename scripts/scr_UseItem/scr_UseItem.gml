/// @function scr_UseItem(_user_inst, _item_data, _target_inst)
/// @description Uses an item, applies effect, logs to battle log, and returns true if consumed.
function scr_UseItem(_user_inst, _item_data, _target_inst) {
    // Entry log
    //scr_AddBattleLog("--- UseItem START: " + (_item_data.item_key ?? "?") + " by " + string(_user_inst));

    var effect  = _item_data.effect;
    var success = false;

    switch (effect) {
        case "heal_hp":
            if (instance_exists(_target_inst)
             && variable_instance_exists(_target_inst, "data")
             && is_struct(_target_inst.data)) {
                var td      = _target_inst.data;
                if (variable_struct_exists(td, "hp") && variable_struct_exists(td, "maxhp")) {
                    var old_hp = td.hp;
                    td.hp      = min(td.maxhp, td.hp + _item_data.value);
                    var healed = td.hp - old_hp;

                    // NEW LOGGING
                    var userName   = (variable_instance_exists(_user_inst, "data") && is_struct(_user_inst.data) && variable_struct_exists(_user_inst.data, "name"))
                                   ? _user_inst.data.name : "Unknown";
                    var itemName   = (is_struct(_item_data) && variable_struct_exists(_item_data, "name"))
                                   ? _item_data.name : "Item";
                    var targetName = (variable_struct_exists(td, "name"))
                                   ? td.name : "Unknown";

                    scr_AddBattleLog(
                        userName
                      + " used "
                      + itemName
                      + " and healed "
                      + string(healed)
                      + " HP on "
                      + targetName
                      + "."
                    );

                    success = true;
                }
            }
            break;

        case "damage_enemy":
            if (instance_exists(_target_inst)
             && variable_instance_exists(_target_inst, "data")) {
                var td2     = _target_inst.data;
                if (variable_struct_exists(td2, "hp")) {
                    var old_hp2 = td2.hp;
                    var dmg     = _item_data.value;
                    if (variable_struct_exists(td2, "is_defending") && td2.is_defending) {
                        dmg = floor(dmg / 2);
                    }
                    dmg = max(1, dmg);
                    td2.hp = max(0, td2.hp - dmg);
                    var dealt = old_hp2 - td2.hp;

                    // NEW LOGGING
                    var userName   = (variable_instance_exists(_user_inst, "data") && is_struct(_user_inst.data) && variable_struct_exists(_user_inst.data, "name"))
                                   ? _user_inst.data.name : "Unknown";
                    var itemName   = (is_struct(_item_data) && variable_struct_exists(_item_data, "name"))
                                   ? _item_data.name : "Item";
                    var targetName = (variable_struct_exists(td2, "name"))
                                   ? td2.name : "Unknown";

                    scr_AddBattleLog(
                        userName
                      + " used "
                      + itemName
                      + " and dealt "
                      + string(dealt)
                      + " damage to "
                      + targetName
                      + "."
                    );

                    success = true;
                }
            }
            break;

        case "cure_status":
            if (instance_exists(_target_inst)
             && variable_instance_exists(_target_inst, "status_effect")) {
                var status_to_cure = _item_data.value;
                var oldStatus      = _target_inst.status_effect;
                var cured          = false;

                if (oldStatus == status_to_cure) {
                    _target_inst.status_effect = "none";
                    if (variable_instance_exists(_target_inst, "status_duration")) {
                        _target_inst.status_duration = 0;
                    }
                    cured = true;
                }

                // NEW LOGGING
                var userName   = (variable_instance_exists(_user_inst, "data") && is_struct(_user_inst.data) && variable_struct_exists(_user_inst.data, "name"))
                               ? _user_inst.data.name : "Unknown";
                var itemName   = (is_struct(_item_data) && variable_struct_exists(_item_data, "name"))
                               ? _item_data.name : "Item";
                var targetName = (instance_exists(_target_inst) && variable_instance_exists(_target_inst, "data"))
                               ? _target_inst.data.name : "Unknown";

                if (cured) {
                    scr_AddBattleLog(
                        userName
                      + " used "
                      + itemName
                      + " and cured "
                      + string(status_to_cure)
                      + " on "
                      + targetName
                      + "."
                    );
                } else {
                    scr_AddBattleLog(
                        userName
                      + " used "
                      + itemName
                      + " but "
                      + targetName
                      + " was not "
                      + string(status_to_cure)
                      + "."
                    );
                }

                success = true;
            }
            break;

        default:
            // Unknown effect: do nothing
            break;
    }

    return success;
}
