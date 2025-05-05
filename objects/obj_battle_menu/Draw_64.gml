/// obj_battle_menu :: Draw GUI
/// Draws battle UI elements. Reads data from obj_battle_player.data and turn order from obj_battle_manager. Uses global string states.

// --- Basic Checks ---
if (!visible || image_alpha <= 0) exit;
// Check if manager exists
if (!instance_exists(obj_battle_manager)) exit;
// Use the global string state
if (!variable_global_exists("battle_state")) exit; // Exit if state var doesn't exist
var _current_battle_state = global.battle_state; // Read the global string state

// --- Active Player Data Validation ---
// Use global.active_party_member_index which manager updates when a player turn starts
var active_player_data_valid = false;
var active_p_inst = noone;
var active_p_data = noone;
var active_idx = -1; // Local index for highlighting HUD

if (variable_global_exists("active_party_member_index") 
 && variable_global_exists("battle_party")
 && ds_exists(global.battle_party, ds_type_list)) {
    
    // Use the index set by the manager
    active_idx = global.active_party_member_index; 
    var party_size = ds_list_size(global.battle_party);

    if (active_idx >= 0 && active_idx < party_size) {
        active_p_inst = global.battle_party[| active_idx];
        
        // Validate instance and data for drawing menus
        if (instance_exists(active_p_inst)
         && variable_instance_exists(active_p_inst, "data")
         && is_struct(active_p_inst.data)) {
            active_p_data = active_p_inst.data;
            // Check necessary fields exist for drawing
            if (variable_struct_exists(active_p_data, "hp")
             && variable_struct_exists(active_p_data, "mp")
             && variable_struct_exists(active_p_data, "name")
             && variable_struct_exists(active_p_data, "skills") 
             && variable_struct_exists(active_p_data, "skill_index") 
             && variable_struct_exists(active_p_data, "item_index") // Ensure item_index exists if item menu needs it
             ) {
                active_player_data_valid = true;
            }
        }
    }
}
// If not in a state where a player index is set, active_idx remains -1, active_p_inst is noone.

// === Constants === (Keep your existing constants)
var party_hud_positions_x = [64, 320, 576, 832];
var party_hud_y           = 0;
var menu_cx               = 160;
var menu_cy               = 600;
var menu_r                = 80;
var button_scale          = 0.5;
var label_scale           = 0.5;
var label_rot             = 35;
var menu_y_offset         = 220;
var list_x_base           = menu_cx + menu_r + 80;
var list_y                = menu_cy - 80 + menu_y_offset;
var list_line_h           = 36;
var list_padding          = 8;
var list_item_w           = 240;
var list_qty_w            = 40;
var list_box_w            = list_item_w + list_qty_w + list_padding * 3;
var list_select_color     = c_yellow;
var target_cursor_sprite  = spr_target_cursor; // Assign your actual cursor sprite asset here
var target_cursor_y_offset= -20; // Adjust this value (-20 = 20 pixels above) to position cursor correctly

