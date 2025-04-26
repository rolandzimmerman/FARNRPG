// obj_equipment_menu :: Draw GUI Event

if (!variable_instance_exists(id, "menu_active") || !menu_active) return;
if (!variable_instance_exists(id, "equipment_data") || !is_struct(equipment_data)) { return; }
if (!variable_instance_exists(id, "menu_state")) return;
if (!variable_instance_exists(id, "equipment_slots")) { equipment_slots = [ "weapon", "offhand", "armor", "helm", "accessory" ]; }


var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();


if (font_exists(Font1)) draw_set_font(Font1); else draw_set_font(-1);
draw_set_color(c_white);
draw_set_valign(fa_top);
draw_set_halign(fa_left);


col_stat_increase = c_lime;
col_stat_decrease = c_red;


var margin = 16;
var top_y_start = margin;
var line_h = 28;
var col1_x_def = margin;
var col2_x_def = col1_x_def + 110;
var col3_x_def = (gui_w / 2) + margin;
var col4_x_def = col3_x_def + 90;


var slot_count = array_length(equipment_slots);
var slot_section_h = (slot_count * line_h);
var stats_section_h = (8 * line_h);
var needed_h = max(slot_section_h, stats_section_h) + line_h * 4;
var box_h = min(needed_h, gui_h - margin * 2);
var box_w = gui_w - margin * 2;
var box_x = margin;
var box_y = (gui_h - box_h) / 2;


var display_stats = scr_CalculateEquippedStats(equipment_data);
if (!is_struct(display_stats)) { return; }


draw_set_alpha(0.7); draw_set_color(c_black);
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1.0);


if (sprite_exists(spr_box1)) {
    var _spr_w = sprite_get_width(spr_box1);
    var _spr_h = sprite_get_height(spr_box1);
    if (_spr_w > 0 && _spr_h > 0) {
        var _xscale = box_w / _spr_w;
        var _yscale = box_h / _spr_h;
        draw_sprite_ext(spr_box1, 0, box_x, box_y, _xscale, _yscale, 0, c_white, 1);
    } else {
         draw_set_color(c_navy); draw_rectangle(box_x, box_y, box_x + box_w, box_y + box_h, false);
         draw_set_color(c_white); draw_rectangle(box_x, box_y, box_x + box_w, box_y + box_h, true);
    }
} else {
    draw_set_color(c_navy); draw_rectangle(box_x, box_y, box_x + box_w, box_y + box_h, false);
    draw_set_color(c_white); draw_rectangle(box_x, box_y, box_x + box_w, box_y + box_h, true);
}


var top_y = box_y + margin;
var col1_x = box_x + margin;
var col2_x = col1_x + 110;
var col3_x = box_x + (box_w / 2) + margin;
var col4_x = col3_x + 90;


var char_name = variable_struct_exists(display_stats, "name") ? display_stats.name : "?";
draw_set_halign(fa_center);
draw_set_color(c_white);
draw_text(box_x + box_w / 2, top_y, "Equipment - " + char_name);
top_y += line_h * 1.5;
draw_set_halign(fa_left);


var slot_start_y = top_y;
for (var i = 0; i < slot_count; i++) {
    var row_y = slot_start_y + i * line_h;
    var slot_name = equipment_slots[i];
    var is_selected_slot = (i == selected_slot && menu_state == EEquipMenuState.BrowseSlots);
    var slot_label_text = string_upper(slot_name) + ":";
    if (is_selected_slot) { slot_label_text = "> " + slot_label_text; }
    draw_set_color(c_white);
    draw_text(col1_x, row_y, slot_label_text);

    var current_item_key = noone;
    if (variable_struct_exists(display_stats, "equipment") && is_struct(display_stats.equipment)) {
        if (variable_struct_exists(display_stats.equipment, slot_name)) { current_item_key = variable_struct_get(display_stats.equipment, slot_name); }
    }
    var item_label = "(none)";
    if (is_string(current_item_key)) {
        var item_info = scr_GetItemData(current_item_key);
        if (is_struct(item_info) && variable_struct_exists(item_info, "name")) { item_label = item_info.name; } else { item_label = "(inv!)"; }
    }
    draw_set_color(c_white);
    draw_text(col2_x, row_y, item_label);
}


var stats_y = top_y;
draw_set_color(c_white);
draw_text(col3_x, stats_y + line_h * 0, "HP"); draw_text(col3_x, stats_y + line_h * 1, "MP");
draw_text(col3_x, stats_y + line_h * 2, "ATK"); draw_text(col3_x, stats_y + line_h * 3, "DEF");
draw_text(col3_x, stats_y + line_h * 4, "MATK"); draw_text(col3_x, stats_y + line_h * 5, "MDEF");
draw_text(col3_x, stats_y + line_h * 6, "SPD"); draw_text(col3_x, stats_y + line_h * 7, "LUK");

draw_text(col4_x, stats_y + line_h * 0, string(display_stats.hp) + "/" + string(display_stats.maxhp));
draw_text(col4_x, stats_y + line_h * 1, string(display_stats.mp) + "/" + string(display_stats.maxmp));
draw_text(col4_x, stats_y + line_h * 2, string(display_stats.atk)); draw_text(col4_x, stats_y + line_h * 3, string(display_stats.def));
draw_text(col4_x, stats_y + line_h * 4, string(display_stats.matk)); draw_text(col4_x, stats_y + line_h * 5, string(display_stats.mdef));
draw_text(col4_x, stats_y + line_h * 6, string(display_stats.spd)); draw_text(col4_x, stats_y + line_h * 7, string(display_stats.luk));


