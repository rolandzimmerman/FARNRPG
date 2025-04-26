/// obj_dialog :: Draw GUI Event
/// Draws the dialog box using spr_box1 (engine 9-slice via ext), Font1, and white text.

// Exit immediately if the current message index is invalid
// This can happen briefly before the first message is processed
if (current_message < 0 || current_message >= array_length(messages)) {
    exit;
}

// --- Basic Setup ---
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// --- Define drawing area ---
// Position dialog box at bottom part of the screen
var _boxh = gui_h * 0.3; // Height (e.g., 30% of GUI height)
var _boxw = gui_w;       // Full width
var _dx = 0;           // Start at left edge
var _dy = gui_h - _boxh; // Position box at the bottom
var _padding = 16;     // Padding inside the box

// --- Set Font and Color for ALL text ---
// vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
if (font_exists(Font1)) {
    draw_set_font(Font1);
} else {
    draw_set_font(-1); // Use default if Font1 is missing
}
draw_set_color(c_white); // SET COLOR TO WHITE FOR ALL TEXT
// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
draw_set_valign(fa_top);
draw_set_halign(fa_left);

// --- Draw background box using spr_box1 ---
if (sprite_exists(spr_box1)) { // Check for the correct sprite name
    var _spr_w = sprite_get_width(spr_box1);
    var _spr_h = sprite_get_height(spr_box1);
    if (_spr_w > 0 && _spr_h > 0) { // Prevent divide by zero
        var _xscale = _boxw / _spr_w;
        var _yscale = _boxh / _spr_h;
        // Draw using ext (engine handles 9-slice if enabled on sprite)
        draw_sprite_ext(spr_box1, 0, _dx, _dy, _xscale, _yscale, 0, c_white, 1.0); // Use white tint, full alpha
    } else {
        // Fallback rectangle if sprite has no dimensions
        show_debug_message("ERROR: spr_box1 has zero width/height in obj_dialog Draw GUI!");
        draw_set_alpha(0.8); draw_set_color(c_black); draw_rectangle(_dx, _dy, _dx + _boxw, _dy + _boxh, false); draw_set_alpha(1.0);
    }
} else {
    // Fallback rectangle if sprite asset is missing
    show_debug_message("WARNING: spr_box1 not found in obj_dialog Draw GUI!");
    draw_set_alpha(0.8); draw_set_color(c_black); draw_rectangle(_dx, _dy, _dx + _boxw, _dy + _boxh, false); draw_set_alpha(1.0);
}

// --- Calculate text drawing position inside box ---
var _text_x = _dx + _padding;
var _text_y = _dy + _padding;
var _text_width_limit = _boxw - (_padding * 2); // Max width for text wrapping

// --- Get Speaker Name ---
var _name = messages[current_message].name;

// --- REMOVED Speaker Name Color Logic ---
// var _name_color = c_white; ... logic checking global.char_colors ... REMOVED

// --- Draw Name (Always White) ---
// draw_set_color(_name_color); // REMOVED - Color already set to white
draw_text(_text_x, _text_y, _name + ":"); // Add colon after name
// draw_set_color(c_white); // REMOVED - Color is still white


// --- Draw Message Text (Always White) ---
var _message_y = _text_y + string_height_ext("W", -1, _text_width_limit) + 8; // Position message below name line (adjust spacing +8 as needed)

// Use draw_text_ext for automatic wrapping
// Ensure draw_message (likely updated in Step/End Step) contains the currently visible part of the text
// Color is already set to white
draw_text_ext(_text_x, _message_y, draw_message, -1, _text_width_limit);


// --- Reset Draw Settings ---
draw_set_font(-1);
// draw_set_color(c_white); // Color is already white
draw_set_valign(fa_top);
draw_set_halign(fa_left);
draw_set_alpha(1.0); // Ensure alpha is reset if changed elsewhere