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
var box_lines   = menu_item_count + 1; // +1 for Title
var box_height  = (box_lines * line_height) + (pad * 2);
var box_x       = margin; 
var box_y       = margin; 

// --- Set Font and Color ---
if (font_exists(Font1)) { draw_set_font(Font1); } else { draw_set_font(-1); }
draw_set_color(c_white); 
draw_set_valign(fa_top);
draw_set_halign(fa_left);

// --- Dim Background ---
draw_set_alpha(0.7);
draw_set_color(c_black); 
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1.0);
draw_set_color(c_white); 

// --- Draw Menu Box ---
if (sprite_exists(spr_box1)) {
    var _spr_w = sprite_get_width(spr_box1); var _spr_h = sprite_get_height(spr_box1);
    if (_spr_w > 0 && _spr_h > 0) {
        var _xscale = box_width / _spr_w; var _yscale = box_height / _spr_h;
        draw_sprite_ext(spr_box1, 0, box_x, box_y, _xscale, _yscale, 0, c_white, 1); 
    } // else { /* Fallback Rect + Error Log */ } // Consider adding fallback drawing
} // else { /* Fallback Rect + Error Log */ }

// --- Draw Text ---
var text_x = box_x + pad;
var title_y = box_y + pad;
var options_y = title_y + line_height;

// Title
draw_set_halign(fa_center);
draw_text(box_x + box_width / 2, title_y, "Paused");

// Options
draw_set_halign(fa_left);
for (var i = 0; i < menu_item_count; i++) {
    var option_text = menu_options[i];
    var current_row_y = options_y + i * line_height;
    if (i == menu_index) {
        option_text = "> " + option_text;
        // Optional: Draw a selection highlight rectangle behind text
        // draw_set_alpha(0.3); draw_set_color(c_yellow); 
        // draw_rectangle(box_x+pad/2, current_row_y-2, box_x+box_width-pad/2, current_row_y+line_height-2, false);
        // draw_set_alpha(1.0); draw_set_color(c_white); 
    }
    draw_text(text_x, current_row_y, option_text);
}

// --- Reset Drawing Settings ---
draw_set_font(-1);
draw_set_color(c_white); 
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1.0);