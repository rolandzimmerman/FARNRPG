/// obj_battle_menu :: Draw GUI
/// Draws battle UI elements. Reads data from obj_battle_player.data

// --- Basic Checks ---
if (!visible || image_alpha <= 0) exit;
if (!variable_global_exists("battle_state")) exit;

// --- Active Player Data Validation ---
var active_player_data_valid = false;
var active_p_inst = noone;
var active_p_data = noone;
var active_idx = -1;
if (variable_global_exists("active_party_member_index")
 && variable_global_exists("battle_party")
 && ds_exists(global.battle_party, ds_type_list)) {
    active_idx = global.active_party_member_index;
    var party_size = ds_list_size(global.battle_party);
    if (active_idx >= 0 && active_idx < party_size) {
        active_p_inst = global.battle_party[| active_idx];
        if (instance_exists(active_p_inst)
         && variable_instance_exists(active_p_inst, "data")
         && is_struct(active_p_inst.data)) {
            active_p_data = active_p_inst.data;
            if (variable_struct_exists(active_p_data, "hp")
             && variable_struct_exists(active_p_data, "mp")
             && variable_struct_exists(active_p_data, "name")) {
                active_player_data_valid = true;
            }
        }
    }
}

// === Constants ===
var party_hud_positions_x = [64, 320, 576, 832];
var party_hud_y          = 0;
var menu_cx              = 160;
var menu_cy              = 600;
var menu_r               = 80;
var button_scale         = 0.5;
var label_scale          = 0.5;
var label_rot            = 35;
var menu_y_offset        = 220;
var list_x_base          = menu_cx + menu_r + 80;
var list_y               = menu_cy - 80 + menu_y_offset;
var list_line_h          = 36;
var list_padding         = 8;
var list_item_w          = 240;
var list_qty_w           = 40;
var list_box_w           = list_item_w + list_qty_w + list_padding * 3;
var list_select_color    = c_yellow;

// === Set Font and Color ===
if (font_exists(Font1)) draw_set_font(Font1);
else draw_set_font(-1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// === Draw Party HP/MP/Overdrive HUDs ===
if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) {
    var party_size      = ds_list_size(global.battle_party);
    var _spr_hud_bg     = sprite_exists(spr_pc_hud_bg);
    var _spr_hp         = sprite_exists(spr_pc_hud_hp);
    var _spr_mp         = sprite_exists(spr_pc_hud_mp);
    var _spr_od         = sprite_exists(spr_pc_hud_od);
    var _spr_hp_w       = _spr_hp ? sprite_get_width(spr_pc_hud_hp) : 0;
    var _spr_hp_h       = _spr_hp ? sprite_get_height(spr_pc_hud_hp) : 0;
    var _spr_mp_w       = _spr_mp ? sprite_get_width(spr_pc_hud_mp) : 0;
    var _spr_mp_h       = _spr_mp ? sprite_get_height(spr_pc_hud_mp) : 0;
    var _spr_od_w       = _spr_od ? sprite_get_width(spr_pc_hud_od) : 0;
    var _spr_od_h       = _spr_od ? sprite_get_height(spr_pc_hud_od) : 0;

    for (var i = 0; i < party_size; i++) {
        if (i >= array_length(party_hud_positions_x)) continue;
        var x0   = party_hud_positions_x[i];
        var y0   = party_hud_y;
        var inst = global.battle_party[| i];
        if (!instance_exists(inst) || !variable_instance_exists(inst, "data") || !is_struct(inst.data)) continue;
        var d    = inst.data;
        var active = (i == active_idx);
        var alpha  = active ? 1 : 0.7;
        var tint   = active ? c_white : c_gray;

        // BG
        if (_spr_hud_bg) draw_sprite_ext(spr_pc_hud_bg, 0, x0, y0, 1, 1, 0, tint, alpha);

        // Name
        draw_set_alpha(alpha);
        draw_set_valign(fa_top);
        draw_text(x0 + 10, y0 + 3, d.name);

        // HP bar
        if (_spr_hp && variable_struct_exists(d, "hp") && variable_struct_exists(d, "maxhp")) {
            var r = clamp(d.hp / d.maxhp, 0, 1);
            var w = floor(_spr_hp_w * r);
            if (w > 0) draw_sprite_part_ext(spr_pc_hud_hp,0,0,0,w,_spr_hp_h, x0+32,y0+20,1,1,c_white,alpha);
        }
        draw_set_valign(fa_middle);
        draw_text(x0+35, y0+20+_spr_hp_h/2, string(floor(d.hp))+"/"+string(floor(d.maxhp)));
        draw_set_valign(fa_top);

        // MP bar
        if (_spr_mp && variable_struct_exists(d, "mp") && variable_struct_exists(d, "maxmp")) {
            var r2 = clamp(d.mp / d.maxmp, 0,1);
            var w2 = floor(_spr_mp_w * r2);
            if (w2 > 0) draw_sprite_part_ext(spr_pc_hud_mp,0,0,0,w2,_spr_mp_h, x0+32,y0+38,1,1,c_white,alpha);
        }
        draw_set_valign(fa_middle);
        draw_text(x0+35, y0+38+_spr_mp_h/2, string(floor(d.mp))+"/"+string(floor(d.maxmp)));
        draw_set_alpha(1);

        // Overdrive bar
        if (_spr_od && variable_struct_exists(d, "overdrive") && variable_struct_exists(d, "overdrive_max")) {
            var ro = clamp(d.overdrive / d.overdrive_max, 0,1);
            var wo = floor(_spr_od_w * ro);
            if (wo > 0) {
                var xo = x0+32;
                var yo = y0+38+_spr_mp_h+4;
                draw_sprite_part_ext(spr_pc_hud_od,0,0,0,wo,_spr_od_h, xo,yo,1,1,c_white,alpha);
            }
        }
    }
}

