/// obj_save_point :: Draw GUI Event
/// Draw black overlay and horizontal Yes/No prompt

var ww = display_get_gui_width();
var hh = display_get_gui_height();

// Black overlay whenever not idle
if (state != "idle") {
    draw_set_color(c_black);
    draw_set_alpha(fade_alpha);
    draw_rectangle(0, 0, ww, hh, false);
    draw_set_alpha(1);
}

// Draw menu prompt when in "menu" state
if (state == "menu") {
    draw_set_font(Font1);
    draw_set_color(c_white);

    var prompt = "Save Game?";
    var px = ww/2 - string_width(prompt)/2;
    var py = hh/2 - 48;
    draw_text(px, py, prompt);

    // Yes / No horizontally
    var yes_x = ww/2 - 48;
    var no_x  = ww/2 + 16;
    var o_y   = hh/2;
    draw_text(yes_x, o_y, "Yes");
    draw_text(no_x,  o_y, "No");

    // Highlight current choice
    var cx = (menu_choice == 0 ? yes_x : no_x) - 4;
    var cy = o_y - 4;
    var cw = string_width(menu_choice == 0 ? "Yes" : "No") + 8;
    var ch = string_height("Yes") + 8;
    draw_set_color(c_yellow);
    draw_rectangle(cx, cy, cx + cw, cy + ch, false);
}

// Reset draw state
draw_set_alpha(1);
draw_set_color(c_white);
draw_set_font(-1);
