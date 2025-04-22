/// @description Draw the pause menu interface

// --- Basic Setup ---
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// --- Dim Background ---
draw_set_color(c_black);
draw_set_alpha(0.7); // Adjust transparency
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1.0); // Reset alpha

// --- Menu Box ---
var box_width = 240;
var box_lines = menu_item_count + 1; // Lines for options + title
var line_height = 25; // Adjust based on font size
var box_padding = 15;
var box_height = (box_lines * line_height) + (box_padding * 2);
var box_x = (gui_w - box_width) / 2;
var box_y = (gui_h - box_height) / 2;

// Draw box background (optional: use a sprite)
draw_set_color(c_navy); // Example color
draw_rectangle(box_x, box_y, box_x + box_width, box_y + box_height, false);
// Draw box border
draw_set_color(c_white);
draw_rectangle(box_x, box_y, box_x + box_width, box_y + box_height, true);


// --- Draw Text ---
draw_set_font(Font1); // <<< SET YOUR MENU FONT HERE
draw_set_halign(fa_center);
draw_set_valign(fa_top);

// Title
draw_set_color(c_white);
draw_text(box_x + box_width / 2, box_y + box_padding, "Paused");

// Options
draw_set_halign(fa_left);
var text_x = box_x + box_padding;
var text_y_start = box_y + box_padding + line_height; // Start below title

for (var i = 0; i < menu_item_count; i++) {
    var _option_text = menu_options[i];
    var _text_color = c_gray; // Default color for non-selected items

    if (i == menu_index) {
        // Highlight selected option
        _text_color = c_yellow;
        _option_text = "> " + _option_text + " <"; // Add cursor indicators
    }

    draw_set_color(_text_color);
    draw_text(text_x, text_y_start + (i * line_height), _option_text);
}


// --- Reset Draw Settings ---
draw_set_font(-1); // Reset font
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);