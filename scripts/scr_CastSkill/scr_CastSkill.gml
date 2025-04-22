/// @function scr_CastSkill(user_id, skill_struct, target_id)
/// @description Executes the effect of a skill. Handles MP cost & applies effects.
/// @param {Id.Instance} user_id The instance ID of the user casting the skill.
/// @param {Struct} skill_struct The struct containing skill data (name, cost, effect, damage, requires_target etc.).
/// @param {Id.Instance} target_id The instance ID of the confirmed target (can be 'noone').

function scr_CastSkill(user, skill, target) { // Renamed arguments for clarity

    // --- 1. Validate input ---
    // Ensure user instance exists and has data
    if (!instance_exists(user) || !variable_instance_exists(user, "data") || !is_struct(user.data)) {
        show_debug_message("❌ scr_CastSkill: Invalid user instance or missing user data struct.");
        return false; // Indicate failure
    }
    // Ensure skill data is a struct
    if (!is_struct(skill)) {
        show_debug_message("❌ scr_CastSkill: Invalid skill data (not a struct).");
        return false; // Indicate failure
    }
    // Ensure required skill properties exist
     if (!variable_struct_exists(skill, "name") || !variable_struct_exists(skill, "cost") || !variable_struct_exists(skill, "effect")) {
         show_debug_message("❌ scr_CastSkill: Skill data missing required fields (name, cost, effect). Struct: " + string(skill));
         return false; // Indicate failure
     }
     // Check target validity *if* skill requires one
     var _needs_target = variable_struct_exists(skill, "requires_target") ? skill.requires_target : true; // Default true if missing?
     if (_needs_target && !instance_exists(target)) {
          show_debug_message("❌ scr_CastSkill: Skill requires target, but target ID " + string(target) + " is invalid or instance destroyed.");
          // Don't deduct MP if target invalid
          return false; // Indicate failure
     }

    var user_data = user.data; // Shortcut

    // --- 2. Check MP cost ---
    if (user_data.mp < skill.cost) {
        show_debug_message("⚠️ Not enough MP for " + skill.name + ". Required: " + string(skill.cost) + ", Have: " + string(user_data.mp));
        // Show message to player
        if (script_exists(scr_dialogue)) { // Use correct script name
            scr_dialogue([{ name:"System", msg:"Not enough MP!" }]);
        }
        return false; // Indicate failure - DO NOT proceed or deduct MP
    }

    // --- 3. Skill Execution Starts ---
    show_debug_message("🌀 Casting Skill: " + skill.name + " | User: " + string(user) + " | Target: " + string(target));

    // --- 4. Spend MP ---
    user_data.mp -= skill.cost;
    user_data.mp = max(0, user_data.mp); // Clamp MP >= 0
    show_debug_message("   -> MP reduced by " + string(skill.cost) + ". Current MP: " + string(user_data.mp));

    // --- 5. Apply skill effect based on the 'effect' string ---
    // Use the passed 'target' argument directly
    switch (skill.effect) {
        case "heal":
            var amount = variable_struct_exists(skill,"heal_amount") ? skill.heal_amount : 20; // Get heal amount from skill or default
            var old_hp = user_data.hp;
            user_data.hp = min(user_data.hp + amount, user_data.maxhp); // Heal caster, clamp to max HP
            var healed_amount = user_data.hp - old_hp;

            // Show healing popup
             if (object_exists(obj_popup_damage)) {
                 var pop = instance_create_layer(user.x, user.y - 64, "Instances", obj_popup_damage); // Use consistent layer
                 if (pop != noone) {pop.damage_amount = "+" + string(healed_amount); pop.text_color = c_lime;}
             }

            show_debug_message("   ✨ Healed self for " + string(healed_amount) + ". HP: " + string(user_data.hp));
            break;

        case "fire":
            // Target validity was already checked if skill requires_target
            if (instance_exists(target) && variable_instance_exists(target, "data") && is_struct(target.data)) {
                var tgt_data = target.data;
                var dmg = variable_struct_exists(skill,"damage") ? skill.damage : 15; // Get damage from skill data or default
                // Add user magic stat? Subtract target resistance?
                // var dmg = max(1, (skill.damage + user_data.magic_attack) - tgt_data.magic_defense); // Example calc

                 // Apply defense if target is defending
                 if (variable_struct_exists(tgt_data, "is_defending") && tgt_data.is_defending) { dmg = floor(dmg/2); }

                 tgt_data.hp = max(0, tgt_data.hp - dmg); // Damage, clamp HP >= 0

                 // Show damage popup
                 if (object_exists(obj_popup_damage)) {
                      var pop = instance_create_layer(target.x, target.y - 64, "Instances", obj_popup_damage); // Use consistent layer
                      if (pop != noone) pop.damage_amount = string(dmg);
                 }

                 show_debug_message("   🔥 Fireball hit target " + string(target) + " for " + string(dmg) + " damage. Target HP: " + string(tgt_data.hp));
            } else {
                 show_debug_message("   ⚠️ Fireball effect failed: Target " + string(target) + " invalid or missing data struct!");
                 // Note: We already checked instance_exists if target required, so this might indicate data struct issue
            }
            break;

        // --- Add cases for other skill effects here ---
        // case "ice": ... break;
        // case "buff_attack": ... break;

        default:
            show_debug_message("⚠️ Unknown skill effect in scr_CastSkill: '" + string(skill.effect) + "'");
            break;
    }

    // --- 6. Return Success ---
    // Let the battle manager handle state transitions
    return true; // Indicate skill was successfully cast (MP spent, effects attempted)
}