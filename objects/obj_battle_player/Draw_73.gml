// --- PUT THIS IN Draw End FOR: obj_battle_player ---
// --- Adapt "Player" text for Enemy/FX objects ---

// Ensure font exists before setting
if (font_exists(Font_Debug)) {
    draw_set_font(Font_Debug);
} else {
    draw_set_font(-1); // Use default font if debug font missing
    if (!variable_instance_exists(id,"warned_font")) { // Warn only once
        // Adapt object name in message below for Enemy/FX
        show_debug_message("WARNING: Font_Debug not found in Player Draw End!");
        warned_font = true;
    }
}

// Prepare text components safely
var _layer_id_at_draw = layer; // Get the instance's current layer variable
var _layer_name = "(layer invalid or destroyed)"; // Default text

// *** ADDED CHECK: Verify if the layer ID is still valid AT DRAW TIME ***
if (layer_exists(_layer_id_at_draw)) {
     _layer_name = layer_get_name(_layer_id_at_draw); // Get name ONLY if layer still exists
} else {
     // If layer_exists is false, the layer ID stored in the instance is no longer valid
     _layer_name = "(Layer ID " + string(_layer_id_at_draw) + " INVALID at draw!)";
}
// *** END ADDED CHECK ***

var _depth_string = string(depth); // Depth should always be a real number

// Set text to identify this object type
var _obj_type_name = "Player"; // *** CHANGE THIS to "Enemy" or "FX" in other objects ***
var _debug_string = _obj_type_name + "\nLayer: " + _layer_name + "\nDepth: " + _depth_string;

// --- Draw Debug Info ---
draw_set_halign(fa_center);
draw_set_valign(fa_bottom);
draw_set_color(c_yellow); // Keep yellow as requested
draw_set_alpha(1);
draw_text(x, bbox_top - 2, _debug_string);
draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true); // true = outline only

// --- Reset draw settings ---
draw_set_color(c_white);
draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1);