/// @function scr_CastSkill(user_id, skill_struct, target_id)
/// @description Executes the effect of a skill. Handles MP cost & applies effects. Returns true if action performed, false otherwise.
/// @param {Id.Instance} user_id The instance ID of the user casting the skill (obj_battle_player).
/// @param {Struct} skill_struct The struct containing skill data (name, cost, effect, damage, heal_amount, requires_target etc.).
/// @param {Id.Instance} target_id The instance ID of the confirmed target (can be 'noone').

function scr_CastSkill(user, skill, target) {

    // --- 1. Validate input ---
    if (!instance_exists(user) || !variable_instance_exists(user, "data") || !is_struct(user.data)) { show_debug_message("❌ scr_CastSkill: Invalid user instance or missing user data struct."); return false; }
    if (!is_struct(skill)) { show_debug_message("❌ scr_CastSkill: Invalid skill data (not a struct)."); return false; }
    if (!variable_struct_exists(skill, "name") || !variable_struct_exists(skill, "cost") || !variable_struct_exists(skill, "effect")) { show_debug_message("❌ scr_CastSkill: Skill data missing required fields (name, cost, effect)."); return false; }
    var _needs_target = variable_struct_exists(skill, "requires_target") ? skill.requires_target : true;
    if (_needs_target && !instance_exists(target)) { show_debug_message("❌ scr_CastSkill: Skill requires target, but target ID " + string(target) + " is invalid."); return false; }

    var user_data = user.data; // Caster's battle data

    // --- 2. Check MP cost ---
    if (user_data.mp < skill.cost) {
        show_debug_message("⚠️ Not enough MP for " + skill.name + ".");
        if (script_exists(scr_dialogue)) { create_dialog([{ name:"System", msg:"Not enough MP!" }]); }
        return false; // Indicate failure - DO NOT proceed
    }

    // --- 3. Skill Execution Starts ---
    show_debug_message("🌀 Casting Skill: " + skill.name + " | User: " + string(user) + " | Target: " + string(target));

    // --- 4. Spend MP ---
    user_data.mp -= skill.cost;
    user_data.mp = max(0, user_data.mp);
    show_debug_message("   -> MP reduced by " + string(skill.cost) + ". Current MP: " + string(user_data.mp));

    // --- 5. Apply skill effect ---
    var _effect_applied = false; // Flag to track if an effect happened
    switch (skill.effect) {

        case "heal_hp":
            var _heal_target_inst = user; // Default to self-heal
            // TODO: Add logic here if skills can target other allies
            if (instance_exists(_heal_target_inst) && variable_instance_exists(_heal_target_inst, "data") && is_struct(_heal_target_inst.data)) {
                 var _target_data = _heal_target_inst.data;
                 var amount = variable_struct_exists(skill,"heal_amount") ? skill.heal_amount : 0;
                 if (amount > 0 && variable_struct_exists(_target_data, "hp") && variable_struct_exists(_target_data, "maxhp")) {
                     var old_hp = _target_data.hp;
                     _target_data.hp = min(_target_data.hp + amount, _target_data.maxhp); // Heal, clamp to max HP
                     var healed_amount = _target_data.hp - old_hp;
                     if (object_exists(obj_popup_damage)) { var pop = instance_create_layer(_heal_target_inst.x, _heal_target_inst.y - 64, "Instances", obj_popup_damage); if (pop != noone) {pop.damage_amount = "+" + string(healed_amount); pop.text_color = c_lime;} }
                     show_debug_message("   ✨ Healed target " + string(_heal_target_inst) + " for " + string(healed_amount) + ". HP: " + string(_target_data.hp));
                     _effect_applied = true;
                 } else { show_debug_message("   -> Heal Error: Invalid amount or target missing hp/maxhp."); }
            } else { show_debug_message("   -> Heal Error: Invalid heal target instance or data."); }
            break;

        case "damage_enemy":
            // Target validity was already checked if skill requires_target
            if (instance_exists(target) && variable_instance_exists(target, "data") && is_struct(target.data)) {
                var tgt_data = target.data;
                var dmg = variable_struct_exists(skill,"damage") ? skill.damage : 0; // Get damage from skill data
                // TODO: Add user magic stat? Subtract target resistance? Element check?
                // var dmg = max(1, (skill.damage + user_data.magic_attack) - tgt_data.magic_defense);

                 if (dmg > 0 && variable_struct_exists(tgt_data, "hp")) {
                     // Apply defense if target is defending (unlikely for enemy target on player turn)
                     if (variable_struct_exists(tgt_data, "is_defending") && tgt_data.is_defending) { dmg = floor(dmg/2); }
                     tgt_data.hp = max(0, tgt_data.hp - dmg); // Damage, clamp HP >= 0
                     if (object_exists(obj_popup_damage)) { var pop = instance_create_layer(target.x, target.y - 64, "Instances", obj_popup_damage); if (pop != noone) pop.damage_amount = string(dmg); }
                     show_debug_message("   🔥 Dealt " + string(dmg) + " skill damage to target " + string(target) + ". Target HP: " + string(tgt_data.hp));
                     _effect_applied = true;
                 } else { show_debug_message("   -> Damage Error: Invalid damage value or target missing hp."); }
            } else { show_debug_message("   -> Damage Error: Target " + string(target) + " invalid or missing data struct!"); }
            break;

        // --- Add cases for other skill effects here (cure_status, buff, debuff etc.) ---
        // case "cure_status": ... break;

        default:
            show_debug_message("⚠️ Unknown skill effect in scr_CastSkill: '" + string(skill.effect) + "'");
            // Return true even if effect unknown, as MP was spent (prevents infinite loop)
            _effect_applied = true;
            break;
    }

    // --- 6. Return Success/Failure ---
    // Return true if MP was spent and an effect was at least attempted/processed.
    return _effect_applied;
}