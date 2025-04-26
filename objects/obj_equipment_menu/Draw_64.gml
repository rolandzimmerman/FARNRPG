/// obj_equipment_menu :: Draw GUI Event
/// ---------------------------------------------------------------------------
/// Draws the equipment slots, current gear, character stats, and item selection list.

// --- Safety Checks ---
if (!menu_active) return;
if (!is_struct(equipment_data)) {
    // Draw an error message if data is missing
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_red);
    draw_set_font(Font1); // Assuming Font1 exists
    draw_text(display_get_gui_width()/2, display_get_gui_height()/2, "ERROR:\nEquipment data missing!");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_set_font(-1);
    return;
}

// --- Basic Setup ---
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// --- Dim Background ---
draw_set_color(c_black);
draw_set_alpha(0.7);
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1);

// --- Font & Alignment ---
draw_set_font(Font1); // Use your main menu font
draw_set_valign(fa_top);
draw_set_halign(fa_left);

// --- Colors ---
var col_text = c_white;
var col_label = make_color_rgb(180, 180, 180); // Grey for labels like "Weapon:"
var col_selected = c_yellow;
var col_stat_increase = c_lime;
var col_stat_decrease = c_red;
var col_stat_no_change = c_gray;

// --- Layout Variables ---
var margin = 16;
var top_y = margin;
var line_h = 24; // Height for each line of text/slot

// Column X positions
var col1_x = margin;                  // Slot names / Item list
var col2_x = col1_x + 120;            // Equipped item names / Stat diffs
var col3_x = gui_w / 2 + margin;      // Character Stats Label
var col4_x = col3_x + 100;            // Character Stats Value

// --- Calculate Character Stats (Base + Equipment) ---
// IMPORTANT: Calculate this *every frame* because equipment might change
var display_stats = scr_CalculateEquippedStats(equipment_data); // This function applies bonuses

// --- Header: Character Name ---
var char_name = variable_struct_exists(display_stats, "name") ? display_stats.name : "Unknown";
draw_set_halign(fa_center);
draw_set_color(col_text);
draw_text(gui_w / 2, top_y, "Equipment - " + char_name);
top_y += line_h * 1.5; // Extra space after header

// --- Draw Equipment Slots & Currently Equipped ---
draw_set_halign(fa_left);
var slot_start_y = top_y;
var slot_count = array_length(equipment_slots);

for (var i = 0; i < slot_count; i++) {
    var row_y = slot_start_y + i * line_h;
    var slot_name = equipment_slots[i];
    var is_selected_slot = (i == selected_slot && menu_state == EEquipMenuState.BrowseSlots);

    // Draw Slot Label (e.g., "Weapon:")
    draw_set_color(is_selected_slot ? col_selected : col_label);
    draw_text(col1_x, row_y, string_upper(slot_name) + ":");

    // Figure out what’s currently equipped in this slot
    var current_item_key = noone;
    if (variable_struct_exists(display_stats, "equipment") && is_struct(display_stats.equipment)) {
        if (variable_struct_exists(display_stats.equipment, slot_name)) {
            current_item_key = variable_struct_get(display_stats.equipment, slot_name);
        }
    }

    // Get the name of the equipped item
    var item_label = "(none)";
    if (is_string(current_item_key)) {
        var item_info = scr_GetItemData(current_item_key);
        if (is_struct(item_info) && variable_struct_exists(item_info, "name")) {
            item_label = item_info.name;
        } else {
            item_label = "(invalid item!)"; // Should not happen ideally
        }
    }

    // Draw Equipped Item Name
    draw_set_color(is_selected_slot ? col_selected : col_text);
    draw_text(col2_x, row_y, item_label);
}

// --- Draw Character Stats ---
var stats_y = top_y;
draw_set_color(col_label);
draw_text(col3_x, stats_y, "HP");
draw_text(col3_x, stats_y + line_h * 1, "MP");
draw_text(col3_x, stats_y + line_h * 2, "ATK");
draw_text(col3_x, stats_y + line_h * 3, "DEF");
draw_text(col3_x, stats_y + line_h * 4, "MATK");
draw_text(col3_x, stats_y + line_h * 5, "MDEF");
draw_text(col3_x, stats_y + line_h * 6, "SPD");
draw_text(col3_x, stats_y + line_h * 7, "LUK");

draw_set_color(col_text);
// Use the calculated 'display_stats' which include equipment bonuses
draw_text(col4_x, stats_y, string(display_stats.hp) + "/" + string(display_stats.maxhp));
draw_text(col4_x, stats_y + line_h * 1, string(display_stats.mp) + "/" + string(display_stats.maxmp));
draw_text(col4_x, stats_y + line_h * 2, string(display_stats.atk));
draw_text(col4_x, stats_y + line_h * 3, string(display_stats.def));
draw_text(col4_x, stats_y + line_h * 4, string(display_stats.matk));
draw_text(col4_x, stats_y + line_h * 5, string(display_stats.mdef));
draw_text(col4_x, stats_y + line_h * 6, string(display_stats.spd));
draw_text(col4_x, stats_y + line_h * 7, string(display_stats.luk));


