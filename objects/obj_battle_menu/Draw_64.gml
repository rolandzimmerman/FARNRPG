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
// --- NEW: Fixed positions for Party Member HUDs ---
var party_hud_positions_x = [64, 320, 576, 832];
var party_hud_y = 0; // Fixed Y position for all HUDs
// ---

var menu_cx=160;var menu_cy=600;var menu_r=80;var button_scale=0.5;var label_scale=0.5;var label_rot=35;var menu_y_offset=220;var list_x=menu_cx+menu_r+80;var list_y=menu_cy-80;var list_w=240;var list_h=36;var list_select_color=c_yellow;var item_list_w_adj=40;var item_select_color=list_select_color;

// === Set Font ===
if (font_exists(Font1)) draw_set_font(Font1); else draw_set_font(-1);


// === Draw Party HP/MP Bars using Sprites ===
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var _spr_hud_bg_exists = sprite_exists(spr_pc_hud_bg);
var _spr_hp_exists = sprite_exists(spr_pc_hud_hp);
var _spr_mp_exists = sprite_exists(spr_pc_hud_mp);

// Get sprite dimensions IF they exist (used for positioning and drawing parts)
var _spr_hp_w = _spr_hp_exists ? sprite_get_width(spr_pc_hud_hp) : 0;
var _spr_hp_h = _spr_hp_exists ? sprite_get_height(spr_pc_hud_hp) : 0;
var _spr_mp_w = _spr_mp_exists ? sprite_get_width(spr_pc_hud_mp) : 0;
var _spr_mp_h = _spr_mp_exists ? sprite_get_height(spr_pc_hud_mp) : 0;

