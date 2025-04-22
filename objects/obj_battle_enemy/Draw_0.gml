/// obj_battle_enemy :: Draw Event

// ADD LOG AT START - Check data existence here, as it's assigned after Create
var _data_exists = is_struct(data);
show_debug_message("Enemy Draw: ID " + string(id) + ", Data Exists: " + string(_data_exists) + ", Vis: " + string(visible) + ", Alpha: " + string(image_alpha) + ", Sprite: " + sprite_get_name(sprite_index));

// Check visibility before drawing anything
if (!visible || image_alpha <= 0) {
     show_debug_message("   -> Skipping draw (invisible or alpha <= 0)");
     exit; // Don't draw if invisible
}

// If data exists, ensure sprite_index is updated from it (in case it changed)
if (_data_exists) {
    // Make sure sprite_index is correctly set from data struct
    // This assumes data was assigned correctly by the manager.
    if (variable_struct_exists(data, "sprite_index")) {
         sprite_index = data.sprite_index;
    } else {
         // Handle missing sprite_index in data
         show_debug_message("   -> ⚠️ Data struct exists but missing 'sprite_index'!");
         sprite_index = -1; // Set to invalid sprite
    }
} else {
     // No data struct - cannot determine correct sprite
     show_debug_message("   -> ⚠️ Skipping draw: Missing data struct!");
     // Draw placeholder or exit
     draw_set_color(c_orange);
     draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true); // Orange placeholder box
     exit;
}


// Check if sprite is valid before drawing
if (sprite_index < 0 || !sprite_exists(sprite_index)) {
     show_debug_message("   -> ⚠️ Skipping draw: Invalid sprite_index (" + string(sprite_index) + ")");
     // Optionally draw a placeholder shape
     draw_set_color(c_fuchsia);
     draw_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, true); // Fuchsia placeholder box
     exit;
}

// Original draw code
show_debug_message("   -> Calling draw_self() with sprite: " + sprite_get_name(sprite_index));
draw_self();

// HP Bar / Name drawing code (keep as is, but ensure data check is robust)
if (_data_exists) {
    show_debug_message("   -> Drawing HP bar/name");
    var bar_w = 60;
    var bar_h = 6;

    // Name label
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom); // Draw name above the sprite
    // Safely get name, provide default if missing
    var enemy_name = variable_struct_exists(data, "name") ? data.name : "???";
    draw_text(x, bbox_top - 4, enemy_name); // Draw text just above the bounding box top

    // HP Bar (just below sprite feet)
    // Safely get HP values, provide defaults if missing
    var hp = variable_struct_exists(data, "hp") ? data.hp : 0;
    var maxhp = variable_struct_exists(data, "maxhp") ? data.maxhp : 1; // Avoid divide by zero
    var hp_ratio = (maxhp > 0) ? (hp / maxhp) : 0;

    var bar_x = x - bar_w / 2;
    var bar_y = bbox_bottom + 4; // Draw bar just below the bounding box bottom

    // Background
    draw_set_color(c_black);
    draw_set_alpha(0.7);
    draw_rectangle(bar_x - 1, bar_y - 1, bar_x + bar_w + 1, bar_y + bar_h + 1, false);

    // Foreground
    draw_set_color(c_red);
    draw_set_alpha(0.8);
    draw_rectangle(bar_x, bar_y, bar_x + bar_w * hp_ratio, bar_y + bar_h, false);
    draw_set_alpha(1); // Reset alpha

} else {
     show_debug_message("   -> Skipping HP bar draw (no data struct)");
}

// Reset draw settings
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);