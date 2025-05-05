/// @function scr_PerformAttack(_attacker_inst, _target_inst)
/// @description Calculates and applies damage for a basic attack, including element/resistance.
function scr_PerformAttack(_attacker_inst, _target_inst) {
    // --- LOG ENTRY ---
    var _user_name = "INVALID";
    if (instance_exists(_attacker_inst) && variable_instance_exists(_attacker_inst,"data")) {
        _user_name = (_attacker_inst.data.name ?? "??") + " [" + string(_attacker_inst) + "]";
    }
    var _target_name = "INVALID";
    if (instance_exists(_target_inst) && variable_instance_exists(_target_inst,"data")) {
        _target_name = (_target_inst.data.name ?? "??") + " [" + string(_target_inst) + "]";
    }
    scr_AddBattleLog("--- PerformAttack START: " + _user_name + " -> " + _target_name);

    // 1) Validate Attacker & Target
    if (!instance_exists(_attacker_inst) || !variable_instance_exists(_attacker_inst, "data")) {
        scr_AddBattleLog("PerformAttack fail: Invalid Attacker");
        return false;
    }
    if (!instance_exists(_target_inst) || !variable_instance_exists(_target_inst, "data")) {
        scr_AddBattleLog("PerformAttack fail: Invalid Target");
        return false;
    }
    scr_AddBattleLog("Validation PASSED");

    // 2) Determine Element FX
    var attack_fx_info = (script_exists(scr_GetWeaponAttackFX))
                       ? scr_GetWeaponAttackFX(_attacker_inst)
                       : { sprite: spr_pow, sound: snd_punch, element: "physical" };
    var attack_element = attack_fx_info.element;
    scr_AddBattleLog("Element: " + attack_element);

    // 3) Overdrive Gain
    var ad = _attacker_inst.data;
    if (variable_struct_exists(ad,"overdrive")) {
        var beforeOD = ad.overdrive;
        ad.overdrive = min(ad.overdrive + 5, ad.overdrive_max);
        scr_AddBattleLog("OD Gain: " + string(beforeOD) + "→" + string(ad.overdrive));
    }

    // 4) Blind miss check
    var attacker_status = (script_exists(scr_GetStatus)) ? scr_GetStatus(_attacker_inst) : undefined;
    if (is_struct(attacker_status) && attacker_status.effect == "blind") {
        scr_AddBattleLog("Blind check (50%)");
        if (irandom(99) < 50) {
            scr_AddBattleLog("Missed due to Blind");
            return true;
        }
        scr_AddBattleLog("Blind hit");
    }

    // 5) Base Damage
    var atk = _attacker_inst.data.atk;
    var def = _target_inst.data.def;
    var base_dmg = max(1, atk - def);
    scr_AddBattleLog("Base Damage: ATK=" + string(atk) + " DEF=" + string(def) + " → " + string(base_dmg));

    // 6) Resistance Multiplier
    var rm = 1.0;
    if (script_exists(GetResistanceMultiplier)) {
        rm = GetResistanceMultiplier(_target_inst.data.resistances, attack_element);
    }
    scr_AddBattleLog("Resistance Mult: " + string(rm));

    var final_dmg = floor(base_dmg * rm);
    if (base_dmg >= 1 && rm > 0 && final_dmg < 1) final_dmg = 1;
    scr_AddBattleLog("Final Damage: " + string(final_dmg));

    // 7) Apply Damage
    var old_hp = _target_inst.data.hp;
    _target_inst.data.hp = max(0, old_hp - final_dmg);
    scr_AddBattleLog("HP: " + string(old_hp) + "→" + string(_target_inst.data.hp));

    // 8) Popup (omitted actual create code)
    // ...

    // 9) Death check
    if (script_exists(scr_ProcessDeathIfNecessary)) {
        scr_AddBattleLog("Checking death");
        scr_ProcessDeathIfNecessary(_target_inst);
    }

    scr_AddBattleLog("--- PerformAttack END");
    return true;
}
