/// obj_player :: Create Event
persistent = true;
// === Restore Position if returning from battle ===
if (variable_global_exists("return_x") && variable_global_exists("return_y")) {
    show_debug_message("✅ Restoring player position from global.return_x/y...");
    x = global.return_x;
    y = global.return_y;

    // Prevent reuse after respawn
    global.return_x = undefined;
    global.return_y = undefined;
    global.original_room = undefined;
}

show_debug_message("--- obj_player Create Event RUNNING (Instance ID: " + string(id) + ") ---");

// Movement & world setup
move_speed = 2;
tilemap = layer_tilemap_get_id(layer_get_id("Tiles_Col")); 
if (tilemap == -1) show_debug_message("Warning [obj_player Create]: Collision layer 'Tiles_Col' not found!");
if (script_exists(scr_InitRoomMap)) scr_InitRoomMap();

// === Return from battle positioning ===
if (variable_global_exists("return_x") && variable_global_exists("return_y")) {
    show_debug_message("Restoring player position from return_x/y...");
    x = global.return_x;
    y = global.return_y;

    global.return_x = undefined;
    global.return_y = undefined;
    global.original_room = undefined;
}

// Persistent data setup
if (!variable_instance_exists(id, "persistent_data_initialized")) {
    persistent_data_initialized = true;

    var _hero_key = "hero";
    if (!variable_global_exists("party_members") || !is_array(global.party_members)) {
        global.party_members = [_hero_key];
    } else if (array_get_index(global.party_members, _hero_key) == -1) {
        array_push(global.party_members, _hero_key);
    }

    if (!variable_global_exists("party_current_stats") || !ds_exists(global.party_current_stats, ds_type_map)) {
        global.party_current_stats = ds_map_create();
    }

    var _is_new_game = (variable_global_exists("start_as_new_game")) ? global.start_as_new_game : true;
    if (_is_new_game && !ds_map_exists(global.party_current_stats, _hero_key)) {
        var _base_data = script_exists(scr_FetchCharacterInfo) ? scr_FetchCharacterInfo(_hero_key) : undefined;
        if (!is_struct(_base_data)) {
            _base_data = {
                name:"Hero", class:"Hero",
                hp:40, maxhp:40, mp:20, maxmp:20,
                atk:10, def:5, matk:8, mdef:4, spd:7, luk:5,
                level:1, xp:0, xp_require:100,
                overdrive:0, overdrive_max:100,
                skills:[], 
                equipment:{ weapon:noone, offhand:noone, armor:noone, helm:noone, accessory:noone },
                resistances:{ physical:0 },
                character_key:_hero_key
            };
        }

        var _skills = variable_struct_exists(_base_data, "skills") && is_array(_base_data.skills) ? variable_clone(_base_data.skills, true) : [];
        var _equip = variable_struct_exists(_base_data, "equipment") && is_struct(_base_data.equipment) ? variable_clone(_base_data.equipment, true) : {};
        var _resist = variable_struct_exists(_base_data, "resistances") && is_struct(_base_data.resistances) ? variable_clone(_base_data.resistances, true) : {};

        var _xp_req = script_exists(scr_GetXPForLevel) ? scr_GetXPForLevel(2) : 100;

        var _hero_stats = {
            maxhp: _base_data.maxhp ?? 40,
            maxmp: _base_data.maxmp ?? 20,
            hp: _base_data.maxhp ?? 40,
            mp: _base_data.maxmp ?? 20,
            atk:_base_data.atk, def:_base_data.def, matk:_base_data.matk, mdef:_base_data.mdef,
            spd:_base_data.spd, luk:_base_data.luk,
            level:_base_data.level, xp:_base_data.xp, xp_require:_xp_req,
            skills:_skills,
            equipment:_equip,
            resistances:_resist,
            overdrive:_base_data.overdrive ?? 0,
            overdrive_max:_base_data.overdrive_max ?? 100,
            name:_base_data.name ?? "Hero",
            class:_base_data.class ?? "Adventurer",
            character_key:_hero_key
        };

        ds_map_add(global.party_current_stats, _hero_key, _hero_stats);
    }
}

// Overworld/battle temp vars
combat_state = "idle";
origin_x = x; origin_y = y;
target_for_attack = noone;
attack_fx_sprite = spr_pow;
attack_fx_sound = snd_punch;
attack_animation_finished = false;
stored_action_for_anim = undefined;
sprite_assigned = false;
turnCounter = 0;
attack_anim_speed = 0.5;
idle_sprite = sprite_index;
attack_sprite_asset = -1;
casting_sprite_asset = -1;
item_sprite_asset = -1;
sprite_before_attack = sprite_index;
original_scale = image_xscale;
