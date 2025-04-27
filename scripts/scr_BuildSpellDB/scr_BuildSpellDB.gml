/// @function scr_BuildSpellDB()
/// @description Returns a struct containing data for all spells
///              and a ds_map for their learning schedules.
/// Call once (e.g. in obj_init.Create) and store to global.spell_db.
function scr_BuildSpellDB() {

    // 1) Spell definitions in a struct
    var _spell_db = {
        fireball: {
            name:            "Fireball",
            cost:             6,
            effect:       "damage_enemy",
            requires_target:  true,
            damage:          18,
            element:        "fire",
            power_stat:    "matk"
        },
        heal: {
            name:            "Heal",
            cost:             5,
            effect:       "heal_hp",
            requires_target:  false,
            heal_amount:     25,
            power_stat:    "matk"
        },
        zap: {
            name:            "Zap",
            cost:             4,
            effect:       "damage_enemy",
            requires_target:  true,
            damage:          15,
            element:     "lightning",
            power_stat:    "matk"
        },
        blind: {
            name:            "Blind",
            cost:             5,
            effect:         "blind",
            requires_target:  true,
            duration:        3
        },
        bind: {
            name:            "Bind",
            cost:             6,
            effect:         "bind",
            requires_target:  true,
            duration:        3
        },
        shame: {
            name:            "Shame",
            cost:             8,
            effect:        "shame",
            requires_target:  true,
            duration:        3
        },
        frostbolt: {
            name:            "Frostbolt",
            cost:             7,
            effect:       "damage_enemy",
            requires_target:  true,
            damage:          20,
            element:         "ice",
            power_stat:    "matk",
            status_effect:  "slow",
            status_chance:   0.3,
            status_duration: 2
        },
        greater_heal: {
            name:            "Greater Heal",
            cost:            15,
            effect:       "heal_hp",
            requires_target:  false,
            heal_amount:     75,
            power_stat:    "matk"
        },

        // === Overdrive Skills ===
        overdrive_strike: {
            name:            "Overdrive Strike",
            cost:             0,
            effect:       "damage_enemy",
            requires_target:  true,
            damage:          100,
            element:      "phys",
            power_stat:    "atk",
            overdrive:      true
        },
        overdrive_heal: {
            name:            "Overdrive Heal",
            cost:             0,
            effect:       "heal_hp",
            requires_target:  false,
            heal_amount:    9999,
            power_stat:    "matk",
            overdrive:      true
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
