/// @function scr_UseItem(_user_inst, _item_data, _target_inst)
/// @description Uses an item, applies effect, consumes it.
function scr_UseItem(_user_inst, _item_data, _target_inst) {
    scr_AddBattleLog("--- UseItem START: " + (_item_data.item_key ?? "?") + " by " + string(_user_inst));
    var effect = _item_data.effect;
    scr_AddBattleLog("🔸 Effect type: " + effect);

    var success = false;

    switch (effect) {
        case "heal_hp":
            if (instance_exists(_target_inst)) {
                var td = _target_inst.data;
                var old = td.hp;
                td.hp = min(td.maxhp, td.hp + _item_data.value);
                scr_AddBattleLog("Item heal: " + string(old) + "→" + string(td.hp));
                success = true;
            }
            break;
        case "damage_enemy":
            if (instance_exists(_target_inst)) {
                var td2 = _target_inst.data;
                var dmg = max(1, _item_data.value);
                var oh2 = td2.hp;
                td2.hp = max(0, td2.hp - dmg);
                scr_AddBattleLog("Item dmg: " + string(oh2) + "→" + string(td2.hp));
                success = true;
            }
            break;
        case "cure_status":
            if (instance_exists(_target_inst) && variable_instance_exists(_target_inst,"status_effect")) {
                scr_AddBattleLog("Cure status: " + string(_item_data.value));
                if (_target_inst.status_effect == _item_data.value) {
                    _target_inst.status_effect = "none";
                    scr_AddBattleLog("Cured");
                }
                success = true;
            }
            break;
        default:
            scr_AddBattleLog("Unknown item effect: " + effect);
            success = false;
            break;
    }

    if (success) {
        scr_AddBattleLog("Item used, consuming from inventory");
        if (script_exists(scr_RemoveInventoryItem)) scr_RemoveInventoryItem(_item_data.item_key, 1);
    } else {
        scr_AddBattleLog("Item use failed");
    }

    scr_AddBattleLog("--- UseItem END: " + string(success));
    return success;
}