// === Main Command / Skill / Item Menus ===
draw_set_color(c_white);

if (active_player_data_valid) {
    // Player Input menu
    if (global.battle_state == "player_input") {
        if (sprite_exists(Abutton)) draw_sprite_ext(Abutton,0,97,619+menu_y_offset,button_scale,button_scale,0,c_white,1);
        if (sprite_exists(Bbutton)) draw_sprite_ext(Bbutton,0,147,557+menu_y_offset,button_scale,button_scale,0,c_white,1);
        if (sprite_exists(Xbutton)) draw_sprite_ext(Xbutton,0,48,559+menu_y_offset,button_scale,button_scale,0,c_white,1);
        if (sprite_exists(Ybutton)) draw_sprite_ext(Ybutton,0,97,501+menu_y_offset,button_scale,button_scale,0,c_white,1);
        if (sprite_exists(spr_attack))  draw_sprite_ext(spr_attack,0,-5.83,687.83+menu_y_offset,label_scale,label_scale,label_rot,c_white,1);
        if (sprite_exists(spr_defend))  draw_sprite_ext(spr_defend,0,195.92,563.76+menu_y_offset,label_scale,label_scale,label_rot,c_white,1);
        if (sprite_exists(spr_special)) draw_sprite_ext(spr_special,0,-14.91,563.75+menu_y_offset,label_scale,label_scale,label_rot,c_white,1);
        if (sprite_exists(spr_items))   draw_sprite_ext(spr_items,0,133,497.68+menu_y_offset,label_scale,label_scale,label_rot,c_white,1);
    }

    // Skill selection
    else if (global.battle_state == "skill_select") {
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        var skills = (variable_struct_exists(active_p_data,"skills") && is_array(active_p_data.skills))
                   ? active_p_data.skills : [];
        var sel    = variable_struct_exists(active_p_data,"skill_index")
                   ? active_p_data.skill_index : 0;
        var cnt    = array_length(skills);
        sel = (cnt>0) ? clamp(sel,0,cnt-1) : -1;

        var box_h = cnt*list_line_h + list_padding*2;
        if (cnt==0) box_h = list_line_h + list_padding*2;
        var box_x = list_x_base - list_padding;
        var box_y = list_y - list_padding;

        if (sprite_exists(spr_box1)) {
            var sw = sprite_get_width(spr_box1), sh = sprite_get_height(spr_box1);
            draw_sprite_ext(spr_box1,0,box_x,box_y,list_box_w/sw,box_h/sh,0,c_white,0.9);
        }

        if (cnt>0) {
            for (var j=0; j<cnt; j++) {
                var sk = skills[j];
                if (!is_struct(sk)) continue;
                var nm = sk.name ?? "???";
                var cs = sk.cost ?? 0;
                var yj = list_y + j*list_line_h;

                if (j==sel) {
                    draw_set_color(list_select_color);
                    draw_set_alpha(0.5);
                    draw_rectangle(box_x,yj-2,box_x+list_box_w,yj+list_line_h-2,false);
                    draw_set_alpha(1);
                }
                if (variable_struct_exists(sk,"overdrive") && sk.overdrive) {
                    draw_set_color(active_p_data.overdrive < active_p_data.overdrive_max ? c_gray : c_white);
                } else draw_set_color(c_white);

                draw_text(list_x_base,yj, nm + " (MP " + string(cs) + ")");
            }
        } else {
            draw_set_color(c_white);
            draw_text(list_x_base,list_y,"No Skills");
        }
    }

    // Item selection
    else if (global.battle_state == "item_select") {
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        var items = (variable_global_exists("battle_usable_items") && is_array(global.battle_usable_items))
                  ? global.battle_usable_items : [];
        var cnt   = array_length(items);

        var box_h = cnt*list_line_h + list_padding*2;
        if (cnt==0) box_h = list_line_h + list_padding*2;
        var box_x = list_x_base - list_padding;
        var box_y = list_y - list_padding;

        if (sprite_exists(spr_box1)) {
            var sw = sprite_get_width(spr_box1), sh = sprite_get_height(spr_box1);
            draw_sprite_ext(spr_box1,0,box_x,box_y,list_box_w/sw,box_h/sh,0,c_white,0.9);
        }

        if (cnt>0) {
            for (var j=0; j<cnt; j++) {
                var it = items[j];
                var nm = it.name ?? "???";
                var qt = it.quantity;
                var yj = list_y + j*list_line_h;

                if (j == active_p_data.item_index) {
                    draw_set_color(list_select_color);
                    draw_set_alpha(0.5);
                    draw_rectangle(box_x,yj-2,box_x+list_box_w,yj+list_line_h-2,false);
                    draw_set_alpha(1);
                }
                draw_set_color(c_white);
                draw_text(list_x_base,yj, nm);
                draw_set_halign(fa_right);
                draw_text(list_x_base+list_item_w+list_padding,yj,"x"+string(qt));
                draw_set_halign(fa_left);
            }
        } else {
            draw_set_color(c_white);
            draw_text(list_x_base,list_y,"No Usable Items");
        }
    }
}

// --- Draw Target Cursor ---
if (global.battle_state == "TargetSelect"
 && variable_global_exists("battle_enemies")
 && ds_exists(global.battle_enemies, ds_type_list)
 && variable_global_exists("battle_target")) {
    var n = ds_list_size(global.battle_enemies);
    if (n>0 && global.battle_target>=0 && global.battle_target<n) {
        var tid = global.battle_enemies[| global.battle_target];
        if (instance_exists(tid)) {
            var tx = tid.x, ty = tid.bbox_top, off = 10;
            if (sprite_exists(spr_target_cursor)) draw_sprite(spr_target_cursor,-1,tx,ty-off);
            else {
                draw_set_halign(fa_center);
                draw_set_valign(fa_bottom);
                draw_text_color(tx,ty-off,"▼",c_yellow,c_yellow,c_yellow,c_yellow,1);
            }
        }
    }
}

// === Reset draw state ===
draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);
