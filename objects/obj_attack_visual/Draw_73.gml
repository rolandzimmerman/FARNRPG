// In obj_attack_visual - Draw End Event

// Ensure font exists before setting
if (font_exists(Font_Debug)) {
    draw_set_font(Font_Debug);
} else {
    draw_set_font(-1); // Use default font if debug font missing
    if (!variable_instance_exists(id,"warned_font")) { // Warn only once
        show_debug_message("WARNING: Font_Debug not found in obj_attack_visual Draw End!");
        warned_font = true;
    }
}

// Prepare text components safely
var _layer_name = "(invalid layer)"; // Default text
if (layer_exists(layer)) { // Check if the layer ID is valid
     _layer_name = layer_get_name(layer);
} else {
     _layer_name = "(layer ID: " + string(layer) + " invalid?)";
}

var _depth_string = string(depth); // Depth should always be a real number

var _debug_string = "FX\nLayer: " + _layer_name + "\nDepth: " + _depth_string;

// Draw Text
draw_set_halign(fa_center);
draw_set_valign(fa_bottom);
draw_set_color(c_yellow);
draw_set_alpha(1);
draw_text(x, bbox_top - 2, _debug_string);

// Draw bounding box outline
draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true);

// Reset draw settings
draw_set_color(c_white);
draw_set_font(-1);
draw_set_halign(fa_left); // Reset alignment
draw_set_valign(fa_top); // Reset alignment
draw_set_alpha(1);