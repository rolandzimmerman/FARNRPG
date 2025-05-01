/// obj_npc_recruitable_lexy :: User Event 0 (Interaction)
/// Handles recruiting lexy: adds to party list AND initializes persistent stats map entry.

var _char_key = variable_instance_exists(id, "character_key") ? character_key : "lexy"; 
var _can_still_recruit = variable_instance_exists(id, "can_recruit") ? can_recruit : false; 

show_debug_message("Interaction triggered for NPC: " + _char_key + " | Can Recruit: " + string(_can_still_recruit));

if (_can_still_recruit) { 
    var _already_in_party = false;
    if (variable_global_exists("party_members") && is_array(global.party_members)) {
        // Use loop directly to check party membership
        _already_in_party = false; 
        for (var i = 0; i < array_length(global.party_members); i++) {
            if (global.party_members[i] == _char_key) { _already_in_party = true; break; }
        }
    } else { show_debug_message("ERROR: global.party_members missing!"); exit; }

    if (_already_in_party) {
        // Handle already in party case
        show_debug_message("Recruit attempt failed: " + _char_key + " is already in the party.");
        if (variable_instance_exists(id,"dialogue_data_post_recruit")) { dialogue_data = dialogue_data_post_recruit; } 
        else { dialogue_data = [ { name: _char_key, msg: "Ready when you are!" } ]; } 
        can_recruit = false; 
        if(script_exists(create_dialog)) create_dialog(dialogue_data); else show_debug_message("ERROR: create_dialog script missing!");
    } else {
        // --- Add character to party list ---
        show_debug_message("Recruiting " + _char_key + "!");
        array_push(global.party_members, _char_key);
        show_debug_message("Party is now: " + string(global.party_members));

        // --- Initialize persistent stats for this character ---
        if (variable_global_exists("party_current_stats") && ds_exists(global.party_current_stats, ds_type_map)) {
            if (!ds_map_exists(global.party_current_stats, _char_key)) { 
                show_debug_message(" -> Adding initial persistent stats for recruited character: " + _char_key);
                
                var _base_data = script_exists(scr_FetchCharacterInfo) ? scr_FetchCharacterInfo(_char_key) : undefined;
                
                if (is_struct(_base_data)) {
                    // Create initial persistent struct (Level 1, full HP/MP etc.)
                    var _xp_req = (script_exists(scr_GetXPForLevel)) ? scr_GetXPForLevel(2) : 100;
                    var _skills_arr = variable_struct_exists(_base_data, "skills") && is_array(_base_data.skills) ? variable_clone(_base_data.skills, true) : [];
                    var _equip_struct = variable_struct_exists(_base_data, "equipment") && is_struct(_base_data.equipment) ? variable_clone(_base_data.equipment, true) : { weapon:noone, offhand:noone, armor:noone, helm:noone, accessory:noone };
                    var _resists_struct = variable_struct_exists(_base_data, "resistances") && is_struct(_base_data.resistances) ? variable_clone(_base_data.resistances, true) : { physical: 0 };

                    // --- <<< CORRECTED STAT INITIALIZATION >>> ---
                    // Read the names used in scr_BuildCharacterDB (_base_data has hp_total, mp_total)
                    // Assign them to the standard names (hp, maxhp, mp, maxmp) in the new struct
                    var _initial_maxhp = variable_struct_get(_base_data, "hp_total") ?? 35; // Use hp_total from base
                    var _initial_maxmp = variable_struct_get(_base_data, "mp_total") ?? 15; // Use mp_total from base
                    
                    var _initial_stats = {
                        hp:         _initial_maxhp, // Start HP at MaxHP
                        maxhp:      _initial_maxhp, 
                        mp:         _initial_maxmp, // Start MP at MaxMP
                        maxmp:      _initial_maxmp,
                        atk:        variable_struct_get(_base_data, "atk") ?? 8,    
                        def:        variable_struct_get(_base_data, "def") ?? 4, // Corrected lexy's base def
                        matk:       variable_struct_get(_base_data, "matk") ?? 12,   
                        mdef:       variable_struct_get(_base_data, "mdef") ?? 6,
                        spd:        variable_struct_get(_base_data, "spd") ?? 6,     
                        luk:        variable_struct_get(_base_data, "luk") ?? 7,
                        level:      1, xp: 0, xp_require: _xp_req,
                        skills:     _skills_arr, 
                        equipment:  _equip_struct,
                        resistances: _resists_struct, 
                        overdrive:  0, overdrive_max: 100,
                        name:       variable_struct_get(_base_data, "name") ?? _char_key,
                        class:      variable_struct_get(_base_data, "class") ?? "Cleric", 
                        character_key: _char_key
                    };
                    // --- <<< END CORRECTION >>> ---
                     
                    ds_map_add(global.party_current_stats, _char_key, _initial_stats);
                    show_debug_message("    -> Added '" + _char_key + "' to global.party_current_stats map.");
                    try { show_debug_message("    -> Initial Stats Added: " + json_encode(_initial_stats)); } catch(_e){}

                 } else { show_debug_message("ERROR: Could not fetch base data for recruited character '" + _char_key + "'! Cannot add to stats map."); }
            } else { show_debug_message(" -> '" + _char_key + "' already exists in persistent stats map."); }
        } else { show_debug_message("ERROR: global.party_current_stats map missing during recruitment!"); }
       
        // Change NPC state 
        can_recruit = false; 
        // Set dialogue for successful recruitment
        if (variable_instance_exists(id,"dialogue_data_recruit")) { dialogue_data = dialogue_data_recruit; } 
        else { dialogue_data = [ { name: "System", msg: string(_char_key) + " joined the party!" } ]; }
        if(script_exists(create_dialog)) create_dialog(dialogue_data); else show_debug_message("ERROR: create_dialog script missing!");

        // Optional: Change sprite, destroy instance, etc.
        // instance_destroy(); 
    }

} else { // Already recruited
    // Show standard post-recruit dialogue
    if (variable_instance_exists(id,"dialogue_data_post_recruit")) { dialogue_data = dialogue_data_post_recruit; } 
    else if (!variable_instance_exists(id,"dialogue_data")) { dialogue_data = [ { name: _char_key, msg: "Ready when you are!" } ]; } 
    if(script_exists(create_dialog)) create_dialog(dialogue_data); else show_debug_message("ERROR: create_dialog script missing!");
}