// Turn Order Display Constants
var turn_order_x = display_get_gui_width() - 200; // Position from right edge
var turn_order_y = 10; // Position from top edge
var turn_order_spacing = 40;
var turn_order_icon_size = 32; // Size to draw icons/portraits

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
        
        // Highlight based on the active_idx which manager updates
        var active = (i == active_idx); 
        var alpha  = active ? 1 : 0.7;
        var tint   = active ? c_white : c_gray;
        
        if (d.hp <= 0) { alpha *= 0.5; tint = merge_color(tint, c_dkgray, 0.5); }

        if (_spr_hud_bg) draw_sprite_ext(spr_pc_hud_bg, 0, x0, y0, 1, 1, 0, tint, alpha);
        draw_set_alpha(alpha); draw_set_valign(fa_top);
        draw_text_color(x0 + 10, y0, d.name ?? "???", tint, tint, tint, tint, alpha); 

        // HP bar / Text 
        if (_spr_hp && variable_struct_exists(d, "hp") && variable_struct_exists(d, "maxhp")) {
            var r  = clamp(d.hp / max(1,d.maxhp), 0, 1);
            var w  = floor(_spr_hp_w * r);
            if (w > 0) {
                draw_sprite_part_ext(
                    spr_pc_hud_hp, 0,
                    0, 0,          // from its top‐left
                    w, _spr_hp_h,  // width proportion, full height
                    x0 + 32,       // HP X
                    y0,       // HP Y
                    1, 1,
                    c_white, alpha
                );
            }
        }
        draw_set_valign(fa_middle);
        draw_text_color(
            x0 + 180, 
            y0 -16 + _spr_hp_h/2,
            string(floor(d.hp)) + "/" + string(floor(d.maxhp)),
            tint, tint, tint, tint, alpha
        );
        draw_set_valign(fa_top);

        // MP bar / Text
        // --- Position matched to HP bar (same X,Y) ---
        if (_spr_mp && variable_struct_exists(d, "mp") && variable_struct_exists(d, "maxmp")) {
            var r2  = clamp(d.mp / max(1,d.maxmp), 0, 1);
            var w2  = floor(_spr_mp_w * r2);
            if (w2 > 0) {
                draw_sprite_part_ext(
                    spr_pc_hud_mp, 0,
                    0, 0,            // from its top‐left
                    w2, _spr_mp_h,   // width proportion, full height
                    x0 + 32,         // **MP X now same as HP X**
                    y0,         // **MP Y now same as HP Y**
                    1, 1,
                    c_white, alpha
                );
            }
        }
        draw_set_valign(fa_middle);
        draw_text_color(
            x0 + 180,
            y0 + _spr_mp_h/2, // **MP text Y matches HP text Y**
            string(floor(d.mp)) + "/" + string(floor(d.maxmp)),
            tint, tint, tint, tint, alpha
        );
        draw_set_valign(fa_top);

        // Overdrive bar: static first frame while filling, animate when full
        // --- Position matched to HP bar (same X,Y) ---
        if (_spr_od
         && variable_struct_exists(d, "overdrive")
         && variable_struct_exists(d, "overdrive_max")) {
            
            // Fill ratio
            var ro    = clamp(d.overdrive / max(1, d.overdrive_max), 0, 1);
            var xo    = x0 + 32;  // **OD X same as HP X**
            var yo    = y0;  // **OD Y same as HP Y**
            
            if (ro < 1) {
                // Partial fill of the **first** frame
                var wo = floor(_spr_od_w * ro);
                if (wo > 0) {
                    draw_sprite_part_ext(
                        spr_pc_hud_od,  // sprite
                        0,               // subimage 0 = first frame
                        0, 0,           // from its top‐left
                        wo, _spr_od_h,  // width = wo, full height
                        xo, yo,         // draw at same coords as HP bar
                        1, 1,           // no scaling
                        c_white, alpha  // normal tint/alpha
                    );
                }
            } else {
                // Full gauge → play the full animation
                var num   = sprite_get_number(spr_pc_hud_od);
                // advance one frame per 100 ms
                var frame = (current_time div 100) mod num;
                draw_sprite_ext(
                    spr_pc_hud_od,
                    frame,
                    xo, yo,    // **OD anim at same coords as HP bar**
                    1, 1,
                    0,
                    c_white, alpha
                );
            }
        }

        draw_set_alpha(1); // Reset alpha after each HUD element
    }
}

// === Main Command / Skill / Item Menues ===
draw_set_color(c_white);

