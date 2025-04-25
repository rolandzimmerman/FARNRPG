/// obj_equipment_menu :: STEP EVENT

// only when active
if (!menu_active) exit;

// read input
var up      = keyboard_check_pressed(vk_up)   || gamepad_button_check_pressed(0, gp_padu);
var down    = keyboard_check_pressed(vk_down) || gamepad_button_check_pressed(0, gp_padd);
var confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(0, gp_face1);
var cancel  = keyboard_check_pressed(vk_escape)|| gamepad_button_check_pressed(0, gp_face2);

// B / Esc → back to pause + re-enable player/NPCs
if (cancel) {
    instance_activate_object(obj_pause_menu);
    instance_activate_object(obj_player);
    instance_activate_object(obj_npc_parent);
    instance_destroy();
    exit;
}

// navigate ↑/↓
var cnt = array_length(equipment_slots);
if (up)   selected_slot = (selected_slot - 1 + cnt) mod cnt;
if (down) selected_slot = (selected_slot + 1) mod cnt;

// A / Enter → cycle
if (confirm) {
    var slotname = equipment_slots[selected_slot];
    show_debug_message("Cycling equipment in slot: " + slotname);

    // get persistent stats struct
    var pers;
    if (equipment_character_key == "hero" && instance_exists(obj_player)) {
        pers = obj_player;
    } else {
        pers = ds_map_find_value(global.party_current_stats, equipment_character_key);
    }
    if (!is_struct(pers)) {
        show_debug_message("⚠️ No persistent stats for " + equipment_character_key);
        exit;
    }

    // build candidate list: [ noone ] + all matching in hero’s inventory
    var inv = [];
    if (equipment_character_key == "hero" && instance_exists(obj_player) && is_array(obj_player.inventory)) {
        inv = obj_player.inventory;
    }
    var cand = [ noone ];
    for (var i = 0; i < array_length(inv); i++) {
        var e = inv[i];
        var info = scr_GetItemData(e.item_key);
        if (is_struct(info) && info.type == "equipment" && info.equip_slot == slotname && e.quantity > 0) {
            array_push(cand, e.item_key);
        }
    }

    // find current index
    var cur = variable_struct_exists(pers.equipment, slotname)
            ? variable_struct_get(pers.equipment, slotname)
            : noone;
    var idx = 0;
    for (var j = 0; j < array_length(cand); j++) {
        if (cand[j] == cur) { idx = j; break; }
    }
    idx = (idx + 1) mod array_length(cand);

    // apply new
    var new_key = cand[idx];
    variable_struct_set(pers.equipment,        slotname, new_key);
    variable_struct_set(equipment_data.equipment, slotname, new_key);

    // feedback
    var label = "(none)";
    if (new_key != noone) {
        var info2 = scr_GetItemData(new_key);
        if (is_struct(info2) && variable_struct_exists(info2,"name"))
            label = info2.name;
    }
    show_debug_message(" -> " + slotname + " = " + label);
}
