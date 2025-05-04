/// @function scr_SpeedQueue(combatant_list, base_tick_value)
/// @description Calculates the next actor based on speed and turn counters, and advances time.
/// @param {Id.DsList} combatant_list A ds_list containing the instance IDs of all active combatants.
/// @param {Real} base_tick_value The base value used for tick calculations (e.g., 10000).
/// @returns {Struct} A struct containing {actor: instanceId, time_advance: minimum_counter} or {actor: noone, time_advance: 0} if no valid actor found.

function scr_SpeedQueue(_combatant_list, _base_tick_value) {
    var _next_actor = noone;
    var _min_counter = infinity; // Start with infinity to find the minimum

    var _list_size = ds_list_size(_combatant_list);
    if (_list_size == 0) {
        show_debug_message("scr_SpeedQueue: Error - Combatant list is empty.");
        return { actor: noone, time_advance: 0 };
    }

    // --- Find the combatant with the lowest turn counter ---
    for (var i = 0; i < _list_size; i++) {
        var _inst = _combatant_list[| i];
        
        // Validate instance and required variables
        if (!instance_exists(_inst)) continue; // Skip destroyed instances
        if (!variable_instance_exists(_inst, "turnCounter")) continue; // Skip if no turn counter
        if (variable_instance_exists(_inst, "data") && is_struct(_inst.data) && variable_struct_exists(_inst.data, "hp") && _inst.data.hp <= 0) continue; // Skip dead combatants

        if (_inst.turnCounter < _min_counter) {
            _min_counter = _inst.turnCounter;
            _next_actor = _inst;
        }
        // Optional: Add tie-breaking logic here if needed (e.g., prioritize players, higher base speed)
    }

    // Check if we found a valid actor
    if (_next_actor == noone) {
         show_debug_message("scr_SpeedQueue: Error - No valid actor found with a turn counter.");
         // This might happen if all remaining combatants are dead or invalid
         // Or if turnCounters somehow became infinity/NaN
        return { actor: noone, time_advance: 0 };
    }

    // --- Advance time for all combatants ---
    // Important: Do this *after* finding the minimum, otherwise the actor's own counter subtraction affects others
    for (var i = 0; i < _list_size; i++) {
        var _inst = _combatant_list[| i];
         if (instance_exists(_inst) && variable_instance_exists(_inst, "turnCounter")) {
             // Check for potential floating point issues, ensure counter doesn't go vastly negative if multiple hit 0
             _inst.turnCounter = max(0, _inst.turnCounter - _min_counter); 
         }
    }
    
    show_debug_message("scr_SpeedQueue: Next Actor is " + object_get_name(_next_actor.object_index) + "(" + string(_next_actor) + "). Time Advance: " + string(_min_counter));

    // Return the actor and the amount of time that passed
    return { actor: _next_actor, time_advance: _min_counter };
}

/// @function scr_ResetTurnCounter(instance_id, base_tick_value)
/// @description Resets the turn counter and ticks down any status on that instance.
function scr_ResetTurnCounter(_instance_id, _base_tick_value) {
    // ————— Validation —————
    if (!instance_exists(_instance_id)) return false;
    if (!variable_instance_exists(_instance_id, "data")
     || !is_struct(_instance_id.data)
     || !variable_struct_exists(_instance_id.data, "spd")) {
        show_debug_message("scr_ResetTurnCounter: Missing data.spd on " + string(_instance_id));
        return false;
    }
    if (!variable_instance_exists(_instance_id, "turnCounter")) {
        show_debug_message("scr_ResetTurnCounter: Missing turnCounter on " + string(_instance_id));
        return false;
    }

    // ————— Base Reset (with Haste/Slow) —————
    var _spd = max(1, _instance_id.data.spd);
    var _mult = 1.0;
    var st = script_exists(scr_GetStatus) ? scr_GetStatus(_instance_id) : undefined;
    if (is_struct(st)) {
        switch (st.effect) {
            case "haste": _mult = 0.66; break;
            case "slow":  _mult = 1.50; break;
        }
    }
    _instance_id.turnCounter = (_base_tick_value / _spd) * _mult;
    show_debug_message("scr_ResetTurnCounter: " + string(_instance_id)
                     + " → " + string(_instance_id.turnCounter)
                     + " (" + string(_spd) + ", x" + string(_mult) + ")");

    // ————— Tick Down This Instance’s Status —————
    if (variable_global_exists("battle_status_effects")
     && ds_exists(global.battle_status_effects, ds_type_map)
     && ds_map_exists(global.battle_status_effects, _instance_id)) {
        var status = ds_map_find_value(global.battle_status_effects, _instance_id);
        status.duration -= 1;
        if (status.duration <= 0) {
            ds_map_delete(global.battle_status_effects, _instance_id);
            show_debug_message("scr_ResetTurnCounter: Status expired on " + string(_instance_id));
        } else {
            ds_map_replace(global.battle_status_effects, _instance_id, status);
            show_debug_message("scr_ResetTurnCounter: Status '" + status.effect
                             + "' now " + string(status.duration) + " turns on "
                             + string(_instance_id));
        }
    }

    return true;
}




