/// @function scr_GetEnemyDataFromName(_obj)
/// @description Returns a data struct for a given enemy object type,
///              including stats, FX, death/corpse sprites, and loot tables.
function scr_GetEnemyDataFromName(_obj) {
    // --- Defaults ---
    var default_fx_sprite     = spr_pow;
    var default_fx_sound      = snd_punch;
    var default_element       = "physical";
    var default_resistances   = {
        physical: 0, fire: 0, ice: 0, lightning: 0,
        poison: 0, holy: 0, dark: 0
    };
    var default_death_anim    = spr_death;
    var default_corpse_sprite = spr_dead;

    // Empty loot tables by default
    var default_drop_table    = [];
    var default_steal_table   = [];

    switch (_obj) {
        // --- Goblin Chief ---
        case obj_enemy_goblin:
            return {
                // Identity
                name               : "Nut Thief Chief",
                sprite_index       : spr_enemy_goblin,
                status             : "none",

                // Stats
                hp                 : 30,
                maxhp              : 30,
                atk                :  6,
                def                :  2,
                matk               :  1,
                mdef               :  1,
                spd                :  5,
                luk                :  3,
                xp                 : 50,

                // Combat FX
                attack_sprite      : spr_pow,
                attack_sound       : snd_punch,
                attack_element     : "physical",
                resistances        : default_resistances,

                // Death & Corpse
                death_anim_sprite  : default_death_anim,
                corpse_sprite      : default_corpse_sprite,

                // Loot
                drop_table         : [
                    { item_key:"potion",   chance:0.30 },
                    { item_key:"antidote", chance:0.10 }
                ],
                steal_table        : [
                    { item_key:"potion",   chance:0.50 }
                ]
            };

        // --- Slime ---
        case obj_enemy_slime:
            return {
                // Identity
                name               : "Green Slime",
                sprite_index       : spr_enemy_slime,
                status             : "none",

                // Stats
                hp                 : 20,
                maxhp              : 20,
                atk                :  4,
                def                :  1,
                matk               :  3,
                mdef               :  5,
                spd                :  3,
                luk                :  1,
                xp                 : 30,

                // Combat FX
                attack_sprite      : spr_pow,
                attack_sound       : snd_punch,
                attack_element     : "physical",
                resistances        : {
                    physical: 0.25, fire:-0.5, ice:0.1,
                    lightning:0, poison:1.0, holy:0, dark:0
                },

                // Death & Corpse
                death_anim_sprite  : default_death_anim,
                corpse_sprite      : default_corpse_sprite,

                // Loot
                drop_table         : [
                    { item_key:"antidote",   chance:0.40 },
                    { item_key:"potion",      chance:0.05 }
                ],
                steal_table        : [
                    { item_key:"bomb",   chance:0.60 }
                ]
            };

        // --- Nut Thief Runner ---
        case obj_enemy_nut_thief:
            return {
                // Identity
                name               : "Nut Thief",
                sprite_index       : spr_enemy_nut_thief_2,
                status             : "none",

                // Stats
                hp                 : 25,
                maxhp              : 25,
                atk                :  5,
                def                :  1,
                matk               :  2,
                mdef               :  2,
                spd                :  7,
                luk                :  4,
                xp                 : 35,

                // Combat FX
                attack_sprite      : spr_pow,
                attack_sound       : snd_punch,
                attack_element     : "physical",
                resistances        : default_resistances,

                // Death & Corpse
                death_anim_sprite  : default_death_anim,
                corpse_sprite      : default_corpse_sprite,

                // Loot
                drop_table         : [
                    { item_key:"potion",   chance:0.20 },
                    { item_key:"bomb", chance:0.50 }
                ],
                steal_table        : [
                    { item_key:"bomb", chance:0.75 }
                ]
            };

        // --- Default Fallback ---
        default:
            return {
                // Identity
                name               : "Unknown",
                sprite_index       : spr_enemy_slime,
                status             : "none",

                // Stats
                hp                 : 10,
                maxhp              : 10,
                atk                :  2,
                def                :  1,
                matk               :  1,
                mdef               :  1,
                spd                :  1,
                luk                :  1,
                xp                 :  5,

                // Combat FX
                attack_sprite      : default_fx_sprite,
                attack_sound       : default_fx_sound,
                attack_element     : default_element,
                resistances        : default_resistances,

                // Death & Corpse
                death_anim_sprite  : default_death_anim,
                corpse_sprite      : default_corpse_sprite,

                // Loot
                drop_table         : default_drop_table,
                steal_table        : default_steal_table
            };
    }
}
