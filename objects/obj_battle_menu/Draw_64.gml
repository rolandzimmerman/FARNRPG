/// obj_battle_menu :: Draw GUI
// Draws UI elements for ALL party members, menus, and handles target cursor.

// --- Basic Checks & Active Player Data Validation ---
if (!visible || image_alpha <= 0) exit;
if (!variable_global_exists("battle_state")) exit; // Need battle state

var active_player_data_valid = false;
var active_p_inst = noone;
var active_p_data = noone; // This will hold the data struct of the active player
var active_idx = -1;

// Find the active player instance and their data
if (variable_global_exists("active_party_member_index")) {
    active_idx = global.active_party_member_index;
    if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) {
        var party_size = ds_list_size(global.battle_party);
        if (active_idx >= 0 && active_idx < party_size) {
            active_p_inst = global.battle_party[| active_idx];
            if (instance_exists(active_p_inst)) {
                if (variable_instance_exists(active_p_inst,"data") && is_struct(active_p_inst.data)) {
                     active_p_data = active_p_inst.data; // Get the active player's data struct
                     // Check for essential stats needed by this object's drawing code
                     if (variable_struct_exists(active_p_data, "hp") && variable_struct_exists(active_p_data, "mp")) {
                          active_player_data_valid = true;
                     }
                }
            }
        }
    }
}
// --- End Validation ---


// === Constants ===
var hud_x=24;var hud_y=24;var bar_w=200;var bar_h=18;var bar_spacing=4;var party_bar_y_spacing=bar_h*2+bar_spacing+10;var menu_cx=160;var menu_cy=600;var menu_r=80;var button_scale=0.5;var label_scale=0.5;var label_rot=35;var menu_y_offset=220;var list_x=menu_cx+menu_r+80;var list_y=menu_cy-80;var list_w=240;var list_h=36;var list_select_color=c_yellow;var item_list_w_adj=40;var item_select_color=list_select_color;

// === Set Font ===
if (font_exists(Font1)) draw_set_font(Font1); else draw_set_font(-1);


// === Draw Party HP/MP Bars ===
draw_set_halign(fa_left);draw_set_valign(fa_top);var current_hud_y=hud_y;if(variable_global_exists("battle_party")&&ds_exists(global.battle_party,ds_type_list)){var party_size=ds_list_size(global.battle_party);for(var i=0;i<party_size;i++){var p_inst=global.battle_party[|i];if(instance_exists(p_inst)&&variable_instance_exists(p_inst,"data")&&is_struct(p_inst.data)){var p_data=p_inst.data;var is_active_member=(i==active_idx);var bar_alpha=is_active_member?1.0:0.6;draw_set_color(is_active_member?c_white:c_gray);draw_set_alpha(bar_alpha);draw_text(hud_x,current_hud_y,p_data.name);var name_h=string_height("Wg");var bar_start_y=current_hud_y+name_h+2;var _hp=p_data.hp;var _maxhp=p_data.maxhp;var hp_ratio=(_maxhp>0)?(_hp/_maxhp):0;draw_set_color(c_dkgray);draw_set_alpha(0.7*bar_alpha);draw_rectangle(hud_x,bar_start_y,hud_x+bar_w,bar_start_y+bar_h,false);draw_set_color(c_red);draw_set_alpha(0.8*bar_alpha);draw_rectangle(hud_x,bar_start_y,hud_x+floor(bar_w*hp_ratio),bar_start_y+bar_h,false);draw_set_color(c_white);draw_set_alpha(bar_alpha);draw_set_valign(fa_middle);draw_text(hud_x+4,bar_start_y+bar_h/2,string(floor(_hp))+"/"+string(floor(_maxhp)));draw_set_valign(fa_top);var mp_bar_y=bar_start_y+bar_h+bar_spacing;var _mp=p_data.mp;var _maxmp=p_data.maxmp;var mp_ratio=(_maxmp>0)?(_mp/_maxmp):0;draw_set_color(c_dkgray);draw_set_alpha(0.7*bar_alpha);draw_rectangle(hud_x,mp_bar_y,hud_x+bar_w,mp_bar_y+bar_h,false);draw_set_color(c_blue);draw_set_alpha(0.8*bar_alpha);draw_rectangle(hud_x,mp_bar_y,hud_x+floor(bar_w*mp_ratio),mp_bar_y+bar_h,false);draw_set_color(c_white);draw_set_alpha(bar_alpha);draw_set_valign(fa_middle);draw_text(hud_x+4,mp_bar_y+bar_h/2,string(floor(_mp))+"/"+string(floor(_maxmp)));draw_set_valign(fa_top);current_hud_y=mp_bar_y+bar_h+party_bar_y_spacing;}}}


// === Main Command Menu (Radial), Skill Menu, Item Menu OR Target Cursor ===
draw_set_color(c_white); draw_set_alpha(1);