// --- Draw Item Selection Sub-menu (If Active) ---
if (menu_state == EEquipMenuState.SelectingItem) {
    var sub_x = col1_x; // Align with slot names
    var sub_y = slot_start_y + selected_slot * line_h + line_h; // Position below the selected slot
    var sub_width = col4_x + 80 - sub_x; // Make it reasonably wide
    var sub_max_h = (item_submenu_display_count + 1) * line_h; // +1 for title/border

    // Draw sub-menu box (optional background)
    draw_set_color(c_navy);
    draw_set_alpha(0.8);
    draw_rectangle(sub_x - 4, sub_y - 4, sub_x + sub_width + 4, sub_y + sub_max_h + 4, false);
    draw_set_alpha(1.0);
    draw_set_color(c_white);
    draw_rectangle(sub_x - 4, sub_y - 4, sub_x + sub_width + 4, sub_y + sub_max_h + 4, true);


    // --- Draw Item List ---
    var item_list_y = sub_y;
    var item_count = array_length(item_submenu_choices);

    for (var i = 0; i < item_submenu_display_count; i++) {
        var list_index = item_submenu_scroll_top + i;
        if (list_index >= item_count) break; // Don't draw past the end of the list

        var item_key = item_submenu_choices[list_index];
        var item_list_label = "(Unequip)";
        if (is_string(item_key)) {
            var item_info = scr_GetItemData(item_key);
            item_list_label = (is_struct(item_info) && variable_struct_exists(item_info, "name")) ? item_info.name : "(invalid)";
        }

        var is_selected_item = (list_index == item_submenu_selected_index);
        draw_set_color(is_selected_item ? col_selected : col_text);
        draw_text(sub_x, item_list_y + i * line_h, item_list_label);


        // --- Draw Stat Differences for the Selected Item ---
        if (is_selected_item) {
            var diff_x = col2_x + 10; // Position near the item name column
            var diff_y = item_list_y + i * line_h;
            var diff_line = 0;

            var _draw_diff = function(stat_name, value) {
                if (value != 0) {
                     var _s = value > 0 ? "+" : "";
                     var _col = value > 0 ? col_stat_increase : col_stat_decrease;
                     draw_set_color(_col);
                     draw_text(diff_x, diff_y + diff_line * (line_h * 0.8), stat_name + " " + _s + string(value)); // Slightly smaller line height for diffs
                     diff_line++;
                 }
            }

            // Draw only non-zero differences
            _draw_diff("HP",  item_submenu_stat_diffs.hp_total ?? 0);
            _draw_diff("MP",  item_submenu_stat_diffs.mp_total ?? 0);
            _draw_diff("ATK", item_submenu_stat_diffs.atk      ?? 0);
            _draw_diff("DEF", item_submenu_stat_diffs.def      ?? 0);
            _draw_diff("MATK",item_submenu_stat_diffs.matk     ?? 0);
            _draw_diff("MDEF",item_submenu_stat_diffs.mdef     ?? 0);
            _draw_diff("SPD", item_submenu_stat_diffs.spd      ?? 0);
            _draw_diff("LUK", item_submenu_stat_diffs.luk      ?? 0);
        }
    }
     // Draw scroll indicators if needed
     if (item_submenu_scroll_top > 0) {
         draw_set_halign(fa_center);
         draw_set_color(c_aqua);
         draw_text(sub_x + sub_width/2, sub_y - line_h * 0.6, "▲"); // Arrow up
         draw_set_halign(fa_left);
     }
     if (item_submenu_scroll_top + item_submenu_display_count < item_count) {
         draw_set_halign(fa_center);
         draw_set_color(c_aqua);
         draw_text(sub_x + sub_width/2, sub_y + item_submenu_display_count * line_h, "▼"); // Arrow down
          draw_set_halign(fa_left);
     }
} // End drawing item selection sub-menu

// --- Footer Controls Help Text ---
var footer_y = gui_h - margin - line_h;
draw_set_color(c_aqua);
draw_set_halign(fa_left);
var help_text = "";
switch(menu_state) {
    case EEquipMenuState.BrowseSlots:
        help_text = "[↑/↓] Slot   [←/→] Char   [Enter] Select   [Esc] Back";
        break;
    case EEquipMenuState.SelectingItem:
         help_text = "[↑/↓] Item   [Enter] Equip   [Esc] Cancel";
         break;
}
draw_text(margin, footer_y, help_text);

// --- Reset Drawing Settings ---
draw_set_font(-1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1);