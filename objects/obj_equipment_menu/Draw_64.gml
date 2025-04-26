/// obj_equipment_menu :: Draw GUI Event
/// ---------------------------------------------------------------------------
/// Draws the equipment slots, current gear, character stats, and item selection list.

// --- Safety Checks ---
// Ensure menu_active exists and is true
if (!variable_instance_exists(id, "menu_active") || !menu_active) return;
// Ensure equipment_data struct exists (fetched in Create/Step)
if (!variable_instance_exists(id, "equipment_data") || !is_struct(equipment_data)) {
    // Draw an error message if data is missing
    var _ew = display_get_gui_width();
    var _eh = display_get_gui_height();
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_red);
    // Ensure Font1 exists or use default font
    if (font_exists(Font1)) draw_set_font(Font1);
    draw_set_font(-1); // Reset font
    draw_text(_ew/2, _eh/2, "ERROR:\nEquipment data missing!");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    return;
}
// Ensure menu_state exists
if (!variable_instance_exists(id, "menu_state")) return;


// --- Basic Setup ---
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// --- Font & Alignment ---
// Ensure Font1 exists or use default font
if (font_exists(Font1)) draw_set_font(Font1);
else draw_set_font(-1); // Use default if Font1 is missing

draw_set_valign(fa_top);
draw_set_halign(fa_left);

// --- Colors (Declared WITHOUT 'var' to be accessible where needed) ---
col_text = c_white;
col_label = make_color_rgb(180, 180, 180); // Grey for labels like "Weapon:"
col_selected = c_yellow;
col_stat_increase = c_lime;      // Brighter Green for increases
col_stat_decrease = c_red;       // Red for decreases
col_stat_no_change = c_dkgray;   // Dark Grey if showing no change (optional)

// --- Layout Variables ---
var margin = 16;
var top_y = margin;
var line_h = 24; // Height for each line of text/slot

// Column X positions (Adjust as needed for your font/layout)
var col1_x = margin;                  // Slot names / Item list start
var col2_x = col1_x + 100;            // Equipped item names / Stat diffs start
var col3_x = gui_w / 2 + margin;      // Character Stats Label start
var col4_x = col3_x + 80;             // Character Stats Value start

// --- Calculate Character Stats (Base + Equipment) ---
// IMPORTANT: Calculate this *every frame* using the latest equipment_data
// Ensure equipment_data is valid before calling (checked at the top)
var display_stats = scr_CalculateEquippedStats(equipment_data);
// Safety check if calculation returns invalid
if (!is_struct(display_stats)) {
     show_debug_message("ERROR: scr_CalculateEquippedStats returned invalid data!");
     // Draw error or return
     draw_text(10, 10, "Stat Calculation Error!");
     return;
}


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
    // Highlight based on selection only when Browse slots
    var is_selected_slot = (i == selected_slot && menu_state == EEquipMenuState.BrowseSlots);

    // Draw Slot Label (e.g., "WEAPON:") - Capitalized for clarity
    draw_set_color(is_selected_slot ? col_selected : col_label);
    draw_text(col1_x, row_y, string_upper(slot_name) + ":");

    // Figure out what’s currently equipped in this slot using the calculated 'display_stats'
    var current_item_key = noone;
    // Check 'equipment' struct exists in display_stats and the specific slot exists
    if (variable_struct_exists(display_stats, "equipment") && is_struct(display_stats.equipment)) {
        if (variable_struct_exists(display_stats.equipment, slot_name)) {
            current_item_key = variable_struct_get(display_stats.equipment, slot_name);
        }
    }

    // Get the name of the equipped item
    var item_label = "(none)";
    if (is_string(current_item_key)) {
        var item_info = scr_GetItemData(current_item_key); // Assumes this returns valid data or handles errors
        if (is_struct(item_info) && variable_struct_exists(item_info, "name")) {
            item_label = item_info.name;
        } else {
            item_label = "(invalid item!)"; // Indicates missing item definition
        }
    }

    // Draw Equipped Item Name
    draw_set_color(is_selected_slot ? col_selected : col_text);
    draw_text(col2_x, row_y, item_label);
}

// --- Draw Character Stats ---
var stats_y = top_y; // Align stats with the top slot
// Draw Labels
draw_set_color(col_label);
draw_text(col3_x, stats_y + line_h * 0, "HP");
draw_text(col3_x, stats_y + line_h * 1, "MP");
draw_text(col3_x, stats_y + line_h * 2, "ATK");
draw_text(col3_x, stats_y + line_h * 3, "DEF");
draw_text(col3_x, stats_y + line_h * 4, "MATK");
draw_text(col3_x, stats_y + line_h * 5, "MDEF");
draw_text(col3_x, stats_y + line_h * 6, "SPD");
draw_text(col3_x, stats_y + line_h * 7, "LUK");

