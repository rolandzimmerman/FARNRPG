/// obj_equipment_menu :: Step Event
/// ---------------------------------------------------------------------------
/// Handle navigation, party switching, equipping, and closing (resumes game).

// Only run when this menu is active
if (!menu_active) return;

// — INPUT ———————————————————————————————————————————————————————————
var up      = keyboard_check_pressed(vk_up)    || gamepad_button_check_pressed(0, gp_padu);
var down    = keyboard_check_pressed(vk_down)  || gamepad_button_check_pressed(0, gp_padd);
var left    = keyboard_check_pressed(vk_left)  || gamepad_button_check_pressed(0, gp_shoulderl);
var right   = keyboard_check_pressed(vk_right) || gamepad_button_check_pressed(0, gp_shoulderr);
var confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(0, gp_face1);
var back    = keyboard_check_pressed(vk_escape)|| gamepad_button_check_pressed(0, gp_face2);

// — SLOT NAVIGATION —————————————————————————————————————————————————
var slot_count = array_length(equipment_slots);
if (down) selected_slot = (selected_slot + 1) mod slot_count;
if (up)   selected_slot = (selected_slot - 1 + slot_count) mod slot_count;

// — PARTY SWITCHING ———————————————————————————————————————————————
var party_count = array_length(global.party_members);
if (left  && party_count > 1) party_index = (party_index - 1 + party_count) mod party_count;
if (right && party_count > 1) party_index = (party_index + 1) mod party_count;
if (left || right) {
    equipment_character_key = global.party_members[party_index];
    equipment_data         = scr_GetPlayerData(equipment_character_key);
}

// — EQUIP / UNEQUIP ———————————————————————————————————————————————
if (confirm) {
    var slotname = equipment_slots[selected_slot];

    // 1) Get persistent‐stats struct for this character
    var pers;
    if (equipment_character_key == "hero" && instance_exists(obj_player)) {
        pers = obj_player;
    } else {
        pers = ds_map_find_value(global.party_current_stats, equipment_character_key);
    }

    // 2) Build list of valid gear from inventory
    var inv_list = [];
    if (variable_struct_exists(pers, "inventory") && is_array(pers.inventory)) {
        inv_list = pers.inventory;
    } else if (instance_exists(obj_player) && is_array(obj_player.inventory)) {
        inv_list = obj_player.inventory;
    }

    var choices = [ noone ];
    for (var i = 0; i < array_length(inv_list); i++) {
        var entry = inv_list[i];
        var key   = entry.item_key;
        var data  = scr_GetItemData(key);
        if (is_struct(data)
         && variable_struct_exists(data, "equip_slot")
         && data.equip_slot == slotname) {
            array_push(choices, key);
        }
    }

    // 3) Find currently equipped
    var current_key = noone;
    if (variable_struct_exists(pers, "equipment") && is_struct(pers.equipment)) {
        current_key = variable_struct_get(pers.equipment, slotname);
    }

    // 4) Manually find its index in choices
    var idx = 0;
    for (var j = 0; j < array_length(choices); j++) {
        if (choices[j] == current_key) {
            idx = j;
            break;
        }
    }

    // 5) Cycle to next
    var next_key = choices[(idx + 1) mod array_length(choices)];
    if (!variable_struct_exists(pers, "equipment")) pers.equipment = {};
    variable_struct_set(pers.equipment, slotname, next_key);

    // 6) Refresh display
    equipment_data = scr_GetPlayerData(equipment_character_key);
}

// — CLOSE & RESUME GAME —————————————————————————————————————————————
if (back) {
    // 1) Unpause
    if (instance_exists(obj_game_manager)) {
        obj_game_manager.game_state = "playing";
    }

    // 2) Reactivate all gameplay objects
    instance_activate_all();

    // 3) Destroy the pause menu if it exists
    with (obj_pause_menu) instance_destroy();

    // 4) Destroy this equipment menu
    instance_destroy();
    return;
}