if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) {
    var party_size = ds_list_size(global.battle_party);
    for (var i = 0; i < party_size; i++) {

        // --- Get the specific X position for this party member ---
        if (i >= array_length(party_hud_positions_x)) {
             show_debug_message("Warning: More party members than defined HUD positions!");
             continue; // Skip drawing this member if no position is defined
        }
        var current_member_hud_x = party_hud_positions_x[i];
        var current_member_hud_y = party_hud_y; // Use the fixed Y
        // ---

        var p_inst = global.battle_party[| i];
        if (instance_exists(p_inst) && variable_instance_exists(p_inst, "data") && is_struct(p_inst.data)) {
            var p_data = p_inst.data;
            var is_active_member = (i == active_idx);
            var bar_alpha = is_active_member ? 1.0 : 0.7;
            var text_color = is_active_member ? c_white : c_gray;
            var bg_tint = is_active_member ? c_white : c_gray;

            // --- Offsets set to 0 as requested ---
            // This will make the HP/MP bars draw starting at the exact same (X,Y)
            // as the background, causing overlap. This is probably NOT visually correct.
            // You likely need to determine the *actual* relative offsets based
            // on your spr_pc_hud_bg graphic layout.
            var name_rel_x = 10;     var name_rel_y = 3; // Adjust name position as needed

            var hp_bar_rel_x = 32;    var hp_bar_rel_y = 0; // Bar starts at BG's top-left
            var hp_text_rel_x = 3;   // Position text relative to the bar's start (now 0,0)
            var hp_text_rel_y = 32;//(_spr_hp_h / 2);

            var mp_bar_rel_x = 32;    var mp_bar_rel_y = 0; // Bar starts at BG's top-left
            var mp_text_rel_x = 3;   // Position text relative to the bar's start (now 0,0)
            var mp_text_rel_y = 48; //(_spr_mp_h / 2); // This will likely overlap HP text
            // --- End Adjustments ---

            // 1. Draw Background Sprite
            if (_spr_hud_bg_exists) {
                draw_sprite_ext(spr_pc_hud_bg, 0, current_member_hud_x, current_member_hud_y, 1, 1, 0, bg_tint, bar_alpha);
            } else {
                // Fallback rectangle
                draw_set_color(c_dkgray); draw_set_alpha(0.5 * bar_alpha);
                draw_rectangle(current_member_hud_x, current_member_hud_y, current_member_hud_x + 220, current_member_hud_y + 70, false);
                draw_set_alpha(bar_alpha);
            }

            // 2. Draw Name (Positioned relative to BG start)
            draw_set_color(text_color);
            draw_set_alpha(bar_alpha);
            draw_set_valign(fa_top);
            draw_text(current_member_hud_x + name_rel_x, current_member_hud_y + name_rel_y, p_data.name);

            // 3. Draw HP Bar Sprite (Partial) - Starts at current_member_hud_x, current_member_hud_y
            if (_spr_hp_exists) {
                 var _hp = p_data.hp;
                 var _maxhp = p_data.maxhp;
                 var hp_ratio = (_maxhp > 0) ? clamp(_hp / _maxhp, 0, 1) : 0;
                 var hp_draw_w = floor(_spr_hp_w * hp_ratio);

                 if (hp_draw_w > 0) {
                    draw_sprite_part_ext(spr_pc_hud_hp, 0,
                                         0, 0, hp_draw_w, _spr_hp_h,
                                         current_member_hud_x + hp_bar_rel_x, // rel_x is 0
                                         current_member_hud_y + hp_bar_rel_y, // rel_y is 0
                                         1, 1, c_white, bar_alpha);
                 }
            }

            // 4. Draw HP Text (Positioned relative to where HP bar starts - now 0,0 relative)
            draw_set_color(text_color);
            draw_set_alpha(bar_alpha);
            draw_set_valign(fa_middle); // Center text vertically
            draw_text(current_member_hud_x + hp_text_rel_x, current_member_hud_y + hp_text_rel_y, string(floor(_hp)) + "/" + string(floor(_maxhp)));
            draw_set_valign(fa_top); // Reset valign

            // 5. Draw MP Bar Sprite (Partial) - Starts at current_member_hud_x, current_member_hud_y
             if (_spr_mp_exists) {
                 var _mp = p_data.mp;
                 var _maxmp = p_data.maxmp;
                 var mp_ratio = (_maxmp > 0) ? clamp(_mp / _maxmp, 0, 1) : 0;
                 var mp_draw_w = floor(_spr_mp_w * mp_ratio);

                 if (mp_draw_w > 0) {
                     draw_sprite_part_ext(spr_pc_hud_mp, 0,
                                          0, 0, mp_draw_w, _spr_mp_h,
                                          current_member_hud_x + mp_bar_rel_x, // rel_x is 0
                                          current_member_hud_y + mp_bar_rel_y, // rel_y is 0
                                          1, 1, c_white, bar_alpha);
                 }
             }

            // 6. Draw MP Text (Positioned relative to where MP bar starts - now 0,0 relative - likely overlaps HP text)
            draw_set_color(text_color);
            draw_set_alpha(bar_alpha);
            draw_set_valign(fa_middle); // Center text vertically
            draw_text(current_member_hud_x + mp_text_rel_x, current_member_hud_y + mp_text_rel_y, string(floor(_mp)) + "/" + string(floor(_maxmp)));
            draw_set_valign(fa_top); // Reset valign
        }
    }
}


// === Main Command Menu (Radial), Skill Menu, Item Menu OR Target Cursor ===
// (Rest of your menu/cursor drawing code remains unchanged)
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
            for (var j = 0; j < array_length(_skills_array); j++) {
                var s = _skills_array[j]; if (!is_struct(s)) continue;
                var skill_name = variable_struct_exists(s, "name") ? s.name : "???";
                var skill_cost = variable_struct_exists(s, "cost") ? s.cost : 0;
                var current_y = list_y + j * list_h;
                // Highlight
                if (j == _skill_index) {
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
            for (var j = 0; j < array_length(_inventory); j++) {
                var ie=_inventory[j]; if (!is_struct(ie)) continue;
                var ik=variable_struct_exists(ie,"item_key")?ie.item_key:undefined; var iq=variable_struct_exists(ie,"quantity")?ie.quantity:0; if (is_undefined(ik)||iq<=0) continue;
                var idf=scr_GetItemData(ik); var inm=is_struct(idf)?idf.name:"???";
                var current_y = list_y + j * list_h;
                // Highlight
                if (j == _item_index) {
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