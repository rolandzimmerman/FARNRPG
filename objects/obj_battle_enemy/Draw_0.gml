/// obj_battle_enemy :: Draw Event
var _data_exists = is_struct(data);
/*show_debug_message("Enemy Draw: ID " + string(id)
  + ", State: " + string(combat_state)
  + ", Data Exists: " + string(_data_exists)
  + ", Sprite: " + sprite_get_name(sprite_index)
); */

// If invisible or alpha 0, skip all drawing
if (!visible || image_alpha <= 0) {
    exit;
}

// Only override the sprite from data when we're neither dying nor corpse
if (_data_exists
 && combat_state != "dying"
 && combat_state != "corpse") {
    if (variable_struct_exists(data, "sprite_index")) {
        sprite_index = data.sprite_index;
    } else {
        show_debug_message("   -> ⚠️ Missing data.sprite_index!");
        sprite_index = -1;
    }
}

// Now draw whatever sprite_index is set to (death/corpse or normal)
draw_self();

// Draw HP bar / name only if we're alive
if (_data_exists
 && combat_state != "dying"
 && combat_state != "corpse") {
    
    // Name
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    var nm = variable_struct_exists(data, "name") ? data.name : "???";
    draw_text(x, bbox_top - 4, nm);

    // HP bar
    var hp    = variable_struct_exists(data, "hp")    ? data.hp    : 0;
    var maxhp = variable_struct_exists(data, "maxhp") ? data.maxhp : 1;
    var ratio = (maxhp > 0) ? hp / maxhp : 0;
    var w = 60, h = 6;
    var bx = x - w/2, by = bbox_bottom + 4;

    draw_set_color(c_black);
    draw_set_alpha(0.7);
    draw_rectangle(bx-1, by-1, bx+w+1, by+h+1, false);

    draw_set_color(c_red);
    draw_set_alpha(0.8);
    draw_rectangle(bx, by, bx + w*ratio, by+h, false);

    draw_set_alpha(1);
}

var st = scr_GetStatus(id);
if (is_struct(st) && st.effect != "none") {
    var icon_idx = scr_GetStatusIcon(st.effect);
    if (icon_idx != -1 && sprite_exists(icon_idx)) {
        draw_sprite_ext(icon_idx, 0, x, bbox_top - 16, 1,1, 0, c_white, 1);
    }
}

// Reset draw settings
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
