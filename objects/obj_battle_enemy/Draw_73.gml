/// obj_battle_player :: Draw End Event
// Draws debug information (Layer, Depth, BBox) in yellow.

// Ensure font exists before setting
if (font_exists(Font_Debug)) {
    draw_set_font(Font_Debug);
} else {
    draw_set_font(-1); // Use default font if debug font missing
    if (!variable_instance_exists(id,"warned_font")) { // Warn only once
        show_debug_message("WARNING: Font_Debug not found in obj_battle_player Draw End!");
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

// Set text to identify this as the Player
var _debug_string = "Player\nLayer: " + _layer_name + "\nDepth: " + _depth_string;

// --- Draw Debug Info ---
draw_set_halign(fa_center);
draw_set_valign(fa_bottom);
// Use yellow color as requested
draw_set_color(c_yellow);
draw_set_alpha(1);

// Draw the text slightly above the bounding box
draw_text(x, bbox_top - 2, _debug_string);

// Draw bounding box outline
draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true); // true = outline only

// --- Reset draw settings ---
draw_set_color(c_white);
draw_set_font(-1);
draw_set_halign(fa_left); // Reset alignment
draw_set_valign(fa_top); // Reset alignment
draw_set_alpha(1);