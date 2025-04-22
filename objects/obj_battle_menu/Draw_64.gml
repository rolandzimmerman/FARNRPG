/// obj_battle_menu :: Draw GUI
// Draws HP/MP bars, Radial Menu (Shifted Down), Skill List, or Target Cursor.

// --- Basic Checks & Player Data Validation ---
if (!visible || image_alpha <= 0) exit;

var player_data_valid = false;
var p_inst = noone; // Instance ID of obj_battle_player
var p_data = noone; // The data struct inside obj_battle_player

if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) {
    if (ds_list_size(global.battle_party) > 0) {
        p_inst = global.battle_party[| 0];
        if (instance_exists(p_inst)) {
            if (variable_instance_exists(p_inst,"data") && is_struct(p_inst.data)) {
                 p_data = p_inst.data;
                 if (variable_struct_exists(p_data, "hp") && variable_struct_exists(p_data, "mp")) {
                      player_data_valid = true;
                 }
            }
        }
    }
}

if (!player_data_valid) {
    // Draw error message if player data invalid and exit
    if (font_exists(Font1)) draw_set_font(Font1); else draw_set_font(-1);
    draw_set_color(c_red); draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_text(10, 10, "ERROR: BATTLE MENU CANNOT FIND PLAYER DATA FOR UI");
    draw_set_color(c_white); draw_set_font(-1);
    exit;
}
// --- End Validation ---


// === Constants ===
var hud_x = 24; var hud_y = 24; var bar_w = 200; var bar_h = 20; var bar_spacing = 10;
// Constants for Skill List positioning (relative to old menu center)
var menu_cx = 160; var menu_cy = 600; var menu_r = 80;
var skill_list_x = menu_cx + menu_r + 80; var skill_list_y = menu_cy - 80;
var skill_list_w = 240; var skill_list_h = 36; var skill_select_color = c_yellow;
// Constants for Radial Menu (Scale and Rotation)
var button_scale = 0.5;
var label_scale = 0.5;
var label_rot = 35;
var menu_y_offset = 220; // <<< UPDATED: Total downward shift (120 + 100)


// === Set Font (Needed for Skill List) ===
if (font_exists(Font1)) draw_set_font(Font1); else draw_set_font(-1);


// === Draw Top-left HP/MP Bars ===
draw_set_halign(fa_left); draw_set_valign(fa_top);
// HP Bar
var _hp = p_data.hp; var _maxhp = variable_struct_exists(p_data,"maxhp") ? p_data.maxhp : 1; var hp_ratio = (_maxhp > 0) ? (_hp / _maxhp) : 0; draw_set_color(c_dkgray); draw_set_alpha(0.7); draw_rectangle(hud_x, hud_y, hud_x + bar_w, hud_y + bar_h, false); draw_set_color(c_red); draw_set_alpha(0.8); draw_rectangle(hud_x, hud_y, hud_x + floor(bar_w * hp_ratio), hud_y + bar_h, false); draw_set_color(c_white); draw_set_alpha(1); draw_set_valign(fa_middle); draw_text(hud_x + 4, hud_y + bar_h / 2, "HP: " + string(floor(_hp)) + " / " + string(floor(_maxhp))); draw_set_valign(fa_top);
// MP Bar
var mp_hud_y = hud_y + bar_h + bar_spacing; var _mp = p_data.mp; var _maxmp = variable_struct_exists(p_data,"maxmp") ? p_data.maxmp : 1; var mp_ratio = (_maxmp > 0) ? (_mp / _maxmp) : 0; draw_set_color(c_dkgray); draw_set_alpha(0.7); draw_rectangle(hud_x, mp_hud_y, hud_x + bar_w, mp_hud_y + bar_h, false); draw_set_color(c_blue); draw_set_alpha(0.8); draw_rectangle(hud_x, mp_hud_y, hud_x + floor(bar_w * mp_ratio), mp_hud_y + bar_h, false); draw_set_color(c_white); draw_set_alpha(1); draw_set_valign(fa_middle); draw_text(hud_x + 4, mp_hud_y + bar_h / 2, "MP: " + string(floor(_mp)) + " / " + string(floor(_maxmp)));


// === Main Command Menu (Radial), Skill Menu OR Target Cursor ===
draw_set_color(c_white); draw_set_alpha(1); // Reset color/alpha

