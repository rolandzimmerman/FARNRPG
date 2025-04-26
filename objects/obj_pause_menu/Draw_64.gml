/// obj_pause_menu :: Draw GUI Event
/// Draws the pause menu using spr_box1 (engine 9-slice via stretch), Font1, and white text.

// Only draw if this menu is active
if (!variable_instance_exists(id, "active") || !active) return;
if (!variable_instance_exists(id, "menu_options")) return;
if (!variable_instance_exists(id, "menu_item_count")) return;
if (!variable_instance_exists(id, "menu_index")) return;

// --- Basic Setup ---
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// --- Menu Box Dimensions ---
var box_width   = 240;
var line_height = 28;
var pad         = 15;
var margin      = 16;
var box_lines   = menu_item_count + 1;
var box_height  = (box_lines * line_height) + (pad * 2);
var box_x       = margin; // Top-left alignment
var box_y       = margin; // Top-left alignment

// --- Set Font and Color ---
if (font_exists(Font1)) {
    draw_set_font(Font1); // SET FONT
} else {
    draw_set_font(-1); // Fallback font
}
draw_set_color(c_white); // SET COLOR
draw_set_valign(fa_top);
draw_set_halign(fa_left);

// --- Dim Background ---
draw_set_alpha(0.7);
draw_set_color(c_black); // Separate color for dimming rect
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1.0);
draw_set_color(c_white); // Reset color after drawing dimming rect

// --- Draw Menu Box ---
if (sprite_exists(spr_box1)) {
    var _spr_w = sprite_get_width(spr_box1); var _spr_h = sprite_get_height(spr_box1);
    if (_spr_w > 0 && _spr_h > 0) {
        var _xscale = box_width / _spr_w; var _yscale = box_height / _spr_h;
        draw_sprite_ext(spr_box1, 0, box_x, box_y, _xscale, _yscale, 0, c_white, 1); // Draw sprite normally tinted white
    } else { /* Fallback Rect + Error Log */ }
} else { /* Fallback Rect + Error Log */ }

// --- Draw Text ---
var text_x = box_x + pad;
var title_y = box_y + pad;
var options_y = title_y + line_height;

// Title
draw_set_halign(fa_center);
draw_set_color(c_white); // Ensure white for title
draw_text(box_x + box_width / 2, title_y, "Paused");

// Options
draw_set_halign(fa_left);
for (var i = 0; i < menu_item_count; i++) {
    var option_text = menu_options[i];
    var current_row_y = options_y + i * line_height;
    if (i == menu_index) {
        option_text = "> " + option_text;
    }
    draw_set_color(c_white); // Ensure white for options
    draw_text(text_x, current_row_y, option_text);
}

// --- Reset Drawing Settings ---
draw_set_font(-1);
draw_set_color(c_white); // Reset color
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1.0);