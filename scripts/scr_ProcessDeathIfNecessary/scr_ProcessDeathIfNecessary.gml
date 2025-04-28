/// @function scr_ProcessDeathIfNecessary(target_inst)
/// @description Checks if target HP is <= 0 and calls cleanup if needed. Handles XP gain.
/// @param {Id.Instance} target_inst The instance to check.
/// @returns {Bool} True if the target was found dead and processed, false otherwise.
function scr_ProcessDeathIfNecessary(_target_inst) {
    if (!instance_exists(_target_inst)) return false; 
    
    // Check HP FIRST
    if (!variable_instance_exists(_target_inst, "data") || !is_struct(_target_inst.data) || !variable_struct_exists(_target_inst.data, "hp") || _target_inst.data.hp > 0) {
         return false; // Not dead
    }
       
    show_debug_message("!!! Immediate Death Check: " + string(_target_inst) + " has HP <= 0. Processing...");
    
    // Access Battle Manager instance
    if (!instance_exists(obj_battle_manager)) { 
         show_debug_message("ERROR [ProcessDeath]: Cannot find obj_battle_manager!");
         instance_destroy(_target_inst); 
         return true; 
    }
    var _manager = obj_battle_manager;

    // Grant XP (Only if it's an enemy)
    // Assuming enemies inherit from obj_battle_enemy or similar parent
    if (object_is_ancestor(_target_inst.object_index, obj_battle_enemy)) { // <<<--- ADJUST obj_battle_enemy if needed
        // Use nullish coalescing and struct_exists for safety
        var xp_val = variable_struct_get( _target_inst.data, "xp_value") ?? variable_struct_get( _target_inst.data, "xp") ?? 0; 
        
        // <<< ADDED XP LOGGING >>>
        show_debug_message("    -> Enemy XP Value Found: " + string(xp_val));
        _manager.total_xp_from_battle += xp_val; 
        show_debug_message("    -> Granted XP. Manager total_xp_from_battle now: " + string(_manager.total_xp_from_battle));
        // <<< END LOGGING >>>
    }

    // Remove from global enemy list (if applicable)
    if (ds_exists(global.battle_enemies, ds_type_list)) {
         var enemy_index = ds_list_find_index(global.battle_enemies, _target_inst);
         if (enemy_index != -1) {
             ds_list_delete(global.battle_enemies, enemy_index);
             show_debug_message("    -> Removed from global.battle_enemies.");
         }
    }
    
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

    // Handle death animation state or destroy
    if (variable_instance_exists(_target_inst, "combat_state")) {
         _target_inst.combat_state = "dying"; 
         show_debug_message("    -> Set combat_state to 'dying'. Instance will self-destruct after animation.");
    } else {
        instance_destroy(_target_inst);
        show_debug_message("    -> Instance destroyed immediately (no combat_state found).");
    }

    // Recalculate turn order display immediately
    if (script_exists(scr_CalculateTurnOrderDisplay)) {
        _manager.turnOrderDisplay = scr_CalculateTurnOrderDisplay(_manager.combatants_all, _manager.BASE_TICK_VALUE, _manager.TURN_ORDER_DISPLAY_COUNT);
        show_debug_message("    -> Recalculated turn order display after death.");
    }
    
    return true; // Indicate death was processed
}