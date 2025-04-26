/// @function scr_GetPlayerData(_char_key)
/// @description Returns a battle struct for the character, reading persistent data
///              from global.party_current_stats map. Includes equipment reference and class.
function scr_GetPlayerData(_char_key) {
    show_debug_message("--- scr_GetPlayerData START for key: " + string(_char_key) + " ---");
    var _base = scr_FetchCharacterInfo(_char_key); // Get base definition (name, class, base stats, sprite)

    // --- Handle missing base data ---
    if (is_undefined(_base)) {
        show_debug_message("scr_GetPlayerData: Base data undefined for " + string(_char_key) + ". Returning fallback.");
        return {
            character_key:_char_key, name:"(Unknown)", class:"(Unknown)", hp:1, maxhp:1, mp:0, maxmp:0,
            atk:1, def:1, matk:1, mdef:1, spd:1, luk:1, level:1, xp:0, xp_require:100, skills:[],
            skill_index:0, item_index:0, equipment:{ weapon:noone, offhand:noone, armor:noone, helm:noone, accessory:noone },
            is_defending:false, status:"none", battle_sprite:undefined
        };
    }

    // --- 1) Get persistent data source (_pers) ALWAYS from the global map ---
    var _pers = undefined; // This will hold the struct reference from the map

    if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) {
         show_debug_message("scr_GetPlayerData: Creating global.party_current_stats map.");
         global.party_current_stats = ds_map_create();
    }

    var saved = ds_map_find_value(global.party_current_stats, _char_key);
    if (is_struct(saved)) {
         show_debug_message("scr_GetPlayerData: Found existing struct in global map for " + string(_char_key));
         _pers = saved; // _pers is the struct from the map
         // Ensure required fields like equipment exist
          if (!variable_struct_exists(_pers, "equipment")) {
             show_debug_message("WARNING: Persistent data for " + _char_key + " missing 'equipment'. Initializing.");
             _pers.equipment = { weapon:noone, offhand:noone, armor:noone, helm:noone, accessory:noone };
          }
          // Could add checks for hp, mp, level etc. here too if needed

    } else {
        // Initialize NEW persistent stats in the map if not found
        show_debug_message("scr_GetPlayerData: Initializing NEW persistent stats in global map for: " + string(_char_key));
        var xp_req = (script_exists(scr_GetXPForLevel)) ? scr_GetXPForLevel(2) : 100;
        var sk = [];
        if (variable_struct_exists(_base, "skills") && is_array(_base.skills)) { /* copy skills */
            for (var i = 0; i < array_length(_base.skills); i++) { if (is_struct(_base.skills[i])) array_push(sk, struct_copy(_base.skills[i])); }
        }
        // Make sure _base stats exist before using them
        var _base_hp = variable_struct_exists(_base, "hp_total") ? _base.hp_total : 1;
        var _base_mp = variable_struct_exists(_base, "mp_total") ? _base.mp_total : 0;
        var _base_atk = variable_struct_exists(_base, "atk") ? _base.atk : 1;
        var _base_def = variable_struct_exists(_base, "def") ? _base.def : 1;
        var _base_matk = variable_struct_exists(_base, "matk") ? _base.matk : 1;
        var _base_mdef = variable_struct_exists(_base, "mdef") ? _base.mdef : 1;
        var _base_spd = variable_struct_exists(_base, "spd") ? _base.spd : 1;
        var _base_luk = variable_struct_exists(_base, "luk") ? _base.luk : 1;

        var new_stats = {
             hp: _base_hp,   maxhp: _base_hp, mp: _base_mp,   maxmp: _base_mp,
             atk:_base_atk,  def:_base_def,  matk:_base_matk, mdef:_base_mdef,
             spd:_base_spd,  luk:_base_luk,  level:1, xp:0, xp_require: xp_req, skills:sk,
             equipment:{ weapon:noone, offhand:noone, armor:noone, helm:noone, accessory:noone }
        };
        ds_map_add(global.party_current_stats, _char_key, new_stats);
        _pers = new_stats; // _pers is the newly created struct
    }

    // --- 2) Build the output struct 'd' using _base and _pers ---
    show_debug_message("scr_GetPlayerData: Building output struct 'd'...");
    var d = {};
    d.character_key = _char_key;
    d.name = variable_struct_exists(_base, "name") ? _base.name : "(Unknown)";
    d.class = variable_struct_exists(_base, "class") ? _base.class : "(Unknown)"; // <<< GET CLASS FROM BASE
    show_debug_message("scr_GetPlayerData: Assigned d.class = " + string(d.class));

    // Copy stats from persistent source (_pers struct), falling back to base if needed
    if (!is_struct(_pers)) { // Safety check
         show_debug_message("ERROR: _pers struct is invalid before copying stats for " + string(_char_key));
         // Assign base stats as fallback
         d.hp = _base.hp_total ?? 1; d.maxhp = _base.hp_total ?? 1; d.mp = _base.mp_total ?? 0; d.maxmp = _base.mp_total ?? 0;
         d.atk = _base.atk ?? 1; d.def = _base.def ?? 1; d.matk = _base.matk ?? 1; d.mdef = _base.mdef ?? 1;
         d.spd = _base.spd ?? 1; d.luk = _base.luk ?? 1; d.level = 1; d.xp = 0;
         d.xp_require = (script_exists(scr_GetXPForLevel)) ? scr_GetXPForLevel(2) : 100;
         d.equipment = { weapon:noone, offhand:noone, armor:noone, helm:noone, accessory:noone };
    } else {
        // Copy stats using the persistent struct _pers
        d.hp    = variable_struct_exists(_pers,"hp")      ? _pers.hp      : (_base.hp_total ?? 1);
        d.maxhp = variable_struct_exists(_pers,"maxhp")   ? _pers.maxhp   : (_base.hp_total ?? 1);
        d.mp    = variable_struct_exists(_pers,"mp")      ? _pers.mp      : (_base.mp_total ?? 0);
        d.maxmp = variable_struct_exists(_pers,"maxmp")   ? _pers.maxmp   : (_base.mp_total ?? 0);
        d.atk   = variable_struct_exists(_pers,"atk")     ? _pers.atk     : (_base.atk ?? 1);
        d.def   = variable_struct_exists(_pers,"def")     ? _pers.def     : (_base.def ?? 1);
        d.matk  = variable_struct_exists(_pers,"matk")    ? _pers.matk    : (_base.matk ?? 1);
        d.mdef  = variable_struct_exists(_pers,"mdef")    ? _pers.mdef    : (_base.mdef ?? 1);
        d.spd   = variable_struct_exists(_pers,"spd")     ? _pers.spd     : (_base.spd ?? 1);
        d.luk   = variable_struct_exists(_pers,"luk")     ? _pers.luk     : (_base.luk ?? 1);
        d.level = variable_struct_exists(_pers,"level")   ? _pers.level   : 1;
        d.xp    = variable_struct_exists(_pers,"xp")      ? _pers.xp      : 0;
        d.xp_require = variable_struct_exists(_pers,"xp_require")? _pers.xp_require: ((script_exists(scr_GetXPForLevel)) ? scr_GetXPForLevel(d.level+1) : 100);

        // Get equipment reference from _pers struct
        if (variable_struct_exists(_pers,"equipment") && is_struct(_pers.equipment)) {
            d.equipment = _pers.equipment; // Pass the reference
            // show_debug_message("scr_GetPlayerData: Assigned equipment reference: " + string(d.equipment));
        } else {
            show_debug_message("scr_GetPlayerData: Equipment struct missing on _pers, assigning default empty.");
            d.equipment = { weapon:noone, offhand:noone, armor:noone, helm:noone, accessory:noone };
            _pers.equipment = d.equipment; // Also create it on the _pers struct
        }
    }

    // --- 3) learned skills (Calculated based on level) ---
     var s = [], cur = d.level;
     if (variable_global_exists("spell_db") && is_struct(global.spell_db) && variable_struct_exists(global.spell_db, "learning_schedule") && ds_exists(global.spell_db.learning_schedule, ds_type_map) && ds_map_exists(global.spell_db.learning_schedule, _char_key)){var sched = ds_map_find_value(global.spell_db.learning_schedule, _char_key);if (ds_exists(sched, ds_type_map)) {for (var L = 1; L <= cur; L++) {var k = string(L);if (ds_map_exists(sched, k)) {var skey = ds_map_find_value(sched, k);if (variable_struct_exists(global.spell_db, skey)) array_push(s, struct_copy(variable_struct_get(global.spell_db, skey)));}}}}
     d.skills       = s;
     d.skill_index = 0;
     d.item_index = 0;

    // --- Other properties ---
    d.is_defending = false;
    d.status       = "none";
    d.battle_sprite = variable_struct_exists(_base, "battle_sprite") ? _base.battle_sprite : undefined;

    show_debug_message("scr_GetPlayerData: Finished building 'd'. Returning struct with class: " + string(d.class));
    return d;
}