// Draw menus ONLY if active player data is valid
if (active_player_data_valid) {
    if (global.battle_state == "player_input") {
        // --- Draw Radial Menu ---
        // show_debug_message("Battle Menu Draw: Drawing Radial Menu"); // Optional Debug
        if(sprite_exists(Abutton))draw_sprite_ext(Abutton,0,97,619+menu_y_offset,button_scale,button_scale,0,c_white,1);
        if(sprite_exists(Bbutton))draw_sprite_ext(Bbutton,0,147,557+menu_y_offset,button_scale,button_scale,0,c_white,1);
        if(sprite_exists(Xbutton))draw_sprite_ext(Xbutton,0,48,559+menu_y_offset,button_scale,button_scale,0,c_white,1);
        if(sprite_exists(Ybutton))draw_sprite_ext(Ybutton,0,97,501+menu_y_offset,button_scale,button_scale,0,c_white,1);
        if(sprite_exists(spr_attack))draw_sprite_ext(spr_attack,0,-5.83,687.83+menu_y_offset,label_scale,label_scale,label_rot,c_white,1);
        if(sprite_exists(spr_defend))draw_sprite_ext(spr_defend,0,195.92,563.76+menu_y_offset,label_scale,label_scale,label_rot,c_white,1);
        if(sprite_exists(spr_special))draw_sprite_ext(spr_special,0,-14.91,563.75+menu_y_offset,label_scale,label_scale,label_rot,c_white,1);
        if(sprite_exists(spr_items))draw_sprite_ext(spr_items,0,133,497.68+menu_y_offset,label_scale,label_scale,label_rot,c_white,1);
    }
    else if (global.battle_state == "skill_select") {
        // --- Draw Skill List ---
        show_debug_message("Battle Menu Draw: Drawing Skill List"); // DEBUG
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        var _skills_array = (variable_struct_exists(active_p_data, "skills") && is_array(active_p_data.skills)) ? active_p_data.skills : [];
        var _skill_index = variable_struct_exists(active_p_data, "skill_index") ? active_p_data.skill_index : 0;
        var _current_mp = active_p_data.mp;
        if (array_length(_skills_array) > 0) {
            for (var i = 0; i < array_length(_skills_array); i++) {
                var s = _skills_array[i]; if (!is_struct(s)) continue;
                var skill_name = variable_struct_exists(s, "name") ? s.name : "???";
                var skill_cost = variable_struct_exists(s, "cost") ? s.cost : 0;
                var current_y = list_y + i * list_h;
                // Highlight
                if (i == _skill_index) {
                    draw_set_color(list_select_color); draw_set_alpha(0.5);
                    draw_rectangle(list_x - 6, current_y - 2, list_x + list_w + 6, current_y + list_h - 2, false);
                    draw_set_alpha(1);
                }
                // Text (Dim if not enough MP)
                var display_color = (_current_mp < skill_cost) ? c_gray : c_white;
                draw_set_color(display_color);
                draw_text(list_x, current_y, skill_name + " (MP " + string(skill_cost) + ")");
            }
        } else {
            draw_set_color(c_gray);
            draw_text(list_x, list_y, "No Skills");
        }
    } // <<< END of skill_select drawing
    else if (global.battle_state == "item_select") {
        // --- Draw Item List ---
        show_debug_message("Battle Menu Draw: Drawing Item List"); // DEBUG
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        var _inventory = []; if (instance_exists(obj_player) && variable_instance_exists(obj_player, "inventory") && is_array(obj_player.inventory)) { _inventory = obj_player.inventory; }
        var _item_index = variable_struct_exists(active_p_data, "item_index") ? active_p_data.item_index : 0;
        if (array_length(_inventory) > 0) {
            for (var i = 0; i < array_length(_inventory); i++) {
                var ie=_inventory[i]; if (!is_struct(ie)) continue;
                var ik=variable_struct_exists(ie,"item_key")?ie.item_key:undefined; var iq=variable_struct_exists(ie,"quantity")?ie.quantity:0; if (is_undefined(ik)||iq<=0) continue;
                var idf=scr_GetItemData(ik); var inm=is_struct(idf)?idf.name:"???";
                var current_y = list_y + i * list_h;
                // Highlight
                if (i == _item_index) {
                    draw_set_color(item_select_color); draw_set_alpha(0.5);
                    draw_rectangle(list_x - 6, current_y - 2, list_x + list_w + item_list_w_adj + 6, current_y + list_h - 2, false);
                    draw_set_alpha(1);
                }
                // Text
                var tx=list_x; draw_set_color(c_white);
                draw_text(tx, current_y, inm);
                draw_set_halign(fa_right);
                draw_text(list_x + list_w + item_list_w_adj, current_y, "x" + string(iq));
                draw_set_halign(fa_left); // Reset alignment
            }
        } else {
            draw_set_color(c_gray);
            draw_text(list_x, list_y, "No Items");
        }
    } // <<< END of item_select drawing
} // End check for active_player_data_valid for menus

// Target cursor drawn only in TargetSelect state
if (global.battle_state == "TargetSelect") {
    // --- Draw Target Indicator Cursor ---
     var num_enemies = ds_list_size(global.battle_enemies);
     if (num_enemies > 0 && global.battle_target >= 0 && global.battle_target < num_enemies) {
         var _tid = global.battle_enemies[| global.battle_target];
         if (instance_exists(_tid)) {
             var _tx = _tid.x; var _ty = _tid.bbox_top; var _coffy = 10;
             if (sprite_exists(spr_target_cursor)) { draw_sprite(spr_target_cursor, 0, _tx, _ty - _coffy); }
             else { draw_set_halign(fa_center); draw_set_valign(fa_bottom); draw_text_color(_tx, _ty - _coffy, "▼", c_yellow, c_yellow, c_yellow, c_yellow, 1); }
         }
     }
}


// === Reset draw state ===
draw_set_font(-1); draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_color(c_white); draw_set_alpha(1);