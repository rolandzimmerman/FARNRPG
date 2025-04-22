/// obj_dialog :: Draw GUI

// Exit immediately if the current message index is invalid
// This can happen briefly before the first message is processed
if (current_message < 0 || current_message >= array_length(messages)) {
    exit;
}

// Define drawing area
var _dx = 0;
var _dy = gui_h * 0.7;
var _boxw = gui_w;
var _boxh = gui_h - _dy;
var _padding = 16; // Padding inside the box

// Draw background box (ensure spr_box exists)
if (sprite_exists(spr_box)) {
    draw_sprite_stretched(spr_box, 0, _dx, _dy, _boxw, _boxh);
} else {
    // Fallback if sprite missing
    draw_set_color(c_black);
    draw_set_alpha(0.8);
    draw_rectangle(_dx, _dy, _dx + _boxw, _dy + _boxh, false);
    draw_set_alpha(1.0);
}


// Set text drawing properties
_dx += _padding;
_dy += _padding;
if (font_exists(Font1)) draw_set_font(Font1); else draw_set_font(-1); // Use default if Font1 missing
draw_set_valign(fa_top);
draw_set_halign(fa_left);

// --- Get Speaker Name and Color Safely ---
var _name = messages[current_message].name;
var _name_color = c_white; // Default color

// Check if global struct exists and the name key is present
if (variable_global_exists("char_colors") && is_struct(global.char_colors)) {
    if (variable_struct_exists(global.char_colors, _name)) {
        // Key exists, get the color
        _name_color = global.char_colors[$ _name];
        // Optional: Check if the retrieved value is actually a color number
        if (!is_real(_name_color)) {
             show_debug_message("⚠️ Dialog Draw: Color value for '" + _name + "' is not a number! Reverting to default.");
            _name_color = c_white;
        }
    } else {
        // Name key doesn't exist in the struct
        show_debug_message("⚠️ Dialog Draw: Name '" + _name + "' not found in global.char_colors. Using default color.");
        _name_color = c_white; // Use default
    }
} else {
    // Global struct itself doesn't exist or isn't a struct
    show_debug_message("⚠️ Dialog Draw: global.char_colors missing or not a struct. Using default color for name.");
    _name_color = c_white; // Use default
}

// --- Draw Name ---
draw_set_color(_name_color); // Use the safely determined color
draw_text(_dx, _dy, _name + ":"); // Add colon after name
draw_set_color(c_white); // Reset color for message text


// --- Draw Message Text ---
var _message_y = _dy + string_height("W") + 8; // Position message below name (adjust spacing as needed)
var _text_width_limit = _boxw - (_padding * 2); // Max width for text wrapping

// Use draw_text_ext for automatic wrapping
// Ensure draw_message (updated in End Step) contains the currently visible text
draw_text_ext(_dx, _message_y, draw_message, -1, _text_width_limit);


// --- Reset Draw Settings ---
draw_set_font(-1);
draw_set_color(c_white);
draw_set_valign(fa_top);
draw_set_halign(fa_left);