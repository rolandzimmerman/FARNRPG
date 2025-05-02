var box_x = 380;
var box_y = 80;
var box_w = 640;
var box_h = 600;

var col_bg = make_color_rgb(40, 40, 40);
var col_highlight = make_color_rgb(100, 100, 100);
var col_text = c_white;

// Draw background box using 9-slice sprite
if (sprite_exists(spr_box1)) {
    var sw = sprite_get_width(spr_box1);
    var sh = sprite_get_height(spr_box1);
    draw_sprite_ext(spr_box1, 0, box_x, box_y, box_w / sw, box_h / sh, 0, c_white, 1);
}

// Set font and colors
draw_set_color(col_text);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_text(box_x + 20, box_y + 20, "Settings Menu");

// === Compute Highlight Position ===
var sel_y;
switch (settings_index) {
    case 0: sel_y = 130; break; // Display Mode
    case 1: sel_y = 230; break; // Resolution
    case 2: sel_y = 380; break; // SFX Volume
    case 3: sel_y = 440; break; // Music Volume
    case 4: sel_y = 530; break; // Back
}

// Draw highlight rectangle
draw_set_color(c_yellow);
draw_rectangle(box_x + 10, sel_y - 10, box_x + box_w - 10, sel_y + 30, false);

// === Display Mode ===
draw_set_color(col_text);
draw_text(400, 130, "Display Mode:");
draw_set_color(col_highlight);
draw_rectangle(400, 150, 600, 180, true);
draw_set_color(col_text);
draw_text(410, 160, dropdown_display_options[dropdown_display_index]);

// Draw dropdown if open
if (dropdown_display_open) {
    for (var i = 0; i < array_length(dropdown_display_options); i++) {
        draw_set_color(col_highlight);
        draw_rectangle(400, 180 + i * 30, 600, 210 + i * 30, true);
        draw_set_color(col_text);
        draw_text(410, 190 + i * 30, dropdown_display_options[i]);
    }
}

// === Resolution ===
draw_set_color(col_text);
draw_text(400, 230, "Resolution:");
var res = global.resolution_options[global.resolution_index];
draw_set_color(col_highlight);
draw_rectangle(400, 250, 600, 280, true);
draw_set_color(col_text);
draw_text(410, 260, string(res[0]) + " x " + string(res[1]));

// Draw dropdown if open
if (dropdown_resolution_open) {
    for (var i = 0; i < array_length(global.resolution_options); i++) {
        var r = global.resolution_options[i];
        draw_set_color(col_highlight);
        draw_rectangle(400, 280 + i * 30, 600, 310 + i * 30, true);
        draw_set_color(col_text);
        draw_text(410, 290 + i * 30, string(r[0]) + " x " + string(r[1]));
    }
}

// === SFX Volume ===
draw_set_color(col_text);
draw_text(400, 380, "SFX Volume:");
draw_set_color(col_bg);
draw_rectangle(400, 400, 600, 420, true);
draw_set_color(col_highlight);
draw_rectangle(400, 400, 400 + global.sfx_volume * 200, 420, true);

// === Music Volume ===
draw_set_color(col_text);
draw_text(400, 440, "Music Volume:");
draw_set_color(col_bg);
draw_rectangle(400, 460, 600, 480, true);
draw_set_color(col_highlight);
draw_rectangle(400, 460, 400 + global.music_volume * 200, 480, true);

// === Back ===
draw_set_color(col_text);
draw_text(400, 530, "Back (ESC / B)");

// Reset draw state
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
