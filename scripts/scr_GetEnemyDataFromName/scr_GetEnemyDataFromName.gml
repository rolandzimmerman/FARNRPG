/// @function scr_GetEnemyDataFromName(_obj)
/// @description Returns a data struct for a given enemy object type, including FX, resistances,
///              and default death/corpse sprites (spr_death/spr_dead).
/// @param {Object} _obj  The enemy object index (e.g. obj_enemy_goblin)
/// @returns {Struct}     The enemy data struct.
function scr_GetEnemyDataFromName(_obj) {
    // Define default values once
    var default_fx_sprite    = spr_pow;
    var default_fx_sound     = snd_punch;
    var default_element      = "physical";
    var default_resistances  = { physical:0, fire:0, ice:0, lightning:0, poison:0, holy:0, dark:0 };

    // Default death + corpse sprites
    var default_death_anim   = spr_death;
    var default_corpse_sprite= spr_dead;

    switch (_obj) {
        case obj_enemy_goblin:
            return {
                name               : "Nut Thief Chief",
                hp                 : 30,   maxhp: 30,
                atk                :  6,   def: 2,
                matk               :  1,   mdef: 1,
                spd                :  5,   luk: 3,
                xp                 : 50,
                sprite_index       : spr_enemy_goblin,
                status             : "none",

                // FX / Resistances
                attack_sprite      : spr_pow,
                attack_sound       : snd_punch,
                attack_element     : "physical",
                resistances        : { physical:0, fire:0, ice:0, lightning:0, poison:0, holy:0, dark:0 },

                // Death animation & corpse
                death_anim_sprite  : default_death_anim,
                corpse_sprite      : default_corpse_sprite
            };

        case obj_enemy_slime:
            return {
                name               : "Slime",
                hp                 : 20,   maxhp: 20,
                atk                :  4,   def: 1,
                matk               :  3,   mdef: 5,
                spd                :  3,   luk: 1,
                xp                 : 30,
                sprite_index       : spr_enemy_slime,
                status             : "none",

                attack_sprite      : spr_pow,
                attack_sound       : snd_punch,
                attack_element     : "physical",
                resistances        : { physical:0.25, fire:-0.5, ice:0.1, lightning:0, poison:1.0, holy:0, dark:0 },

                death_anim_sprite  : default_death_anim,
                corpse_sprite      : default_corpse_sprite
            };

        case obj_enemy_nut_thief:
            return {
                name               : "Nut Thief",
                hp                 : 20,   maxhp: 20,
                atk                :  4,   def: 1,
                matk               :  3,   mdef: 5,
                spd                :  3,   luk: 1,
                xp                 : 30,
                sprite_index       : spr_enemy_nut_thief_2,
                status             : "none",

                attack_sprite      : spr_pow,
                attack_sound       : snd_punch,
                attack_element     : "physical",
                resistances        : { physical:0, fire:0, ice:0, lightning:0, poison:0, holy:0, dark:0 },

                death_anim_sprite  : default_death_anim,
                corpse_sprite      : default_corpse_sprite
            };

        // Add other specific enemies here...

        default:
            return {
                name               : "Unknown",
                hp                 : 10,   maxhp: 10,
                atk                :  2,   def: 1,
                matk               :  1,   mdef: 1,
                spd                :  1,   luk: 1,
                xp                 :  5,
                sprite_index       : spr_enemy_slime,
                status             : "none",

                attack_sprite      : default_fx_sprite,
                attack_sound       : default_fx_sound,
                attack_element     : default_element,
                resistances        : default_resistances,

                death_anim_sprite  : default_death_anim,
                corpse_sprite      : default_corpse_sprite
            };
    }
}
