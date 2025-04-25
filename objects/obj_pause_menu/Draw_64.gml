/// obj_pause_menu :: Draw GUI Event
// Only draw if this menu is active
if (!active) return;

// --- Basic Setup ---
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// --- Dim Background ---
draw_set_color(c_black);
draw_set_alpha(0.7);
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1.0);

// --- Menu Box ---
var box_width   = 240;
var box_lines   = menu_item_count + 1; // options + title
var line_height = 25;
var pad         = 15;
var box_height  = (box_lines * line_height) + (pad * 2);
var bx          = (gui_w - box_width)  / 2;
var by          = (gui_h - box_height) / 2;

// Box background
draw_set_color(c_navy);
draw_rectangle(bx, by, bx + box_width, by + box_height, false);
// Box border
draw_set_color(c_white);
draw_rectangle(bx, by, bx + box_width, by + box_height, true);

// --- Draw Text ---
draw_set_font(Font1);
draw_set_halign(fa_center);
draw_set_valign(fa_top);

// Title
draw_set_color(c_white);
draw_text(bx + box_width/2, by + pad, "Paused");

// Options
draw_set_halign(fa_left);
var tx = bx + pad;
var ty = by + pad + line_height;
for (var i = 0; i < menu_item_count; i++) {
    var txt = menu_options[i];
    var col = c_gray;
    if (i == menu_index) {
        col = c_yellow;
        txt = "> " + txt + " <";
    }
    draw_set_color(col);
    draw_text(tx, ty + i*line_height, txt);
}

// --- Reset ---
draw_set_font(-1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
