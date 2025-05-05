/// @function scr_AddXPToParty(_xp_amount)
/// @description Gives _xp_amount to every living party member via scr_AddXPToCharacter.
function scr_AddXPToParty(_xp_amount) {
    if (!ds_exists(global.battle_party, ds_type_list)) return;
    for (var i = 0; i < ds_list_size(global.battle_party); i++) {
        var inst = global.battle_party[| i];
        if (instance_exists(inst) && variable_instance_exists(inst, "data") && inst.data.hp > 0) {
            scr_AddXPToCharacter(inst.character_key, _xp_amount);
        }
    }
}