/// obj_popup_damage :: Draw Event

// Assume the instance is created at x = character.x, y = character.y - sprite_height / 2
// So it starts just above their head

draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_set_alpha(alpha);
draw_set_color(c_white);
draw_set_font(Font1);

var offset_y = -32; // rise above spawn point slightly
draw_text(x, y + offset_y, string(damage_amount));

draw_set_alpha(1);
