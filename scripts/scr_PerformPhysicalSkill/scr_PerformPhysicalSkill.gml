/// @function scr_PerformPhysicalSkill(_user_inst, _skill_struct, _target_inst)
/// @description Damage/effects for a physical skill.
function scr_PerformPhysicalSkill(_user_inst, _skill_struct, _target_inst) {
    var un = (instance_exists(_user_inst) ? _user_inst.data.name : "Invalid");
    var tn = (instance_exists(_target_inst) ? _target_inst.data.name : "Invalid");
    var sn = (_skill_struct.name ?? "Skill");
    scr_AddBattleLog("--- PhysicalSkill START: " + un + " uses " + sn + " on " + tn);

    // 1) Validate
    if (!instance_exists(_user_inst) || !instance_exists(_target_inst) || !is_struct(_skill_struct)) {
        scr_AddBattleLog("PhysicalSkill fail: validation");
        return false;
    }
    scr_AddBattleLog("Validation PASSED");

    // 2) Blind check
    var us = (script_exists(scr_GetStatus)) ? scr_GetStatus(_user_inst) : undefined;
    if (is_struct(us) && us.effect == "blind") {
        scr_AddBattleLog("Blind check for skill");
        if (irandom(99) < 50) {
            scr_AddBattleLog("Skill missed via Blind");
            return true;
        }
        scr_AddBattleLog("Skill hit despite Blind");
    }

    // 3) Damage calc
    var ps = _skill_struct.power_stat ?? "atk";
    var atk = _user_inst.data[ps];
    var def = _target_inst.data.def;
    var base = (_skill_struct.damage ?? 0) + atk - def;
    base = max(1, base);
    scr_AddBattleLog("Skill base dmg: " + string(base));

    var el = _skill_struct.element ?? "physical";
    var rm = 1.0;
    if (script_exists(GetResistanceMultiplier)) rm = GetResistanceMultiplier(_target_inst.data.resistances, el);
    scr_AddBattleLog("Skill resist mult ("+el+"): " + string(rm));

    var fd = floor(base * rm);
    if (base >= 1 && rm > 0 && fd < 1) fd = 1;
    scr_AddBattleLog("Skill final dmg: " + string(fd));

    // 4) Apply
    var oh = _target_inst.data.hp;
    _target_inst.data.hp = max(0, oh - fd);
    scr_AddBattleLog("Skill HP: " + string(oh) + "→" + string(_target_inst.data.hp));

    // 5) Status effect
    if (variable_struct_exists(_skill_struct,"status_effect")) {
        var eff = _skill_struct.status_effect;
        var dur = _skill_struct.status_duration;
        scr_AddBattleLog("Applying status: " + eff);
        if (script_exists(scr_ApplyStatus)) scr_ApplyStatus(_target_inst, eff, dur);
    }

    // 6) Death check
    if (script_exists(scr_ProcessDeathIfNecessary)) {
        scr_AddBattleLog("Death check post-skill");
        scr_ProcessDeathIfNecessary(_target_inst);
    }

    scr_AddBattleLog("--- PhysicalSkill END");
    return true;
}
