/// @function scr_ProcessDeathIfNecessary(target_inst)
/// @description Checks if target HP is <= 0 and calls cleanup if needed.
/// @param {Id.Instance} target_inst The instance to check.
/// @returns {Bool} True if the target was found dead and processed, false otherwise.

function scr_ProcessDeathIfNecessary(_target_inst) {
    if (!instance_exists(_target_inst)) return false; // Target already gone
    
    if (variable_instance_exists(_target_inst, "data") && is_struct(_target_inst.data) && variable_struct_exists(_target_inst.data, "hp") && _target_inst.data.hp <= 0) {
        
        show_debug_message("!!! Immediate Death Check: " + string(_target_inst) + " has HP <= 0. Processing...");
        
        // Access Battle Manager instance (assuming only one exists)
        if (!instance_exists(obj_battle_manager)) {
             show_debug_message("ERROR [ProcessDeath]: Cannot find obj_battle_manager!");
             instance_destroy(_target_inst); // Destroy anyway as fallback
             return true; 
        }
        var _manager = obj_battle_manager;

        // Grant XP (Copy relevant part from check_win_loss)
        var xp_val = variable_struct_exists(_target_inst.data,"xp_value") ? _target_inst.data.xp_value : (variable_struct_exists(_target_inst.data,"xp") ? _target_inst.data.xp : 0);
        _manager.total_xp_from_battle += xp_val;
        show_debug_message("    -> Granting XP: " + string(xp_val) + ". Total now: " + string(_manager.total_xp_from_battle));

        // Remove from global enemy list (if applicable)
        if (ds_exists(global.battle_enemies, ds_type_list)) {
             var enemy_index = ds_list_find_index(global.battle_enemies, _target_inst);
             if (enemy_index != -1) {
                 ds_list_delete(global.battle_enemies, enemy_index);
                 show_debug_message("    -> Removed from global.battle_enemies.");
             }
        }
        // Remove from global party list (if applicable - usually don't remove players, just mark dead)
        // if (ds_exists(global.battle_party, ds_type_list)) { ... }

        // Remove from manager's combined combatant list
        if (ds_exists(_manager.combatants_all, ds_type_list)) {
            var combatant_index = ds_list_find_index(_manager.combatants_all, _target_inst);
            if (combatant_index != -1) {
                ds_list_delete(_manager.combatants_all, combatant_index);
                show_debug_message("    -> Removed from manager.combatants_all.");
            }
        }
        
        // Remove from status effect map
        if (ds_exists(global.battle_status_effects, ds_type_map)) {
             if (ds_map_exists(global.battle_status_effects, _target_inst.id)) {
                  ds_map_delete(global.battle_status_effects, _target_inst.id);
                  show_debug_message("    -> Removed from global.battle_status_effects map.");
             }
        }

        // TODO: Play death animation / effect here if needed BEFORE destroying instance
        // Example: _target_inst.state = "dying"; return true; // Let animation handle final destroy?
        // For now, destroy immediately:
        instance_destroy(_target_inst);
        show_debug_message("    -> Instance destroyed.");

        // Recalculate turn order display immediately after death
        if (script_exists(scr_CalculateTurnOrderDisplay)) {
            _manager.turnOrderDisplay = scr_CalculateTurnOrderDisplay(_manager.combatants_all, _manager.BASE_TICK_VALUE, _manager.TURN_ORDER_DISPLAY_COUNT);
        }
        
        return true; // Indicate death was processed
    }
    
    return false; // Target is not dead
}