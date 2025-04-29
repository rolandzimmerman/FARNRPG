/// @function scr_GetWeaponAttackFX(_user_inst)
/// @description Gets the attack sprite, sound, and element based on the user's equipped weapon OR the "unarmed" default.
/// @param {Id.Instance} _user_inst The player/ally instance whose weapon to check.
/// @returns {Struct} { sprite: SpriteAsset, sound: SoundAsset, element: String }
function scr_GetWeaponAttackFX(_user_inst) {
    // --- Define Defaults (Fallback ONLY if "unarmed" entry itself is missing/invalid) ---
    var _fallback_sprite = spr_pow;    
    var _fallback_sound = snd_punch;  
    var _fallback_element = "physical";
    var _default_return = { sprite: _fallback_sprite, sound: _fallback_sound, element: _fallback_element };

    // --- Validate User & Get Equipment ---
    var _weapon_key = noone; // Default to no weapon key
    if (instance_exists(_user_inst) && variable_instance_exists(_user_inst, "data") && is_struct(_user_inst.data) && variable_struct_exists(_user_inst.data, "equipment") && is_struct(_user_inst.data.equipment) && variable_struct_exists(_user_inst.data.equipment, "weapon")) {
        _weapon_key = _user_inst.data.equipment.weapon; 
    } else {
         show_debug_message("Warning [GetWeaponAttackFX]: User instance or data/equipment invalid. Using unarmed.");
         _weapon_key = noone; // Ensure it defaults if user data is bad
    }
    
    // --- Determine Item Key to Look Up ---
    var _lookup_key = "unarmed"; // Default to looking up "unarmed"
    // Check if a valid weapon key string IS equipped
    if (is_string(_weapon_key) && _weapon_key != "" && _weapon_key != "-4" && _weapon_key != string(noone)) { 
         _lookup_key = _weapon_key; // If yes, look up the actual weapon
         show_debug_message(" -> GetWeaponAttackFX: Found equipped weapon key: " + _lookup_key);
    } else {
         show_debug_message(" -> GetWeaponAttackFX: No weapon equipped or key invalid. Looking up 'unarmed'.");
    }
    
    // --- Get Item Data from Global Item DB ---
    if (!variable_global_exists("item_database") || !ds_exists(global.item_database, ds_type_map)) { 
         show_debug_message("ERROR [GetWeaponAttackFX]: global.item_database missing! Returning fallback FX.");
         return _default_return;
    }
    var _item_db = global.item_database; 
    
    var _item_data = ds_map_find_value(_item_db, _lookup_key); 
    
    // --- Check if data for lookup_key was found ---
    if (!is_struct(_item_data)) {
         show_debug_message("Warning [GetWeaponAttackFX]: Item data not found for key: '" + _lookup_key + "'. Returning fallback FX.");
         // If lookup failed even for "unarmed", return the hardcoded fallback
         if (_lookup_key == "unarmed") {
              return _default_return; 
         } else {
              // If specific weapon failed, try getting "unarmed" explicitly as a secondary fallback
              var _unarmed_data = ds_map_find_value(_item_db, "unarmed");
              if (is_struct(_unarmed_data)) {
                   _item_data = _unarmed_data; // Use unarmed data
                   show_debug_message("    -> Using 'unarmed' data as fallback.");
              } else {
                   show_debug_message("    -> ERROR: Specific weapon AND 'unarmed' data missing! Returning hardcoded fallback FX.");
                    return _default_return; // Final fallback
              }
         }
    }
    
    // --- Extract FX Info from the found _item_data (either weapon or unarmed) ---
    var _sprite = variable_struct_get(_item_data, "attack_sprite") ?? _fallback_sprite;
    var _sound = variable_struct_get(_item_data, "attack_sound") ?? _fallback_sound;
    var _element = variable_struct_get(_item_data, "attack_element") ?? _fallback_element;
    
    // --- Validate Assets ---
    if (!sprite_exists(_sprite)) { _sprite = _fallback_sprite; }
    if (!audio_exists(_sound)) { _sound = _fallback_sound; }

    // Return the determined FX info
    return { sprite: _sprite, sound: _sound, element: _element };
}