// Only draw menus if it's a valid player's turn and data is good
if (active_player_data_valid && active_p_inst != noone) {
    // Player Input menu (Use global string state)
    if (_current_battle_state == "player_input") { // <<< Use string state
        // Your existing drawing logic for buttons/labels is fine
        if (sprite_exists(Abutton)) draw_sprite_ext(Abutton,0,97,619+menu_y_offset,button_scale,button_scale,0,c_white,1);
        if (sprite_exists(Bbutton)) draw_sprite_ext(Bbutton,0,147,557+menu_y_offset,button_scale,button_scale,0,c_white,1);
        if (sprite_exists(Xbutton)) draw_sprite_ext(Xbutton,0,48,559+menu_y_offset,button_scale,button_scale,0,c_white,1);
        if (sprite_exists(Ybutton)) draw_sprite_ext(Ybutton,0,97,501+menu_y_offset,button_scale,button_scale,0,c_white,1);
        if (sprite_exists(spr_attack))  draw_sprite_ext(spr_attack,0,-5.83,687.83+menu_y_offset,label_scale,label_scale,label_rot,c_white,1);
        if (sprite_exists(spr_defend))  draw_sprite_ext(spr_defend,0,195.92,563.76+menu_y_offset,label_scale,label_scale,label_rot,c_white,1);
        if (sprite_exists(spr_special)) draw_sprite_ext(spr_special,0,-14.91,563.75+menu_y_offset,label_scale,label_scale,label_rot,c_white,1);
        if (sprite_exists(spr_items))   draw_sprite_ext(spr_items,0,133,497.68+menu_y_offset,label_scale,label_scale,label_rot,c_white,1);
    }

    // Skill selection (Use global string state)
    else if (_current_battle_state == "skill_select") { // <<< Use string state
        // Your existing drawing logic for skill list is fine, using active_p_data
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        var skills = (variable_struct_exists(active_p_data,"skills") && is_array(active_p_data.skills)) ? active_p_data.skills : [];
        var sel    = variable_struct_exists(active_p_data,"skill_index") ? active_p_data.skill_index : 0;
        var cnt    = array_length(skills);
        sel = (cnt>0) ? clamp(sel,0,cnt-1) : -1;
        var box_h = cnt*list_line_h + list_padding*2; if (cnt==0) box_h = list_line_h + list_padding*2; var box_x = list_x_base - list_padding; var box_y = list_y - list_padding;
        if (sprite_exists(spr_box1)) { var sw = sprite_get_width(spr_box1), sh = sprite_get_height(spr_box1); draw_sprite_ext(spr_box1,0,box_x,box_y,list_box_w/sw,box_h/sh,0,c_white,0.9); }
        if (cnt>0) { for (var j=0; j<cnt; j++) { var sk = skills[j]; if (!is_struct(sk)) continue; var nm = sk.name ?? "???"; var cs = sk.cost ?? 0; var yj = list_y + j*list_line_h; if (j==sel) { draw_set_color(list_select_color); draw_set_alpha(0.5); draw_rectangle(box_x,yj-2,box_x+list_box_w,yj+list_line_h-2,false); draw_set_alpha(1); } var can_afford = true; if (variable_struct_exists(sk,"overdrive") && sk.overdrive) { can_afford = (active_p_data.overdrive >= active_p_data.overdrive_max); } else { can_afford = (active_p_data.mp >= cs); } draw_set_color(can_afford ? c_white : c_gray); draw_text(list_x_base,yj, nm + " (MP " + string(cs) + ")"); } } else { draw_set_color(c_white); draw_text(list_x_base,list_y,"No Skills"); }
        draw_set_alpha(1); draw_set_color(c_white); 
    }

    // Item selection (Use global string state)
    else if (_current_battle_state == "item_select") { // <<< Use string state
        // Your existing item list drawing logic is fine, using active_p_data and global.battle_usable_items
         draw_set_halign(fa_left); draw_set_valign(fa_top);
         var items = (variable_global_exists("battle_usable_items") && is_array(global.battle_usable_items)) ? global.battle_usable_items : [];
         var cnt   = array_length(items);
         var sel   = variable_struct_exists(active_p_data,"item_index") ? active_p_data.item_index : 0; 
         sel = (cnt>0) ? clamp(sel, 0, cnt-1) : -1;
         
         var box_h = cnt*list_line_h + list_padding*2; if (cnt==0) box_h = list_line_h + list_padding*2; var box_x = list_x_base - list_padding; var box_y = list_y - list_padding;
         if (sprite_exists(spr_box1)) { var sw = sprite_get_width(spr_box1), sh = sprite_get_height(spr_box1); draw_sprite_ext(spr_box1,0,box_x,box_y,list_box_w/sw,box_h/sh,0,c_white,0.9); }
         if (cnt>0) { for (var j=0; j<cnt; j++) { var it = items[j]; var nm = it.name ?? "???"; var qt = it.quantity; var yj = list_y + j*list_line_h; if (j == sel) { draw_set_color(list_select_color); draw_set_alpha(0.5); draw_rectangle(box_x,yj-2,box_x+list_box_w,yj+list_line_h-2,false); draw_set_alpha(1); } draw_set_color(c_white); draw_text(list_x_base,yj, nm); draw_set_halign(fa_right); draw_text(list_x_base+list_item_w+list_padding,yj,"x"+string(qt)); draw_set_halign(fa_left); } } else { draw_set_color(c_white); draw_text(list_x_base,list_y,"No Usable Items"); }
         draw_set_alpha(1); draw_set_color(c_white); 
    }
}