/// @function scr_CalculateTurnOrderDisplay(combatant_list, base_tick_value, count)
/// @description Simulates future turns to generate a turn order display list.
/// @param {Id.DsList} combatant_list The ds_list of active combatant instance IDs.
/// @param {Real} base_tick_value The base value for tick calculations.
/// @param {Integer} count How many turns ahead to predict.
/// @returns {Array<Id.Instance>} An array of instance IDs representing the predicted turn order.

function scr_CalculateTurnOrderDisplay(_combatant_list, _base_tick_value, _count) {
    var _predicted_order = [];
    var _list_size = ds_list_size(_combatant_list);
    if (_list_size == 0) return _predicted_order; // Return empty array if no combatants

    // Create temporary storage for simulated turn counters
    var _temp_counters = ds_map_create(); 
    
    // Populate temporary map with current turn counters
    for (var i = 0; i < _list_size; i++) {
        var _inst = _combatant_list[| i];
        if (instance_exists(_inst) && variable_instance_exists(_inst, "turnCounter")) {
            // Only include valid, alive combatants in simulation
            var _is_alive = true;
            if (variable_instance_exists(_inst, "data") && is_struct(_inst.data) && variable_struct_exists(_inst.data, "hp")) {
                 _is_alive = (_inst.data.hp > 0);
            }
             if (_is_alive) {
                 ds_map_add(_temp_counters, _inst, _inst.turnCounter);
            }
        }
    }
    
    // Simulate N turns
    for (var turn = 0; turn < _count; turn++) {
        var _sim_next_actor = noone;
        var _sim_min_counter = infinity;

        // Find the next actor in the simulation based on temp counters
        var _map_keys = ds_map_keys_to_array(_temp_counters); // Get current instances in the simulation
        var _num_sim_actors = array_length(_map_keys);
        if (_num_sim_actors == 0) break; // Stop if no more actors in simulation

        for (var i = 0; i < _num_sim_actors; i++) {
             var _inst_id = _map_keys[i];
             // Need to double check instance exists *just in case* it got destroyed mid-simulation? Unlikely but safe.
             if (!instance_exists(_inst_id)) continue; 
             
             var _current_sim_counter = _temp_counters[? _inst_id];

             if (_current_sim_counter < _sim_min_counter) {
                 _sim_min_counter = _current_sim_counter;
                 _sim_next_actor = _inst_id;
             }
             // Optional: Tie-breaking for simulation
        }

        if (_sim_next_actor == noone) break; // Stop simulation if no actor found

        // Add the predicted actor to the list
        array_push(_predicted_order, _sim_next_actor);

        // Advance simulated time for all actors in the map
        for (var i = 0; i < _num_sim_actors; i++) {
            var _inst_id = _map_keys[i];
            _temp_counters[? _inst_id] = max(0, _temp_counters[? _inst_id] - _sim_min_counter);
        }
        
        // Reset the simulated counter for the actor who just 'acted'
        // Need speed from the actual instance
        if (instance_exists(_sim_next_actor) && variable_instance_exists(_sim_next_actor, "data") && is_struct(_sim_next_actor.data) && variable_struct_exists(_sim_next_actor.data, "spd")) {
             var _spd = max(1, _sim_next_actor.data.spd);
             // Assume standard action cost for prediction
             _temp_counters[? _sim_next_actor] = _base_tick_value / _spd; 
        } else {
             // If actor became invalid (e.g., destroyed externally during prediction), remove from sim map
             ds_map_delete(_temp_counters, _sim_next_actor); 
        }
    }

    // Clean up temporary map
    ds_map_destroy(_temp_counters);

    // Return the predicted order
    // show_debug_message("scr_CalculateTurnOrderDisplay: Predicted Order: " + string(_predicted_order));
    return _predicted_order;
}