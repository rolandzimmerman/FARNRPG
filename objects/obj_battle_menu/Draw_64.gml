/// obj_battle_menu :: Draw GUI
/// Draws battle UI elements. Reads data from obj_battle_player.data

// --- Basic Checks ---
if (!visible || image_alpha <= 0) exit;
if (!variable_global_exists("battle_state")) { exit; }

// --- Active Player Data Validation ---
var active_player_data_valid = false; var active_p_inst = noone; var active_p_data = noone; var active_idx = -1;
if (variable_global_exists("active_party_member_index") && variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) {
    active_idx = global.active_party_member_index; var party_size = ds_list_size(global.battle_party);
    if (active_idx >= 0 && active_idx < party_size) {
        active_p_inst = global.battle_party[| active_idx];
        if (instance_exists(active_p_inst)) {
            if (variable_instance_exists(active_p_inst, "data") && is_struct(active_p_inst.data)) { // Check 'data'
                active_p_data = active_p_inst.data; // Reference 'data'
                if (variable_struct_exists(active_p_data, "hp") && variable_struct_exists(active_p_data, "mp") && variable_struct_exists(active_p_data, "name")) { active_player_data_valid = true; }
            }
        }
    }
}
// --- End Validation ---

// === Constants ===
var party_hud_positions_x = [64, 320, 576, 832]; var party_hud_y = 0; var menu_cx=160; var menu_cy=600; var menu_r=80; var button_scale=0.5; var label_scale=0.5; var label_rot=35; var menu_y_offset=220; var list_x_base = menu_cx + menu_r + 80; var list_y = menu_cy - 80 + menu_y_offset; var list_line_h = 36; var list_padding = 8; var list_item_w = 240; var list_qty_w = 40; var list_box_w = list_item_w + list_qty_w + list_padding * 3; var list_max_items_shown = 5; var list_select_color = c_yellow;

// === Set Font and Color ===
if (font_exists(Font1)) draw_set_font(Font1); else draw_set_font(-1);
draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_top);

// === Draw Party HP/MP HUDs ===
if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) {
    var party_size = ds_list_size(global.battle_party);
    var _spr_hud_bg_exists = sprite_exists(spr_pc_hud_bg); var _spr_hp_exists = sprite_exists(spr_pc_hud_hp); var _spr_mp_exists = sprite_exists(spr_pc_hud_mp);
    var _spr_hp_w = _spr_hp_exists ? sprite_get_width(spr_pc_hud_hp) : 0; var _spr_hp_h = _spr_hp_exists ? sprite_get_height(spr_pc_hud_hp) : 0; var _spr_mp_w = _spr_mp_exists ? sprite_get_width(spr_pc_hud_mp) : 0; var _spr_mp_h = _spr_mp_exists ? sprite_get_height(spr_pc_hud_mp) : 0;
    for (var i = 0; i < party_size; i++) {
        if (i >= array_length(party_hud_positions_x)) { continue; }
        var current_member_hud_x = party_hud_positions_x[i]; var current_member_hud_y = party_hud_y;
        var p_inst = global.battle_party[| i];
        if (instance_exists(p_inst) && variable_instance_exists(p_inst, "data") && is_struct(p_inst.data)) {
            var p_data = p_inst.data; var is_active_member = (i == active_idx); var bar_alpha = is_active_member ? 1.0 : 0.7; var bg_tint = is_active_member ? c_white : c_gray;
            var name_rel_x=10; var name_rel_y=3; var hp_bar_rel_x=32; var hp_bar_rel_y=20; var hp_text_rel_x=35; var hp_text_rel_y=20+(_spr_hp_h/2); var mp_bar_rel_x=32; var mp_bar_rel_y=38; var mp_text_rel_x=35; var mp_text_rel_y=38+(_spr_mp_h/2);
            if (_spr_hud_bg_exists) { draw_sprite_ext(spr_pc_hud_bg, 0, current_member_hud_x, current_member_hud_y, 1, 1, 0, bg_tint, bar_alpha); }
            draw_set_color(c_white); draw_set_alpha(bar_alpha); draw_set_valign(fa_top); draw_text(current_member_hud_x + name_rel_x, current_member_hud_y + name_rel_y, p_data.name ?? "???");
            if (_spr_hp_exists && variable_struct_exists(p_data,"hp") && variable_struct_exists(p_data,"maxhp")) { var _hp=p_data.hp; var _maxhp=p_data.maxhp; var hp_ratio=(_maxhp>0)?clamp(_hp/_maxhp,0,1):0; var hp_draw_w=floor(_spr_hp_w*hp_ratio); if(hp_draw_w>0){draw_sprite_part_ext(spr_pc_hud_hp,0,0,0,hp_draw_w,_spr_hp_h,current_member_hud_x+hp_bar_rel_x,current_member_hud_y+hp_bar_rel_y,1,1,c_white,bar_alpha);} }
            draw_set_color(c_white); draw_set_alpha(bar_alpha); draw_set_valign(fa_middle); draw_text(current_member_hud_x + hp_text_rel_x, current_member_hud_y + hp_text_rel_y, string(floor(p_data.hp ?? 0)) + "/" + string(floor(p_data.maxhp ?? 1))); draw_set_valign(fa_top);
            if (_spr_mp_exists && variable_struct_exists(p_data,"mp") && variable_struct_exists(p_data,"maxmp")) { var _mp=p_data.mp; var _maxmp=p_data.maxmp; var mp_ratio=(_maxmp>0)?clamp(_mp/_maxmp,0,1):0; var mp_draw_w=floor(_spr_mp_w*mp_ratio); if(mp_draw_w>0){draw_sprite_part_ext(spr_pc_hud_mp,0,0,0,mp_draw_w,_spr_mp_h,current_member_hud_x+mp_bar_rel_x,current_member_hud_y+mp_bar_rel_y,1,1,c_white,bar_alpha);} }
            draw_set_color(c_white); draw_set_alpha(bar_alpha); draw_set_valign(fa_middle); draw_text(current_member_hud_x + mp_text_rel_x, current_member_hud_y + mp_text_rel_y, string(floor(p_data.mp ?? 0)) + "/" + string(floor(p_data.maxmp ?? 0))); draw_set_valign(fa_top);
        }
    }
    draw_set_alpha(1.0);
}

