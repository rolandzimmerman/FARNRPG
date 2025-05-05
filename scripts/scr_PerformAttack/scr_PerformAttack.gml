/// @function scr_PerformAttack(_attacker_inst, _target_inst)
/// @description Calculates and applies damage for a basic attack, including element/resistance, and logs to the battle log.
function scr_PerformAttack(_attacker_inst, _target_inst) {
    // --- LOG ENTRY ---
    var _attackerName = "Unknown";
    if (instance_exists(_attacker_inst) && variable_instance_exists(_attacker_inst, "data") && is_struct(_attacker_inst.data)) {
        _attackerName = (_attacker_inst.data.name ?? "Unknown");
    }
    var _targetName = "Unknown";
    if (instance_exists(_target_inst) && variable_instance_exists(_target_inst, "data") && is_struct(_target_inst.data)) {
        _targetName = (_target_inst.data.name ?? "Unknown");
    }
    scr_AddBattleLog(_attackerName + " attacked " + _targetName + ".");

    // 1) Validate Attacker & Target
    if (!instance_exists(_attacker_inst) || !variable_instance_exists(_attacker_inst, "data") || !is_struct(_attacker_inst.data)) {
        scr_AddBattleLog("PerformAttack failed: invalid attacker");
        return false;
    }
    if (!instance_exists(_target_inst) || !variable_instance_exists(_target_inst, "data") || !is_struct(_target_inst.data)) {
        scr_AddBattleLog("PerformAttack failed: invalid target");
        return false;
    }
    //scr_AddBattleLog("Validation PASSED");

    // 2) Determine Element FX
    var attack_fx_info = script_exists(scr_GetWeaponAttackFX)
                       ? scr_GetWeaponAttackFX(_attacker_inst)
                       : { sprite: spr_pow, sound: snd_punch, element: "physical" };
    var attack_element = attack_fx_info.element ?? "physical";
    scr_AddBattleLog("Element: " + attack_element);

    // 3) Blind miss check
    var _status = script_exists(scr_GetStatus) ? scr_GetStatus(_attacker_inst) : undefined;
    if (is_struct(_status) && _status.effect == "blind") {
        scr_AddBattleLog(_attackerName + " is blinded, rolling miss chance...");
        if (irandom(99) < 50) {
            scr_AddBattleLog(_attackerName + " missed " + _targetName + " due to blind.");
            return true; // Turn is consumed
        }
        scr_AddBattleLog(_attackerName + " hit despite blind.");
    }

    // 4) Calculate Base Damage
    var atk_stat = _attacker_inst.data.atk ?? 0;
    var def_stat = _target_inst.data.def ?? 0;
    var base_dmg = max(1, atk_stat - def_stat);
    //scr_AddBattleLog("Base Damage: ATK=" + string(atk_stat) + " DEF=" + string(def_stat) + " → " + string(base_dmg));

    // 5) Apply Resistance Multiplier
    var rm = 1.0;
    if (script_exists(GetResistanceMultiplier) && variable_struct_exists(_target_inst.data, "resistances")) {
        rm = GetResistanceMultiplier(_target_inst.data.resistances, attack_element);
    }
    //scr_AddBattleLog("Resistance Mult: " + string(rm));

    // 6) Final Damage and minimum rule
    var final_dmg = floor(base_dmg * rm);
    if (base_dmg >= 1 && rm > 0 && final_dmg < 1) final_dmg = 1;
    //scr_AddBattleLog("Final Damage: " + string(final_dmg));

    // 7) Apply Damage
    var old_hp = _target_inst.data.hp;
    _target_inst.data.hp = max(0, old_hp - final_dmg);
    var dmgDone = old_hp - _target_inst.data.hp;
    scr_AddBattleLog(_attackerName + " did " + string(dmgDone) + " damage to " + _targetName + ".");

    // 8) Death check
    if (script_exists(scr_ProcessDeathIfNecessary)) {
        scr_ProcessDeathIfNecessary(_target_inst);
    }

    return true;
}
