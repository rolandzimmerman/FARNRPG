/// obj_item_menu_field :: Step Event
/// Handle navigation, selection, use (via stats DS map), and SFX outside battle.

if (!active) return;

// --- INPUT ---
var device  = 0;
var up      = keyboard_check_pressed(vk_up)    || gamepad_button_check_pressed(device, gp_padu);
var down    = keyboard_check_pressed(vk_down)  || gamepad_button_check_pressed(device, gp_padd);
var confirm = keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space) || gamepad_button_check_pressed(device, gp_face1);
var back    = keyboard_check_pressed(vk_escape)|| gamepad_button_check_pressed(device, gp_face2);

switch (menu_state) {

    // ──────────────────────────────────────────────────────────────────────
    case "item_select":
        var count = array_length(usable_items);
        if (count > 0) {
            if (up)   item_index = (item_index - 1 + count) mod count;
            if (down) item_index = (item_index + 1) mod count;

            if (confirm && item_index != -1) {
                var sel  = usable_items[item_index];
                var data = scr_GetItemData(sel.item_key);
                if (!is_struct(data)) {
                    show_debug_message("ERROR: No data for " + sel.item_key);
                } else {
                    var tgt = data.target ?? "none";

                    // --- single-target requires picking a member ---
                    if (tgt == "ally" || tgt == "self") {
                        target_party_index = 0;
                        menu_state = "target_select";

                    // --- apply to all via stats map ---
                    } else if (tgt == "all_allies") {
                        show_debug_message("Using " + sel.item_key + " on ALL allies via stats map");
                        // loop each party key, update its stats struct
                        if (variable_global_exists("party_current_stats")
                         && ds_exists(global.party_current_stats, ds_type_map)) {
                            for (var i = 0; i < array_length(global.party_members); i++) {
                                var key = global.party_members[i];
                                if (ds_map_exists(global.party_current_stats, key)) {
                                    var stats = ds_map_find_value(global.party_current_stats, key);
                                    // only heal_hp here as example; extend for other effects
                                    if (data.effect == "heal_hp"
                                     && variable_struct_exists(stats, "hp")
                                     && variable_struct_exists(stats, "maxhp")) {
                                        var old = stats.hp;
                                        stats.hp = min(stats.maxhp, stats.hp + data.value);
                                        var healed = stats.hp - old;
                                        if (healed > 0) {
                                            // optional: spawn a popup here
                                        }
                                    }
                                }
                            }
                        }
                        // consume one
                        usable_items[item_index].quantity -= 1;
                        if (usable_items[item_index].quantity <= 0) {
                            array_delete(usable_items, item_index, 1);
                            item_index = clamp(item_index, 0, array_length(usable_items) - 1);
                        }
                        // play one SFX for the bulk use
                        audio_play_sound(snd_sfx_heal, 1, false);

                    } else {
                        show_debug_message("Cannot use " + sel.item_key + " on allies outside combat");
                    }
                }
            }
        }

        // back → resume pause menu
        if (back) {
            instance_activate_all();
            if (instance_exists(calling_menu) && variable_instance_exists(calling_menu, "active")) {
                calling_menu.active = true;
            } else if (instance_exists(obj_game_manager)) {
                obj_game_manager.game_state = "playing";
            }
            instance_destroy();
        }
        break;


    // ──────────────────────────────────────────────────────────────────────
    case "target_select":
        var keys  = global.party_members;
        var cnt   = array_length(keys);
        if (cnt <= 0) {
            menu_state = "item_select";
            break;
        }

        // navigation
        target_party_index = clamp(target_party_index, 0, cnt - 1);
        if (up)   target_party_index = (target_party_index - 1 + cnt) mod cnt;
        if (down) target_party_index = (target_party_index + 1) mod cnt;

        // confirm → apply to one
        if (confirm) {
            var sel  = usable_items[item_index];
            var data = scr_GetItemData(sel.item_key);
            var key  = keys[target_party_index];

            var used = false;

            // 1) OUTSIDE COMBAT via stats map
            if (variable_global_exists("party_current_stats")
             && ds_exists(global.party_current_stats, ds_type_map)
             && ds_map_exists(global.party_current_stats, key)) {
                var stats = ds_map_find_value(global.party_current_stats, key);

                switch (data.effect) {
                    case "heal_hp":
                        if (variable_struct_exists(stats, "hp") && variable_struct_exists(stats, "maxhp")) {
                            var old = stats.hp;
                            stats.hp = min(stats.maxhp, stats.hp + data.value);
                            if (stats.hp > old) used = true;
                        }
                        break;
                    case "cure_status":
                        if (variable_struct_exists(stats, "status_effect")
                         && stats.status_effect == data.value) {
                            stats.status_effect = "none";
                            if (variable_struct_exists(stats, "status_duration")) {
                                stats.status_duration = 0;
                            }
                            used = true;
                        }
                        break;
                    // …add more effects as needed…
                }

                if (used) {
                    // consume item
                    scr_RemoveInventoryItem(sel.item_key, 1);
                    // play SFX
                    audio_play_sound(snd_sfx_heal, 1, false);
                }

            // 2) FALLBACK: in-combat instance use
            } else {
                var inst = noone;
                if (variable_global_exists("party_member_instances")
                 && ds_exists(global.party_member_instances, ds_type_map)
                 && ds_map_exists(global.party_member_instances, key)) {
                    inst = ds_map_find_value(global.party_member_instances, key);
                }
                if (instance_exists(inst)) {
                    used = scr_UseItem(calling_menu, data, inst);
                    if (used) {
                        scr_RemoveInventoryItem(sel.item_key, 1);
                        audio_play_sound(snd_sfx_heal, 1, false);
                    }
                } else {
                    show_debug_message("No valid target for " + sel.item_key + " → key=" + key);
                }
            }

            // remove from usable_items if qty hits zero
            if (used) {
                usable_items[item_index].quantity -= 1;
                if (usable_items[item_index].quantity <= 0) {
                    array_delete(usable_items, item_index, 1);
                    item_index = clamp(item_index, 0, array_length(usable_items) - 1);
                }
            }

            // back to list
            menu_state = "item_select";
        }

        // cancel target → back to item_select
        if (back) {
            menu_state = "item_select";
        }
        break;
}