// === Main Command Menu / Skill Menu / Item Menu ===
draw_set_color(c_white);
if (active_player_data_valid) {
    if (global.battle_state == "player_input") {
        if(sprite_exists(Abutton))draw_sprite_ext(Abutton,0,97,619+menu_y_offset,button_scale,button_scale,0,c_white,1); if(sprite_exists(Bbutton))draw_sprite_ext(Bbutton,0,147,557+menu_y_offset,button_scale,button_scale,0,c_white,1); if(sprite_exists(Xbutton))draw_sprite_ext(Xbutton,0,48,559+menu_y_offset,button_scale,button_scale,0,c_white,1); if(sprite_exists(Ybutton))draw_sprite_ext(Ybutton,0,97,501+menu_y_offset,button_scale,button_scale,0,c_white,1); if(sprite_exists(spr_attack))draw_sprite_ext(spr_attack,0,-5.83,687.83+menu_y_offset,label_scale,label_scale,label_rot,c_white,1); if(sprite_exists(spr_defend))draw_sprite_ext(spr_defend,0,195.92,563.76+menu_y_offset,label_scale,label_scale,label_rot,c_white,1); if(sprite_exists(spr_special))draw_sprite_ext(spr_special,0,-14.91,563.75+menu_y_offset,label_scale,label_scale,label_rot,c_white,1); if(sprite_exists(spr_items))draw_sprite_ext(spr_items,0,133,497.68+menu_y_offset,label_scale,label_scale,label_rot,c_white,1);
    } else if (global.battle_state == "skill_select") {
        draw_set_halign(fa_left); draw_set_valign(fa_top); var _skills_array = (variable_struct_exists(active_p_data, "skills") && is_array(active_p_data.skills)) ? active_p_data.skills : []; var _skill_index = variable_struct_exists(active_p_data, "skill_index") ? active_p_data.skill_index : 0; var _skill_count = array_length(_skills_array); if (_skill_count == 0) { _skill_index = -1; } else { _skill_index = clamp(_skill_index, 0, _skill_count - 1); }
        var _list_items_to_draw = _skill_count; var _list_box_h = (_list_items_to_draw * list_line_h) + list_padding * 2; if (_list_items_to_draw == 0) { _list_box_h = list_line_h + list_padding * 2; } var _list_box_x = list_x_base - list_padding; var _list_box_y = list_y - list_padding; var _list_box_w = list_item_w + list_padding * 2;
        if (sprite_exists(spr_box1)) { var _spr_w = sprite_get_width(spr_box1); var _spr_h = sprite_get_height(spr_box1); if (_spr_w > 0 && _spr_h > 0) { var _xscale = _list_box_w / _spr_w; var _yscale = _list_box_h / _spr_h; draw_sprite_ext(spr_box1, 0, _list_box_x, _list_box_y, _xscale, _yscale, 0, c_white, 0.9); } }
        if (_skill_count > 0) { for (var j = 0; j < _skill_count; j++) { var s = _skills_array[j]; if (!is_struct(s)) continue; var skill_name = variable_struct_exists(s, "name") ? s.name : "???"; var skill_cost = variable_struct_exists(s, "cost") ? s.cost : 0; var current_draw_y = list_y + j * list_line_h; if (j == _skill_index) { draw_set_color(list_select_color); draw_set_alpha(0.5); draw_rectangle(_list_box_x, current_draw_y - 2, _list_box_x + _list_box_w, current_draw_y + list_line_h - 2, false); draw_set_alpha(1.0); } draw_set_color(c_white); draw_text(list_x_base, current_draw_y, skill_name + " (MP " + string(skill_cost) + ")"); } } else { draw_set_color(c_white); draw_text(list_x_base, list_y, "No Skills"); }
    } else if (global.battle_state == "item_select") {
        draw_set_halign(fa_left); draw_set_valign(fa_top); var _usable_items = []; var _raw_inventory = (variable_global_exists("party_inventory") && is_array(global.party_inventory)) ? global.party_inventory : []; for (var i = 0; i < array_length(_raw_inventory); i++) { var entry = _raw_inventory[i]; if (!is_struct(entry) || !variable_struct_exists(entry, "item_key") || !variable_struct_exists(entry, "quantity") || entry.quantity <= 0) continue; var item_key = entry.item_key; var item_data = scr_GetItemData(item_key); if (is_struct(item_data) && variable_struct_exists(item_data, "usable_in_battle") && item_data.usable_in_battle) { array_push(_usable_items, { item_key: item_key, quantity: entry.quantity, name: item_data.name ?? "???" }); } }
        var _item_index = variable_struct_exists(active_p_data, "item_index") ? active_p_data.item_index : 0; var _usable_item_count = array_length(_usable_items); if (_usable_item_count == 0) { _item_index = -1; } else { _item_index = clamp(_item_index, 0, _usable_item_count - 1); }
        var _list_items_to_draw = _usable_item_count; var _list_box_h = (_list_items_to_draw * list_line_h) + list_padding * 2; if (_list_items_to_draw == 0) { _list_box_h = list_line_h + list_padding * 2; } var _list_box_x = list_x_base - list_padding; var _list_box_y = list_y - list_padding;
        if (sprite_exists(spr_box1)) { var _spr_w = sprite_get_width(spr_box1); var _spr_h = sprite_get_height(spr_box1); if (_spr_w > 0 && _spr_h > 0) { var _xscale = list_box_w / _spr_w; var _yscale = _list_box_h / _spr_h; draw_sprite_ext(spr_box1, 0, _list_box_x, _list_box_y, _xscale, _yscale, 0, c_white, 0.9); } }
        if (_usable_item_count > 0) { for (var j = 0; j < _usable_item_count; j++) { var usable_item_entry = _usable_items[j]; var inm = usable_item_entry.name; var iq = usable_item_entry.quantity; var current_draw_y = list_y + j * list_line_h; if (j == _item_index) { draw_set_color(list_select_color); draw_set_alpha(0.5); draw_rectangle(_list_box_x, current_draw_y - 2, _list_box_x + list_box_w, current_draw_y + list_line_h - 2, false); draw_set_alpha(1.0); } draw_set_color(c_white); draw_set_halign(fa_left); draw_text(list_x_base, current_draw_y, inm); draw_set_halign(fa_right); draw_text(list_x_base + list_item_w + list_padding, current_draw_y, "x" + string(iq)); draw_set_halign(fa_left); } }
        else { draw_set_color(c_white); draw_text(list_x_base, list_y, "No Usable Items"); }
    }
}

// --- Draw Target Cursor ---
if (global.battle_state == "TargetSelect") { if (variable_global_exists("battle_enemies") && ds_exists(global.battle_enemies, ds_type_list) && variable_global_exists("battle_target")) { var num_enemies = ds_list_size(global.battle_enemies); if (num_enemies > 0 && global.battle_target >= 0 && global.battle_target < num_enemies) { var _tid = global.battle_enemies[| global.battle_target]; if (instance_exists(_tid)) { var _tx = _tid.x; var _ty = _tid.bbox_top; var _coffy = 10; if (sprite_exists(spr_target_cursor)) { draw_sprite(spr_target_cursor, -1, _tx, _ty - _coffy); } else { draw_set_halign(fa_center); draw_set_valign(fa_bottom); draw_text_color(_tx, _ty - _coffy, "▼", c_yellow, c_yellow, c_yellow, c_yellow, 1); } } } } }

// === Reset draw state ===
draw_set_font(-1); draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_color(c_white); draw_set_alpha(1);