if (menu_state == EEquipMenuState.SelectingItem) {
    var sub_x = col1_x + 10; var sub_y = slot_start_y + selected_slot * line_h;
    var sub_item_list_x = sub_x + 10; var sub_stat_diff_x = sub_item_list_x + 160;
    var sub_width = sub_stat_diff_x + 80 - sub_x; sub_width = min(sub_width, gui_w - sub_x - margin);
    var item_count = array_length(item_submenu_choices); var sub_visible_items = min(item_submenu_display_count, item_count);
    var sub_height = (sub_visible_items * line_h) + line_h; sub_height = min(sub_height, gui_h - sub_y - margin);
    if (sub_y + sub_height > gui_h - margin) { sub_y = gui_h - margin - sub_height; } sub_y = max(margin, sub_y);

    if (sprite_exists(spr_box1)) {
        var _spr_w_sub=sprite_get_width(spr_box1); var _spr_h_sub=sprite_get_height(spr_box1);
        if (_spr_w_sub > 0 && _spr_h_sub > 0) {
            var _xscale_sub = sub_width / _spr_w_sub; var _yscale_sub = sub_height / _spr_h_sub;
            draw_sprite_ext(spr_box1, 0, sub_x, sub_y, _xscale_sub, _yscale_sub, 0, c_white, 1);
        } else { /* Fallback Rect */ }
    } else { /* Fallback Rect */ }

    var item_list_draw_y = sub_y + (line_h / 2);
    for (var i = 0; i < sub_visible_items; i++) {
        var list_index = item_submenu_scroll_top + i; if (list_index >= item_count) break;
        var current_draw_y = item_list_draw_y + i * line_h; var item_key = item_submenu_choices[list_index];
        var item_list_label = "(Unequip)"; if (is_string(item_key)) { var info=scr_GetItemData(item_key); item_list_label=(is_struct(info)&&variable_struct_exists(info,"name"))?info.name:"(inv!)"; }
        var is_selected_item = (list_index == item_submenu_selected_index);
        if (is_selected_item) { item_list_label = "> " + item_list_label; }
        draw_set_color(c_white);
        draw_text(sub_item_list_x, current_draw_y, item_list_label);

        if (is_selected_item && variable_struct_exists(id, "item_submenu_stat_diffs") && is_struct(item_submenu_stat_diffs)) {
            var diff_line = 0; var diff_draw_x = sub_stat_diff_x; var diff_base_y = current_draw_y; var diff_line_h = line_h * 0.75;
            draw_set_color(c_white);
            var val_hp = item_submenu_stat_diffs.hp_total ?? 0; if (val_hp != 0) { var s=val_hp > 0?"+":""; draw_text(diff_draw_x,diff_base_y+diff_line*diff_line_h,"HP "+s+string(val_hp)); diff_line++; }
            var val_mp = item_submenu_stat_diffs.mp_total ?? 0; if (val_mp != 0) { var s=val_mp > 0?"+":""; draw_text(diff_draw_x,diff_base_y+diff_line*diff_line_h,"MP "+s+string(val_mp)); diff_line++; }
            var val_atk= item_submenu_stat_diffs.atk ?? 0; if (val_atk!= 0) { var s=val_atk> 0?"+":""; draw_text(diff_draw_x,diff_base_y+diff_line*diff_line_h,"ATK "+s+string(val_atk)); diff_line++; }
            var val_def= item_submenu_stat_diffs.def ?? 0; if (val_def!= 0) { var s=val_def> 0?"+":""; draw_text(diff_draw_x,diff_base_y+diff_line*diff_line_h,"DEF "+s+string(val_def)); diff_line++; }
            var val_matk=item_submenu_stat_diffs.matk ?? 0; if (val_matk!=0) { var s=val_matk>0?"+":""; draw_text(diff_draw_x,diff_base_y+diff_line*diff_line_h,"MATK "+s+string(val_matk)); diff_line++; }
            var val_mdef=item_submenu_stat_diffs.mdef ?? 0; if (val_mdef!=0) { var s=val_mdef>0?"+":""; draw_text(diff_draw_x,diff_base_y+diff_line*diff_line_h,"MDEF "+s+string(val_mdef)); diff_line++; }
            var val_spd= item_submenu_stat_diffs.spd ?? 0; if (val_spd!= 0) { var s=val_spd> 0?"+":""; draw_text(diff_draw_x,diff_base_y+diff_line*diff_line_h,"SPD "+s+string(val_spd)); diff_line++; }
            var val_luk= item_submenu_stat_diffs.luk ?? 0; if (val_luk!= 0) { var s=val_luk> 0?"+":""; draw_text(diff_draw_x,diff_base_y+diff_line*diff_line_h,"LUK "+s+string(val_luk)); diff_line++; }
        }
    }

    var indicator_x = sub_x + sub_width / 2;
    draw_set_color(c_white);
    if (item_submenu_scroll_top > 0) { draw_set_halign(fa_center); draw_text(indicator_x, sub_y - line_h * 0.1, "▲"); draw_set_halign(fa_left); }
    if (item_submenu_scroll_top + sub_visible_items < item_count) { draw_set_halign(fa_center); draw_text(indicator_x, sub_y + sub_height - line_h * 0.6, "▼"); draw_set_halign(fa_left); }
}


var footer_y = box_y + box_h + margin / 2;
footer_y = min(footer_y, gui_h - margin - line_h);
draw_set_halign(fa_left);
var help_text = "";
if (menu_state == EEquipMenuState.BrowseSlots) { help_text = "[↑/↓] Slot   [←/→] Char   [Confirm] Select Item   [Cancel] Back"; }
else if (menu_state == EEquipMenuState.SelectingItem) { help_text = "[↑/↓] Item   [Confirm] Equip Item   [Cancel] Back to Slots"; }
else { help_text = "Unknown State"; }
draw_set_color(c_white);
draw_text(margin, footer_y, help_text);


draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1);