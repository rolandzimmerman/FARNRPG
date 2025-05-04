/// @function scr_BuildSpellDB()
/// @description Returns a struct containing data for all spells
///              and a ds_map for their learning schedules.
function scr_BuildSpellDB() {

    // 1) Spell definitions in a struct
    var _spell_db = {
        // --- Offensive Spells ---
        fireball: {
            name:        "Fireball",
            cost:        6,
            effect:      "damage_enemy",
            target_type: "enemy", // <<< MODIFIED
            damage:      18,
            element:     "fire",
            power_stat:  "matk",
            fx_sprite:   spr_fx_magic, // <<< ADDED (Example sprite)
            fx_sound:    snd_sfx_magic     // <<< ADDED (Example sound)
        },
        zap: {
            name:        "Zap",
            cost:        4,
            effect:      "damage_enemy",
            target_type: "enemy", // <<< MODIFIED
            damage:      15,
            element:     "lightning",
            power_stat:  "matk",
            fx_sprite:   spr_fx_magic, // <<< ADDED (Example sprite)
            fx_sound:    snd_sfx_magic     // <<< ADDED (Example sound)
        },
        frostbolt: {
            name:        "Frostbolt",
            cost:        7,
            effect:      "damage_enemy",
            target_type: "enemy", // <<< MODIFIED
            damage:      20,
            element:     "ice",
            power_stat:  "matk",
            status_effect: "slow", status_chance: 0.3, status_duration: 2, // Keep status info
            fx_sprite:   spr_fx_magic, // <<< ADDED (Example sprite)
            fx_sound:    snd_sfx_magic     // <<< ADDED (Example sound)
        },
        // --- Status Effect Spells ---
         blind: {
            name:        "Blind",
            cost:        5,
            effect:      "blind",
            target_type: "enemy", // <<< MODIFIED
            duration:    3,
            fx_sprite:   spr_fx_magic, // <<< ADDED (Example sprite)
            fx_sound:    snd_sfx_magic     // <<< ADDED (Example sound)
        },
         bind: {
            name:        "Bind",
            cost:        6,
            effect:      "bind",
            target_type: "enemy", // <<< MODIFIED
            duration:    3,
            fx_sprite:   spr_fx_magic, // <<< ADDED (Example sprite)
            fx_sound:    snd_sfx_magic     // <<< ADDED (Example sound)
        },
         shame: {
            name:        "Shame",
            cost:        8,
            effect:      "shame",
            target_type: "enemy", // <<< MODIFIED
            duration:    3,
            fx_sprite:   spr_fx_magic, // <<< ADDED (Example sprite)
            fx_sound:    snd_sfx_magic     // <<< ADDED (Example sound)
            // usable_in_field is omitted, treated as false
        },
       // --- Healing / Buff Spells ---
       heal: {
            name:        "Heal",
            cost:        5,
            effect:      "heal_hp",
            target_type: "ally", // <<< MODIFIED (Can target allies)
            heal_amount: 25,
            power_stat:  "matk",
            fx_sprite:   spr_fx_magic, // <<< ADDED (Example sprite)
            fx_sound:    snd_sfx_magic,     // <<< ADDED (Example sound)
            usable_in_field: true // <<< ADDED: Can be used outside battle
        },
        greater_heal: {
            name:        "Greater Heal",
            cost:        15,
            effect:      "heal_hp",
            target_type: "ally", // <<< MODIFIED
            heal_amount: 75,
            power_stat:  "matk",
            fx_sprite:   spr_fx_magic, // <<< ADDED (Example sprite)
            fx_sound:    snd_sfx_magic,     // <<< ADDED (Example sound)
            usable_in_field: true // <<< ADDED: Can be used outside battle
        },
        // === Overdrive Skills ===
        overdrive_strike: {
            name:        "OVERDRIVE STRIKE",  // ← now uppercase
            cost:        0,
            overdrive:   true,
            effect:      "damage_enemy",
            target_type: "enemy",
            damage:      100,
            element:     "physical",
            power_stat:  "atk",
            fx_sprite:   spr_fx_magic,
            fx_sound:    snd_sfx_magic
        },
        overdrive_heal: {
            name:        "OVERDRIVE HEAL",  // ← now uppercase
            cost:        0,
            overdrive:   true,
            effect:      "heal_hp",
            target_type: "ally",
            heal_amount: 9999,
            power_stat:  "matk",
            fx_sprite:   spr_fx_magic,
            fx_sound:    snd_sfx_magic
        }
    };

    // 2) Build a ds_map for learning_schedule
    var sched = ds_map_create();

    // Hero schedule
    var hero_map = ds_map_create();
    ds_map_add(hero_map, "2", "overdrive_strike");
    ds_map_add(hero_map, "3", "greater_heal");
    ds_map_add(hero_map, "5", "frostbolt");
    ds_map_add(sched, "hero", hero_map);

    // Claude schedule
    var claude_map = ds_map_create();
    ds_map_add(claude_map, "2", "overdrive_heal");
    ds_map_add(claude_map, "3", "fireball");
    ds_map_add(claude_map, "4", "bind");
    ds_map_add(claude_map, "6", "heal");
    ds_map_add(sched, "claude", claude_map);

    // 3) Attach it to the struct
    _spell_db.learning_schedule = sched;

    show_debug_message("Spell Database Initialized.");
    return _spell_db;
}
