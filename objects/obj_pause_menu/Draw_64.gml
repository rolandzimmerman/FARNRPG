/// ===========================================================================
/// OBJECT: obj_pause_menu :: DRAW GUI
/// ===========================================================================

/// @description Draw the pause menu interface

var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// Always draw the dim background when the pause menu exists
draw_set_color(c_black);
draw_set_alpha(0.7);
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1.0);

// ONLY draw the menu box and options if no submenu (like the equipment menu) is open
if (!instance_exists(obj_equipment_menu)) { // <-- Hides pause menu content when equipment menu is open
    var box_width = 240;
    var box_lines = menu_item_count + 1;
    var line_height = 25;
    var box_padding = 15;
    var box_height = (box_lines * line_height) + (box_padding * 2);
    var box_x = (gui_w - box_width) / 2;
    var box_y = (gui_h - box_height) / 2;

    // Draw the menu box
    draw_set_color(c_navy);
    draw_rectangle(box_x, box_y, box_x + box_width, box_y + box_height, false);
    draw_set_color(c_white);
    draw_rectangle(box_x, box_y, box_x + box_width, box_y + box_height, true);

    // Draw the "Paused" title
    draw_set_font(Font1); // Make sure Font1 exists
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_text(box_x + box_width / 2, box_y + box_padding, "Paused");

    // Draw the menu options
    draw_set_halign(fa_left);
    var text_x = box_x + box_padding;
    var text_y_start = box_y + box_padding + line_height;

    for (var i = 0; i < menu_item_count; i++) {
        var _option_text = menu_options[i];
        var _text_color = c_gray;
        if (i == menu_index) {
            _text_color = c_yellow;
            _option_text = "> " + _option_text + " <";
        }
        draw_set_color(_text_color);
        draw_text(text_x, text_y_start + (i * line_height), _option_text);
    }
} // End of check for no submenu

// --- RESET DRAW SETTINGS ---
// Always reset draw settings regardless of whether the box was drawn
draw_set_font(-1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);