/// obj_spell_menu_field :: Draw GUI Event
if (!active) return;

// --- Basic Setup ---
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();
if (font_exists(Font1)) {
    draw_set_font(Font1);
} else {
    draw_set_font(-1);
}
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1.0);

// --- Menu State & Data Checks ---
if (!variable_instance_exists(id, "menu_state")) exit;
if (!variable_instance_exists(id, "character_index")) exit;
if (!variable_instance_exists(id, "spell_index")) exit;
if (!variable_instance_exists(id, "usable_spells")) exit;
if (!variable_instance_exists(id, "selected_caster_key")) exit;
if (menu_state == "target_select_ally" && !variable_instance_exists(id, "target_party_index")) exit;

// --- Dim Background ---
draw_set_alpha(0.7);
draw_set_color(c_black);
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1.0);
draw_set_color(c_white);

// --- Constants ---
var list_items_to_show = 10;
var box_margin         = 64;
var box_width          = 400;
var line_height        = 36;
var pad                = 16;
var title_h            = line_height;
var list_select_color  = c_yellow;
var party_list_keys    = global.party_members ?? [];
var party_count        = array_length(party_list_keys);

// --- Character Selection Header ---
var char_box_h = 60;
var char_box_w = max(box_width, party_count * 150 + pad * 2);
var char_box_x = (gui_w - char_box_w) / 2;
var char_box_y = box_margin;

if (party_count > 0) {
    if (sprite_exists(spr_box1)) {
        draw_sprite_stretched(spr_box1, 0, char_box_x, char_box_y, char_box_w, char_box_h);
    } else {
        draw_set_alpha(0.8);
        draw_set_color(c_black);
        draw_rectangle(char_box_x, char_box_y, char_box_x + char_box_w, char_box_y + char_box_h, false);
        draw_set_alpha(1.0);
    }
    
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    var char_y = char_box_y + char_box_h / 2;
    for (var i = 0; i < party_count; i++) {
        var p_key = party_list_keys[i];
        var p_data = (ds_exists(global.party_current_stats, ds_type_map) && ds_map_exists(global.party_current_stats, p_key))
                   ? ds_map_find_value(global.party_current_stats, p_key)
                   : undefined;
        var display_name = (is_struct(p_data) && variable_struct_exists(p_data, "name"))
                         ? p_data.name
                         : p_key;
        var draw_x = char_box_x + (char_box_w * (i + 0.5) / party_count);
        var text_color = (menu_state == "character_select" && i == character_index)
                       ? list_select_color
                       : c_white;

        if (menu_state == "character_select" && i == character_index) {
            var tw = string_width(display_name);
            draw_set_color(list_select_color);
            draw_rectangle(draw_x - tw/2 - 4, char_y + line_height/2 - 4,
                           draw_x + tw/2 + 4, char_y + line_height/2,
                           true);
        }

        draw_set_color(text_color);
        draw_text(draw_x, char_y, display_name);
    }
}

// --- Draw Spell List or Target List ---
var list_box_w = box_width;
var list_box_x = (gui_w - list_box_w) / 2;
var list_box_y = char_box_y + char_box_h + pad;
var list_start_y = list_box_y + pad + title_h;
var list_x      = list_box_x + pad;
var title_text  = "";

if (menu_state == "spell_select") {
    title_text = (ds_exists(global.party_current_stats, ds_type_map) && ds_map_exists(global.party_current_stats, selected_caster_key))
               ? (ds_map_find_value(global.party_current_stats, selected_caster_key).name ?? selected_caster_key) + " - Spells"
               : "Select Spell";
    var spell_count = array_length(usable_spells);
    var list_h      = (spell_count > 0) ? min(spell_count, list_items_to_show) * line_height : line_height;
    var list_box_h  = title_h + list_h + pad * 2;

    if (sprite_exists(spr_box1)) {
        draw_sprite_stretched(spr_box1, 0, list_box_x, list_box_y, list_box_w, list_box_h);
    }
    draw_set_halign(fa_center);
    draw_text(list_box_x + list_box_w / 2, list_box_y + pad, title_text);
    draw_set_halign(fa_left);

    var current_mp = (ds_exists(global.party_current_stats, ds_type_map) && ds_map_exists(global.party_current_stats, selected_caster_key))
                   ? ds_map_find_value(global.party_current_stats, selected_caster_key).mp
                   : 0;
    var cost_x = list_box_x + list_box_w - pad;

    for (var i = 0; i < min(spell_count, list_items_to_show); i++) {
        var spell_data = usable_spells[i];
        var display_y  = list_start_y + i * line_height;
        var name_text  = spell_data.name ?? "???";
        var cost       = spell_data.cost ?? 0;
        var cost_text  = string(cost) + " MP";
        var can_afford = (current_mp >= cost);
        var color      = can_afford ? c_white : c_gray;

        if (i == spell_index) {
            draw_set_alpha(0.4);
            draw_set_color(list_select_color);
            draw_rectangle(list_box_x + pad/2, display_y - 2,
                           list_box_x + list_box_w - pad/2, display_y + line_height - 2,
                           false);
            draw_set_alpha(1.0);
            color = list_select_color;
        }

        draw_set_color(color);
        draw_text(list_x, display_y, name_text);
        draw_set_halign(fa_right);
        draw_text(cost_x, display_y, cost_text);
        draw_set_halign(fa_left);
    }
}
else if (menu_state == "target_select_ally") {
    title_text = "Select Target";
    var list_h = (party_count > 0) ? min(party_count, list_items_to_show) * line_height : line_height;
    var list_box_h = title_h + list_h + pad * 2;

    if (sprite_exists(spr_box1)) {
        draw_sprite_stretched(spr_box1, 0, list_box_x, list_box_y, list_box_w, list_box_h);
    }
    draw_set_halign(fa_center);
    draw_text(list_box_x + list_box_w / 2, list_box_y + pad, title_text);
    draw_set_halign(fa_left);

    for (var i = 0; i < min(party_count, list_items_to_show); i++) {
        var p_key = party_list_keys[i];
        var p_data = (ds_exists(global.party_current_stats, ds_type_map) && ds_map_exists(global.party_current_stats, p_key))
                   ? ds_map_find_value(global.party_current_stats, p_key)
                   : undefined;
        var display_y   = list_start_y + i * line_height;
        var name_text   = (is_struct(p_data) && variable_struct_exists(p_data, "name")) ? p_data.name : p_key;
        var hpmp_text   = is_struct(p_data) ? "HP " + string(p_data.hp) + "/" + string(p_data.maxhp)
                                           + " MP " + string(p_data.mp) + "/" + string(p_data.maxmp)
                                         : "";
        var valid_color = is_struct(p_data) ? c_white : c_gray;

        if (i == target_party_index) {
            draw_set_alpha(0.4);
            draw_set_color(list_select_color);
            draw_rectangle(list_box_x + pad/2, display_y - 2,
                           list_box_x + list_box_w - pad/2, display_y + line_height - 2,
                           false);
            draw_set_alpha(1.0);
            valid_color = list_select_color;
        }

        draw_set_color(valid_color);
        draw_text(list_x, display_y, name_text);
        draw_set_halign(fa_right);
        draw_text(list_box_x + list_box_w - pad, display_y, hpmp_text);
        draw_set_halign(fa_left);
    }
}

// --- Reset Drawing State ---
draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1.0);
draw_set_color(c_white);
