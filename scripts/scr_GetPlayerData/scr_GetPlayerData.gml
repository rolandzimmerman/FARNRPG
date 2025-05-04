/// @function scr_GetPlayerData(_key)
/// @description Retrieves character data by cloning the base template in scr_BuildCharacterDB,
///              then overlaying any persistent values (HP/MP/Level/XP/Overdrive/Skills).
///              Fully guards against missing keys or missing fields so it never crashes.
function scr_GetPlayerData(_key) {
    show_debug_message("--- scr_GetPlayerData START for key: " + string(_key) + " ---");

    // 1) Make sure our base DB is built
    if (!variable_global_exists("character_db")
     || !ds_exists(global.character_db, ds_type_map)) {
        show_debug_message(" -> Building character database...");
        global.character_db = scr_BuildCharacterDB();
    }
    var db = global.character_db;

    // 2) Validate key
    if (!ds_map_exists(db, _key)) {
        show_debug_message(" ❌ scr_GetPlayerData: Unknown character key '" + string(_key) + "'.");
        return undefined;
    }

    // 3) Clone the base template
    var base = ds_map_find_value(db, _key);
    if (!is_struct(base)) {
        show_debug_message(" ❌ scr_GetPlayerData: Base entry not a struct for '" + string(_key) + "'.");
        return undefined;
    }
    var final_data = variable_clone(base, true);

    // 4) Overlay any persistent stats
    if (variable_global_exists("party_current_stats")
     && ds_exists(global.party_current_stats, ds_type_map)
     && ds_map_exists(global.party_current_stats, _key)) {

        var pers = ds_map_find_value(global.party_current_stats, _key);
        if (is_struct(pers)) {
            show_debug_message(" -> Found persistent data for '" + string(_key) + "'. Overlaying fields...");
            var keys = variable_struct_get_names(pers);
            for (var i = 0; i < array_length(keys); i++) {
                var k = keys[i];
                var v = variable_struct_get(pers, k);
                // deep‐clone each overlayed field
                final_data[$ k] = variable_clone(v, true);
                show_debug_message("    • Overrode '" + k + "' with persistent value");
            }
        }
    }

    // 5) Make absolutely sure final_data is valid
    if (!is_struct(final_data)) {
        show_debug_message(" ❌ scr_GetPlayerData: final_data is invalid after overlay for '" + string(_key) + "'.");
        return undefined;
    }

    // 6) Clamp & fill in any missing fields safely
    final_data.hp             = clamp(variable_struct_exists(final_data, "hp")           ? final_data.hp           : 0,
                                      0,
                                      variable_struct_exists(final_data, "maxhp")        ? final_data.maxhp        : 1);
    final_data.mp             = clamp(variable_struct_exists(final_data, "mp")           ? final_data.mp           : 0,
                                      0,
                                      variable_struct_exists(final_data, "maxmp")        ? final_data.maxmp        : 0);
    final_data.overdrive      = clamp(variable_struct_exists(final_data, "overdrive")    ? final_data.overdrive    : 0,
                                      0,
                                      variable_struct_exists(final_data, "overdrive_max")? final_data.overdrive_max: 1);
    final_data.level          = max(variable_struct_exists(final_data, "level")          ? final_data.level        : 1, 1);
    final_data.xp             = max(variable_struct_exists(final_data, "xp")             ? final_data.xp           : 0, 0);
    final_data.xp_require     = max(variable_struct_exists(final_data, "xp_require")    ? final_data.xp_require   : 0, 0);

    // 7) Final debug with safe string conversions
    var dbg_name   = variable_struct_exists(final_data, "name")            ? final_data.name         : "(no-name)";
    var dbg_lvl    = variable_struct_exists(final_data, "level")           ? final_data.level        : 0;
    var dbg_hp     = variable_struct_exists(final_data, "hp")              ? final_data.hp           : 0;
    var dbg_maxhp  = variable_struct_exists(final_data, "maxhp")           ? final_data.maxhp        : 0;
    var dbg_mp     = variable_struct_exists(final_data, "mp")              ? final_data.mp           : 0;
    var dbg_maxmp  = variable_struct_exists(final_data, "maxmp")           ? final_data.maxmp        : 0;
    var dbg_od     = variable_struct_exists(final_data, "overdrive")       ? final_data.overdrive    : 0;
    var dbg_odmax  = variable_struct_exists(final_data, "overdrive_max")   ? final_data.overdrive_max: 0;
    var dbg_xp     = variable_struct_exists(final_data, "xp")              ? final_data.xp           : 0;
    var dbg_xpreq  = variable_struct_exists(final_data, "xp_require")      ? final_data.xp_require   : 0;

    show_debug_message(" -> scr_GetPlayerData FINAL for " + string(dbg_name)
                    + ": Lvl="    + string(dbg_lvl)
                    + " HP="     + string(dbg_hp)     + "/" + string(dbg_maxhp)
                    + " MP="     + string(dbg_mp)     + "/" + string(dbg_maxmp)
                    + " OD="     + string(dbg_od)     + "/" + string(dbg_odmax)
                    + " XP="     + string(dbg_xp)     + "/" + string(dbg_xpreq)
    );

    return final_data;
}
