/// @function scr_GetWeaponAttackFX(_user_inst)
/// @description Gets the attack sprite, sound, and element based on the user's equipped weapon.
/// @param {Id.Instance} _user_inst The player/ally instance whose weapon to check.
/// @returns {Struct} { sprite: SpriteAsset, sound: SoundAsset, element: String }
function scr_GetWeaponAttackFX(_user_inst) {
    // --- Define Defaults ---
    var _default_sprite = spr_pow;    
    var _default_sound = snd_punch;  
    var _default_element = "physical";

    // --- Validate User ---
    if (!instance_exists(_user_inst) || !variable_instance_exists(_user_inst, "data") || !is_struct(_user_inst.data) || !variable_struct_exists(_user_inst.data, "equipment")) {
        return { sprite: _default_sprite, sound: _default_sound, element: _default_element };
    }
    
    var _equip = _user_inst.data.equipment;
    if (!is_struct(_equip) || !variable_struct_exists(_equip, "weapon")) {
         return { sprite: _default_sprite, sound: _default_sound, element: _default_element };
    }

    var _weapon_key = _equip.weapon; 
    
    // --- Check if a weapon is equipped ---
    if (!is_string(_weapon_key) || _weapon_key == "" || _weapon_key == "-4" || _weapon_key == string(noone)) { 
         return { sprite: _default_sprite, sound: _default_sound, element: _default_element };
    }
    
    // --- Get Weapon Data from Global Item DB ---
    // Robust check: Does the global variable exist AND does it hold a valid map ID?
    if (!variable_global_exists("item_database") || !ds_exists(global.item_database, ds_type_map)) { 
         show_debug_message("ERROR [GetWeaponAttackFX]: global.item_database missing or not a DS Map!");
         return { sprite: _default_sprite, sound: _default_sound, element: _default_element };
    }
    var _item_db = global.item_database; 
    
    var _weapon_data = ds_map_find_value(_item_db, _weapon_key); 
    
    if (!is_struct(_weapon_data)) {
         show_debug_message("Warning [GetWeaponAttackFX]: Weapon data not found for key: " + _weapon_key);
         return { sprite: _default_sprite, sound: _default_sound, element: _default_element };
    }
    
    // --- Extract FX Info (with defaults) ---
    var _sprite = variable_struct_exists(_weapon_data, "attack_sprite") ? _weapon_data.attack_sprite : _default_sprite;
    var _sound = variable_struct_exists(_weapon_data, "attack_sound") ? _weapon_data.attack_sound : _default_sound;
    var _element = variable_struct_exists(_weapon_data, "attack_element") ? _weapon_data.attack_element : _default_element;
    
    // --- Validate Assets ---
    if (!sprite_exists(_sprite)) {
         show_debug_message("Warning [GetWeaponAttackFX]: Sprite " + sprite_get_name(_sprite) + " not found for " + _weapon_key + ". Using default.");
         _sprite = _default_sprite;
    }
     if (!audio_exists(_sound)) {
         // Note: audio_get_name() doesn't exist, use sound asset index directly in message
         show_debug_message("Warning [GetWeaponAttackFX]: Sound Index " + string(_sound) + " not found for " + _weapon_key + ". Using default.");
         _sound = _default_sound;
    }

    return { sprite: _sprite, sound: _sound, element: _element };
}