if (global.battle_state == "player_input") {
    // --- Draw Radial Menu using Specific Sprites and Coordinates (Shifted Down Further) ---

    // --- Draw Button Icons (Scaled & Shifted) ---
    if (sprite_exists(Abutton))  draw_sprite_ext(Abutton, 0, 97, 619 + menu_y_offset, button_scale, button_scale, 0, c_white, 1);
    if (sprite_exists(Bbutton))  draw_sprite_ext(Bbutton, 0, 147, 557 + menu_y_offset, button_scale, button_scale, 0, c_white, 1);
    if (sprite_exists(Xbutton))  draw_sprite_ext(Xbutton, 0, 48, 559 + menu_y_offset, button_scale, button_scale, 0, c_white, 1);
    if (sprite_exists(Ybutton))  draw_sprite_ext(Ybutton, 0, 97, 501 + menu_y_offset, button_scale, button_scale, 0, c_white, 1);

    // --- Draw Action Labels (Scaled, Rotated & Shifted) ---
    if (sprite_exists(spr_attack))  draw_sprite_ext(spr_attack, 0, -5.83, 687.83 + menu_y_offset, label_scale, label_scale, label_rot, c_white, 1);
    if (sprite_exists(spr_defend))  draw_sprite_ext(spr_defend, 0, 195.92, 563.76 + menu_y_offset, label_scale, label_scale, label_rot, c_white, 1);
    if (sprite_exists(spr_special)) draw_sprite_ext(spr_special, 0, -14.91, 563.75 + menu_y_offset, label_scale, label_scale, label_rot, c_white, 1);
    if (sprite_exists(spr_items))   draw_sprite_ext(spr_items, 0, 133, 497.68 + menu_y_offset, label_scale, label_scale, label_rot, c_white, 1);

    // --- End Radial Menu Drawing ---
}
else if (global.battle_state == "skill_select") {
    // --- Draw Skill List ---
     // Note: Skill list position might also need adjusting if the radial menu moved significantly
     draw_set_halign(fa_left); draw_set_valign(fa_top);
     var _skills_array = (variable_struct_exists(p_data, "skills") && is_array(p_data.skills)) ? p_data.skills : [];
     var _skill_index = variable_struct_exists(p_data, "skill_index") ? p_data.skill_index : 0;
     var _current_mp = p_data.mp;
     if (array_length(_skills_array) > 0) { for (var i = 0; i < array_length(_skills_array); i++) { var s = _skills_array[i]; if (!is_struct(s)) continue; var skill_name = variable_struct_exists(s, "name") ? s.name : "???"; var skill_cost = variable_struct_exists(s, "cost") ? s.cost : 0; var current_y = skill_list_y + i * skill_list_h; if (i == _skill_index) { draw_set_color(skill_select_color); draw_set_alpha(0.5); draw_rectangle(skill_list_x - 6, current_y - 2, skill_list_x + skill_list_w + 6, current_y + skill_list_h - 2, false); draw_set_alpha(1); } var display_color = (_current_mp < skill_cost) ? c_gray : c_white; draw_set_color(display_color); draw_text(skill_list_x, current_y, skill_name + " (MP " + string(skill_cost) + ")"); } }
     else { draw_set_color(c_gray); draw_text(skill_list_x, skill_list_y, "No Skills"); }
}
else if (global.battle_state == "TargetSelect") {
    // --- Draw Target Indicator Cursor ---
     var num_enemies = ds_list_size(global.battle_enemies); if (num_enemies > 0 && global.battle_target >= 0 && global.battle_target < num_enemies) { var _target_inst_id = global.battle_enemies[| global.battle_target]; if (instance_exists(_target_inst_id)) { var _target_x = _target_inst_id.x; var _target_y = _target_inst_id.bbox_top; var _cursor_offset_y = 10; if (sprite_exists(spr_target_cursor)) { draw_sprite(spr_target_cursor, 0, _target_x, _target_y - _cursor_offset_y); } else { draw_set_halign(fa_center); draw_set_valign(fa_bottom); draw_text(_target_x, _target_y - _cursor_offset_y, "▼"); draw_set_halign(fa_left); draw_set_valign(fa_top);} } }
}


// === Reset draw state ===
draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);