// --- Draw Target Cursor --- (Use global string state)
if (_current_battle_state == "TargetSelect" // <<< Use string state
 && variable_global_exists("battle_enemies")
 && ds_exists(global.battle_enemies, ds_type_list)
 && variable_global_exists("battle_target")) {
    var n = ds_list_size(global.battle_enemies);
    if (n>0 && global.battle_target>=0 && global.battle_target<n) {
        var tid = global.battle_enemies[| global.battle_target];
        if (instance_exists(tid)) {
            var tx = tid.x, ty = tid.bbox_top, off = 10;
            if (sprite_exists(spr_target_cursor)) draw_sprite(spr_target_cursor,-1,tx,ty-off);
            else { draw_set_halign(fa_center); draw_set_valign(fa_bottom); draw_text_color(tx,ty-off,"▼",c_yellow,c_yellow,c_yellow,c_yellow,1); }
        }
    }
}
    // --- <<< ADDED: Ally Target Cursor >>> ---
    else if (_current_battle_state == "TargetSelectAlly" && variable_global_exists("battle_ally_target")) {
         var n_party = ds_list_size(global.battle_party);
         var ally_target_idx = global.battle_ally_target ?? -1; // Get selected ally index safely
         
         if (n_party > 0 && ally_target_idx >= 0 && ally_target_idx < n_party) {
             var tid = global.battle_party[| ally_target_idx];
             if (instance_exists(tid)) {
                 // Position cursor relative to the PARTY HUD element for that character
                 var hud_x = party_hud_positions_x[ally_target_idx] ?? tid.x; // Fallback to instance x if HUD pos invalid
                 var hud_center_x = hud_x + 128; // Estimate center of HUD element (adjust 128 based on your HUD width)
                 var hud_top_y = party_hud_y; 
                 
                 // Draw cursor above the HUD element
                 var tx = hud_center_x;
                 var ty = hud_top_y + target_cursor_y_offset; // Use the offset
                                  
                 if (sprite_exists(target_cursor_sprite)) {
                     draw_sprite(target_cursor_sprite, -1, tx, ty); 
                 } else { // Fallback text cursor if sprite missing
                     draw_set_halign(fa_center); draw_set_valign(fa_bottom); 
                     draw_text_color(tx, ty, "▼", c_yellow, c_yellow, c_yellow, c_yellow, 1); 
                 }
             }
         }
    }
// === Draw Turn Order Display ===
if (instance_exists(obj_battle_manager)
 && variable_instance_exists(obj_battle_manager, "turnOrderDisplay")
 && is_array(obj_battle_manager.turnOrderDisplay)) {
    
    var _turn_order  = obj_battle_manager.turnOrderDisplay;
    var _order_count = array_length(_turn_order);
    var padding     = 16;    // 8px padding on every side
    var shift_right = 80;   // shift entire box 96px to the right

    // Compute widest name for box width
    var max_w = 0;
    var _name;
    for (var i = 0; i < _order_count; i++) {
        var aid = _turn_order[i];
        if (!instance_exists(aid)) continue;
        if (variable_instance_exists(aid, "data")
         && is_struct(aid.data)
         && variable_struct_exists(aid.data, "name")) {
            _name = aid.data.name;
        } else {
            _name = object_get_name(aid.object_index);
        }
        max_w = max(max_w, string_width(_name));
    }

    // --- Draw background box with padding and horizontal shift ---
    var box_w = max_w + padding * 2;
    var box_h = _order_count * turn_order_spacing + padding * 2;
    var box_x = turn_order_x + shift_right - padding;  // shifted right, then back by padding
    var box_y = turn_order_y - padding;
    var sw    = sprite_get_width(spr_box1);
    var sh    = sprite_get_height(spr_box1);

    draw_sprite_ext(
        spr_box1, 0,
        box_x, box_y,
        box_w / sw, box_h / sh,
        0,
        c_white, 0.8
    );

    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);

    // --- Draw each entry inside the padded, shifted box ---
    for (var i = 0; i < _order_count; i++) {
        var _actor_id = _turn_order[i];
        if (!instance_exists(_actor_id)) continue;

        var _draw_y = turn_order_y + i * turn_order_spacing;
        if (variable_instance_exists(_actor_id, "data")
         && is_struct(_actor_id.data)
         && variable_struct_exists(_actor_id.data, "name")) {
            _name = _actor_id.data.name;
        } else {
            _name = object_get_name(_actor_id.object_index);
        }

        // Color based on type
        var _tint = (_actor_id.object_index == obj_battle_player) ? c_lime : c_red;
        // Dim if KO'd
        if (variable_instance_exists(_actor_id, "data")
         && is_struct(_actor_id.data)
         && variable_struct_exists(_actor_id.data, "hp")
         && _actor_id.data.hp <= 0) {
            _tint = merge_color(_tint, c_dkgray, 0.6);
        }

        // Shift text same amount as box
        draw_text_color(
            turn_order_x + shift_right,  // text also shifted
            _draw_y,
            _name,
            _tint, _tint, _tint, _tint,
            1
        );
    }
}




// === Reset draw state ===
draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);