// Draw Values using the calculated 'display_stats'
draw_set_color(col_text);
draw_text(col4_x, stats_y + line_h * 0, string(display_stats.hp) + "/" + string(display_stats.maxhp));
draw_text(col4_x, stats_y + line_h * 1, string(display_stats.mp) + "/" + string(display_stats.maxmp));
draw_text(col4_x, stats_y + line_h * 2, string(display_stats.atk));
draw_text(col4_x, stats_y + line_h * 3, string(display_stats.def));
draw_text(col4_x, stats_y + line_h * 4, string(display_stats.matk));
draw_text(col4_x, stats_y + line_h * 5, string(display_stats.mdef));
draw_text(col4_x, stats_y + line_h * 6, string(display_stats.spd));
draw_text(col4_x, stats_y + line_h * 7, string(display_stats.luk));


// --- Draw Item Selection Sub-menu (If Active) ---
if (menu_state == EEquipMenuState.SelectingItem) {
    // Sub-menu positioning and dimensions (adjust as needed)
    var sub_x = col1_x + 10; // Start slightly indented from slot name
    var sub_y = slot_start_y + selected_slot * line_h; // Position near the selected slot vertically
    var sub_item_list_x = sub_x + 10;       // X pos for item names inside the box
    var sub_stat_diff_x = sub_item_list_x + 160; // X pos for stat differences
    var sub_width = sub_stat_diff_x + 80 - sub_x; // Calculate width needed
    // Ensure it doesn't go off screen
    sub_width = min(sub_width, gui_w - sub_x - margin);


    var item_count = array_length(item_submenu_choices);
    // Calculate height based on displayed items, clamp to screen height
    var sub_visible_items = min(item_submenu_display_count, item_count);
    var sub_height = (sub_visible_items + 1) * line_h; // Add space for padding/border/title maybe
    sub_height = min(sub_height, gui_h - sub_y - margin); // Clamp height

    // Adjust vertical position if it goes off bottom of screen
    if (sub_y + sub_height > gui_h - margin) {
        sub_y = gui_h - margin - sub_height;
    }
    // Ensure it doesn't go off top
    sub_y = max(margin, sub_y);


    // Draw sub-menu box background and border
    draw_set_color(c_navy); // Or another background color
    draw_set_alpha(0.9);    // Slightly transparent
    draw_rectangle(sub_x, sub_y, sub_x + sub_width, sub_y + sub_height, false);
    draw_set_alpha(1.0);    // Reset alpha
    draw_set_color(c_white); // Border color
    draw_rectangle(sub_x, sub_y, sub_x + sub_width, sub_y + sub_height, true); // Outline


    // --- Draw Item List within the Sub-menu ---
    var item_list_draw_y = sub_y + (line_h / 2); // Starting Y inside the box (with padding)

    for (var i = 0; i < sub_visible_items; i++) {
        var list_index = item_submenu_scroll_top + i;
        // This check should be redundant if sub_visible_items is calculated correctly, but keep for safety
        if (list_index >= item_count) break;

        var current_draw_y = item_list_draw_y + i * line_h; // Y position for *this specific item line*
        var item_key = item_submenu_choices[list_index];
        var item_list_label = "(Unequip)"; // Default for noone

        // Get item name if it's not 'noone'
        if (is_string(item_key)) {
            var item_info = scr_GetItemData(item_key);
            item_list_label = (is_struct(item_info) && variable_struct_exists(item_info, "name")) ? item_info.name : "(invalid key)";
        }

        // Determine color: yellow if selected, white otherwise
        var is_selected_item = (list_index == item_submenu_selected_index);
        draw_set_color(is_selected_item ? col_selected : col_text);
        // Draw the item name
        draw_text(sub_item_list_x, current_draw_y, item_list_label);


        // --- Draw Stat Differences for the Selected Item ONLY ---
        // <<<< REMOVED INLINE FUNCTION >>>>
        if (is_selected_item && variable_struct_exists(id, "item_submenu_stat_diffs") && is_struct(item_submenu_stat_diffs)) {

            var diff_line = 0; // Track vertical offset for drawing diffs FOR THIS ITEM
            var diff_draw_x = sub_stat_diff_x; // X position for the diff text column
            var diff_base_y = current_draw_y; // Use the Y position of the current item line as base
            var diff_line_h = line_h * 0.75; // Use slightly smaller line height for diffs

            // --- Draw HP Diff ---
            var val_hp = item_submenu_stat_diffs.hp_total ?? 0;
            if (val_hp != 0) {
                var s_hp = val_hp > 0 ? "+" : "";
                var col_hp = val_hp > 0 ? col_stat_increase : col_stat_decrease;
                draw_set_color(col_hp);
                draw_text(diff_draw_x, diff_base_y + diff_line * diff_line_h, "HP " + s_hp + string(val_hp));
                diff_line++;
            }
            // --- Draw MP Diff ---
            var val_mp = item_submenu_stat_diffs.mp_total ?? 0;
             if (val_mp != 0) {
                var s_mp = val_mp > 0 ? "+" : "";
                var col_mp = val_mp > 0 ? col_stat_increase : col_stat_decrease;
                draw_set_color(col_mp);
                draw_text(diff_draw_x, diff_base_y + diff_line * diff_line_h, "MP " + s_mp + string(val_mp));
                diff_line++;
            }
            // --- Draw ATK Diff ---
             var val_atk = item_submenu_stat_diffs.atk ?? 0;
             if (val_atk != 0) {
                var s_atk = val_atk > 0 ? "+" : "";
                var col_atk = val_atk > 0 ? col_stat_increase : col_stat_decrease;
                draw_set_color(col_atk);
                draw_text(diff_draw_x, diff_base_y + diff_line * diff_line_h, "ATK " + s_atk + string(val_atk));
                diff_line++;
            }
            // --- Draw DEF Diff ---
             var val_def = item_submenu_stat_diffs.def ?? 0;
             if (val_def != 0) {
                var s_def = val_def > 0 ? "+" : "";
                var col_def = val_def > 0 ? col_stat_increase : col_stat_decrease;
                draw_set_color(col_def);
                draw_text(diff_draw_x, diff_base_y + diff_line * diff_line_h, "DEF " + s_def + string(val_def));
                diff_line++;
            }
            // --- Draw MATK Diff ---
             var val_matk = item_submenu_stat_diffs.matk ?? 0;
             if (val_matk != 0) {
                var s_matk = val_matk > 0 ? "+" : "";
                var col_matk = val_matk > 0 ? col_stat_increase : col_stat_decrease;
                draw_set_color(col_matk);
                draw_text(diff_draw_x, diff_base_y + diff_line * diff_line_h, "MATK " + s_matk + string(val_matk));
                diff_line++;
            }
            // --- Draw MDEF Diff ---
             var val_mdef = item_submenu_stat_diffs.mdef ?? 0;
             if (val_mdef != 0) {
                var s_mdef = val_mdef > 0 ? "+" : "";
                var col_mdef = val_mdef > 0 ? col_stat_increase : col_stat_decrease;
                draw_set_color(col_mdef);
                draw_text(diff_draw_x, diff_base_y + diff_line * diff_line_h, "MDEF " + s_mdef + string(val_mdef));
                diff_line++;
            }
            // --- Draw SPD Diff ---
             var val_spd = item_submenu_stat_diffs.spd ?? 0;
             if (val_spd != 0) {
                var s_spd = val_spd > 0 ? "+" : "";
                var col_spd = val_spd > 0 ? col_stat_increase : col_stat_decrease;
                draw_set_color(col_spd);
                draw_text(diff_draw_x, diff_base_y + diff_line * diff_line_h, "SPD " + s_spd + string(val_spd));
                diff_line++;
            }
            // --- Draw LUK Diff ---
             var val_luk = item_submenu_stat_diffs.luk ?? 0;
             if (val_luk != 0) {
                var s_luk = val_luk > 0 ? "+" : "";
                var col_luk = val_luk > 0 ? col_stat_increase : col_stat_decrease;
                draw_set_color(col_luk);
                draw_text(diff_draw_x, diff_base_y + diff_line * diff_line_h, "LUK " + s_luk + string(val_luk));
                diff_line++;
            }
             // --- End Drawing Diffs ---
        }
    } // End for loop drawing items

     // --- Draw Scroll Indicators for Item List ---
     var indicator_x = sub_x + sub_width / 2; // Center indicators
     // Draw Up Arrow if not scrolled to the top
     if (item_submenu_scroll_top > 0) {
         draw_set_halign(fa_center);
         draw_set_color(c_aqua); // Or another indicator color
         draw_text(indicator_x, sub_y - line_h * 0.1, "▲"); // Slightly above the box
         draw_set_halign(fa_left); // Reset alignment
     }
     // Draw Down Arrow if not scrolled to the bottom
     if (item_submenu_scroll_top + sub_visible_items < item_count) {
         draw_set_halign(fa_center);
         draw_set_color(c_aqua);
         draw_text(indicator_x, sub_y + sub_height - line_h * 0.6, "▼"); // Slightly below the box bottom
         draw_set_halign(fa_left); // Reset alignment
     }
} // End drawing item selection sub-menu

// --- Footer Controls Help Text ---
var footer_y = gui_h - margin - line_h; // Position at bottom
draw_set_color(c_aqua); // Help text color
draw_set_halign(fa_left);
var help_text = "";
switch(menu_state) {
    case EEquipMenuState.BrowseSlots:
        help_text = "[↑/↓] Slot   [←/→] Char   [Confirm] Select Item   [Cancel] Back";
        break;
    case EEquipMenuState.SelectingItem:
         help_text = "[↑/↓] Item   [Confirm] Equip Item   [Cancel] Back to Slots";
         break;
}
draw_text(margin, footer_y, help_text);

// --- Reset Drawing Settings ---
draw_set_font(-1); // Reset to default font
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1); // Reset alpha just in case