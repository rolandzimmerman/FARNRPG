/// obj_levelup_popup :: Draw GUI Event
/// — Draw the box, title, and old→new for each stat, green if it went up

// Use Font1 everywhere
draw_set_font(Font1);

// 1) background
draw_set_alpha(0.9);
draw_sprite_ext(
    spr_box1, 0,
    boxX, boxY,
    boxW / sprite_get_width(spr_box1),
    boxH / sprite_get_height(spr_box1),
    0, c_white, 1
);
draw_set_alpha(1);

// 2) title
draw_set_color(c_white);
draw_text(boxX + padding, boxY + padding, string(info.name) + " leveled up!");

// 3) stats
var startY = boxY + padding + 2*lineH;
var colOldX = boxX + padding;
var colSepX = boxX + boxW/2 - 8;
var colNewX = boxX + boxW - padding - 50;

for (var i = 0; i < array_length(keys); i++) {
    var key = keys[i];
    // safely fetch old/new from struct
    var oldV = variable_struct_get(info.old, key);
    var newV = variable_struct_get(info.new, key);

    // old value
    draw_set_color(c_gray);
    draw_text(colOldX, startY + i*lineH, string(oldV));

    // separator
    draw_set_color(c_white);
    draw_text(colSepX, startY + i*lineH, ">");

    // new value (green if increased)
    draw_set_color(newV > oldV ? c_lime : c_white);
    draw_text(colNewX, startY + i*lineH, string(newV));
}
