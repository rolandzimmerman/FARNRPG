/// @function scr_CastSkill(user_id, skill_struct, target_id)
/// @description Executes the effect of a skill. Handles MP cost & applies effects. Returns true if action performed, false otherwise.
/// @param {Id.Instance} user_id The instance ID of the user casting the skill (obj_battle_player).
/// @param {Struct} skill_struct The struct containing skill data (name, cost, effect, damage, heal_amount, requires_target etc.).
/// @param {Id.Instance} target_id The instance ID of the confirmed target (can be 'noone').

function scr_CastSkill(user, skill, target) {

    // --- 1. Validate input ---
    if (!instance_exists(user) || !variable_instance_exists(user, "data") || !is_struct(user.data)) { return false; }
    if (!is_struct(skill)) { return false; }
    if (!variable_struct_exists(skill, "name") || !variable_struct_exists(skill, "cost") || !variable_struct_exists(skill, "effect")) { return false; }
    var _needs_target = variable_struct_exists(skill, "requires_target") ? skill.requires_target : true;
    if (_needs_target && !instance_exists(target)) { return false; }

    var user_data = user.data; // Caster's battle data

    // --- 2. Check MP cost ---
    if (user_data.mp < skill.cost) { if (script_exists(scr_dialogue)) { create_dialog([{ name:"System", msg:"Not enough MP!" }]); } return false; }

    // --- 3. Skill Execution Starts ---
    show_debug_message("🌀 Casting Skill: " + skill.name + " | User: " + string(user) + " | Target: " + string(target));

    // --- 4. Spend MP ---
    user_data.mp = max(0, user_data.mp - skill.cost);
    show_debug_message("   -> MP reduced by " + string(skill.cost) + ". Current MP: " + string(user_data.mp));

    // --- 5. Apply skill effect ---
    var _effect_applied = false;
    switch (skill.effect) {

        case "heal_hp":
            var _heal_target_inst = user; // Default self-heal
            if (instance_exists(_heal_target_inst) && variable_instance_exists(_heal_target_inst, "data") && is_struct(_heal_target_inst.data)) {
                 var _target_data = _heal_target_inst.data;
                 var amount = variable_struct_exists(skill,"heal_amount") ? skill.heal_amount : 0;
                 // --- Example: Scale healing with MATK ---
                 var caster_matk = variable_struct_exists(user_data, "matk") ? user_data.matk : 1;
                 amount += floor(caster_matk / 2); // Add half MATK to base heal amount (adjust formula as needed)
                 // --- End Example ---
                 if (amount > 0 && variable_struct_exists(_target_data, "hp") && variable_struct_exists(_target_data, "maxhp")) {
                     var old_hp = _target_data.hp; _target_data.hp = min(_target_data.hp + amount, _target_data.maxhp); var healed_amount = _target_data.hp - old_hp;
                     if (object_exists(obj_popup_damage)) { var pop = instance_create_layer(_heal_target_inst.x, _heal_target_inst.y - 64, "Instances", obj_popup_damage); if (pop != noone) {pop.damage_amount = "+" + string(healed_amount); pop.text_color = c_lime;} }
                     show_debug_message("   ✨ Healed target " + string(_heal_target_inst) + " for " + string(healed_amount) + ". HP: " + string(_target_data.hp));
                     _effect_applied = true;
                 }
            }
            break;

        case "damage_enemy":
            if (instance_exists(target) && variable_instance_exists(target, "data") && is_struct(target.data)) {
                var tgt_data = target.data;
                var base_dmg = variable_struct_exists(skill,"damage") ? skill.damage : 0;
                // --- Example: Use MATK and MDEF ---
                var caster_matk = variable_struct_exists(user_data, "matk") ? user_data.matk : 1;
                var target_mdef = variable_struct_exists(tgt_data, "mdef") ? tgt_data.mdef : 0;
                var dmg = max(1, base_dmg + caster_matk - target_mdef); // Simple MATK vs MDEF formula
                // TODO: Add element checks, luck for criticals etc.
                // --- End Example ---

                 if (dmg > 0 && variable_struct_exists(tgt_data, "hp")) {
                     if (variable_struct_exists(tgt_data, "is_defending") && tgt_data.is_defending) { dmg = floor(dmg/2); } // Defend affects magic too? Your choice.
                     tgt_data.hp = max(0, tgt_data.hp - dmg);
                     if (object_exists(obj_popup_damage)) { var pop = instance_create_layer(target.x, target.y - 64, "Instances", obj_popup_damage); if (pop != noone) pop.damage_amount = string(dmg); }
                     show_debug_message("   🔥 Dealt " + string(dmg) + " skill damage to target " + string(target) + ". Target HP: " + string(tgt_data.hp));
                     _effect_applied = true;
                 }
            }
            break;

        // --- Add other effects ---
        // case "inflict_status": ... break;

        default:
            show_debug_message("⚠️ Unknown skill effect: '" + string(skill.effect) + "'");
            _effect_applied = true; // Still count turn
            break;
    }

    // --- 6. Return Success/Failure ---
    return _effect_applied;
}