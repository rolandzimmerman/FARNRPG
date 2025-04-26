/// obj_battle_menu :: Draw GUI
/// Draws battle UI elements using spr_box1, Font1, and white text where applicable.

// --- Basic Checks & Active Player Data Validation ---
if (!visible || image_alpha <= 0) exit;
if (!variable_global_exists("battle_state")) exit;

var active_player_data_valid = false;
var active_p_inst = noone;
var active_p_data = noone;
var active_idx = -1;

if (variable_global_exists("active_party_member_index")) {
    active_idx = global.active_party_member_index;
    if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) {
        var party_size = ds_list_size(global.battle_party);
        if (active_idx >= 0 && active_idx < party_size) {
            active_p_inst = global.battle_party[| active_idx];
            if (instance_exists(active_p_inst)) {
                if (variable_instance_exists(active_p_inst,"data") && is_struct(active_p_inst.data)) {
                    active_p_data = active_p_inst.data;
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
var party_hud_positions_x = [64, 320, 576, 832];
var party_hud_y = 0; // Fixed Y for HUDs

// Radial menu - assuming positions are fine
var menu_cx=160; var menu_cy=600; var menu_r=80; var button_scale=0.5;
var label_scale=0.5; var label_rot=35; var menu_y_offset=220;

// Skill/Item list positioning and dimensions
var list_x_base = menu_cx + menu_r + 80; // Initial X position for lists
var list_y = menu_cy - 80;
var list_line_h = 36; // Height PER line
var list_padding = 8; // Padding inside list boxes
var list_item_w = 240; // Width for item name part
var list_qty_w = 40; // Width for quantity part (items only)
var list_box_w = list_item_w + list_qty_w + list_padding * 3; // Calculate total box width needed
var list_max_items_shown = 5; // How many items/skills show at once
var list_select_color = c_yellow; // Keep highlight color


// === Set Font and Color ===
// vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
if (font_exists(Font1)) draw_set_font(Font1); else draw_set_font(-1);
draw_set_color(c_white); // Default text color is white
// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
draw_set_halign(fa_left);
draw_set_valign(fa_top); // Default alignments


// === Draw Party HP/MP HUDs ===
var _spr_hud_bg_exists = sprite_exists(spr_pc_hud_bg);
var _spr_hp_exists = sprite_exists(spr_pc_hud_hp);
var _spr_mp_exists = sprite_exists(spr_pc_hud_mp);
var _spr_hp_w = _spr_hp_exists ? sprite_get_width(spr_pc_hud_hp) : 0;
var _spr_hp_h = _spr_hp_exists ? sprite_get_height(spr_pc_hud_hp) : 0;
var _spr_mp_w = _spr_mp_exists ? sprite_get_width(spr_pc_hud_mp) : 0;
var _spr_mp_h = _spr_mp_exists ? sprite_get_height(spr_pc_hud_mp) : 0;

if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) {
    var party_size = ds_list_size(global.battle_party);
    for (var i = 0; i < party_size; i++) {
        if (i >= array_length(party_hud_positions_x)) { continue; } // Skip if no position defined
        var current_member_hud_x = party_hud_positions_x[i];
        var current_member_hud_y = party_hud_y;

        var p_inst = global.battle_party[| i];
        if (instance_exists(p_inst) && variable_instance_exists(p_inst, "data") && is_struct(p_inst.data)) {
            var p_data = p_inst.data;
            var is_active_member = (i == active_idx);
            var bar_alpha = is_active_member ? 1.0 : 0.7;
            // var text_color = is_active_member ? c_white : c_gray; // REMOVED - Use default white
            var bg_tint = is_active_member ? c_white : c_gray; // Keep tint for BG sprite

            // Define relative positions within the HUD sprite (NEEDS ADJUSTMENT based on spr_pc_hud_bg layout)
            var name_rel_x = 10;    var name_rel_y = 3;
            var hp_bar_rel_x = 32;  var hp_bar_rel_y = 20; // Example position
            var hp_text_rel_x = 35; var hp_text_rel_y = 20 + (_spr_hp_h / 2); // Example position
            var mp_bar_rel_x = 32;  var mp_bar_rel_y = 38; // Example position
            var mp_text_rel_x = 35; var mp_text_rel_y = 38 + (_spr_mp_h / 2); // Example position

            // 1. Draw Background Sprite
            if (_spr_hud_bg_exists) {
                draw_sprite_ext(spr_pc_hud_bg, 0, current_member_hud_x, current_member_hud_y, 1, 1, 0, bg_tint, bar_alpha);
            } else { /* Fallback Rect */ }

            // 2. Draw Name (White)
            draw_set_color(c_white); // Ensure white
            draw_set_alpha(bar_alpha);
            draw_set_valign(fa_top);
            draw_text(current_member_hud_x + name_rel_x, current_member_hud_y + name_rel_y, p_data.name);

            // 3. Draw HP Bar Sprite
            if (_spr_hp_exists) {
                var _hp = p_data.hp; var _maxhp = p_data.maxhp;
                var hp_ratio = (_maxhp > 0) ? clamp(_hp / _maxhp, 0, 1) : 0;
                var hp_draw_w = floor(_spr_hp_w * hp_ratio);
                if (hp_draw_w > 0) {
                    draw_sprite_part_ext(spr_pc_hud_hp, 0, 0, 0, hp_draw_w, _spr_hp_h,
                        current_member_hud_x + hp_bar_rel_x, current_member_hud_y + hp_bar_rel_y,
                        1, 1, c_white, bar_alpha);
                }
            }

            // 4. Draw HP Text (White)
            draw_set_color(c_white); // Ensure white
            draw_set_alpha(bar_alpha);
            draw_set_valign(fa_middle);
            draw_text(current_member_hud_x + hp_text_rel_x, current_member_hud_y + hp_text_rel_y, string(floor(_hp)) + "/" + string(floor(_maxhp)));
            draw_set_valign(fa_top);

            // 5. Draw MP Bar Sprite
             if (_spr_mp_exists) {
                var _mp = p_data.mp; var _maxmp = p_data.maxmp;
                var mp_ratio = (_maxmp > 0) ? clamp(_mp / _maxmp, 0, 1) : 0;
                var mp_draw_w = floor(_spr_mp_w * mp_ratio);
                if (mp_draw_w > 0) {
                     draw_sprite_part_ext(spr_pc_hud_mp, 0, 0, 0, mp_draw_w, _spr_mp_h,
                         current_member_hud_x + mp_bar_rel_x, current_member_hud_y + mp_bar_rel_y,
                         1, 1, c_white, bar_alpha);
                 }
             }

            // 6. Draw MP Text (White)
            draw_set_color(c_white); // Ensure white
            draw_set_alpha(bar_alpha);
            draw_set_valign(fa_middle);
            draw_text(current_member_hud_x + mp_text_rel_x, current_member_hud_y + mp_text_rel_y, string(floor(_mp)) + "/" + string(floor(_maxmp)));
            draw_set_valign(fa_top);
        }
    }
}
draw_set_alpha(1.0); // Reset alpha after HUDs


// === Main Command Menu / Skill Menu / Item Menu ===
draw_set_color(c_white); // Ensure white before menu drawing

if (active_player_data_valid) { // Only draw if we have valid active player data
    if (global.battle_state == "player_input") {
        // --- Draw Radial Menu ---
        // Assumes these sprites exist and positions are correct
        if(sprite_exists(Abutton))draw_sprite_ext(Abutton,0,97,619+menu_y_offset,button_scale,button_scale,0,c_white,1);
        if(sprite_exists(Bbutton))draw_sprite_ext(Bbutton,0,147,557+menu_y_offset,button_scale,button_scale,0,c_white,1);
        if(sprite_exists(Xbutton))draw_sprite_ext(Xbutton,0,48,559+menu_y_offset,button_scale,button_scale,0,c_white,1);
        if(sprite_exists(Ybutton))draw_sprite_ext(Ybutton,0,97,501+menu_y_offset,button_scale,button_scale,0,c_white,1);
        if(sprite_exists(spr_attack))draw_sprite_ext(spr_attack,0,-5.83,687.83+menu_y_offset,label_scale,label_scale,label_rot,c_white,1);
        if(sprite_exists(spr_defend))draw_sprite_ext(spr_defend,0,195.92,563.76+menu_y_offset,label_scale,label_scale,label_rot,c_white,1);
        if(sprite_exists(spr_special))draw_sprite_ext(spr_special,0,-14.91,563.75+menu_y_offset,label_scale,label_scale,label_rot,c_white,1);
        if(sprite_exists(spr_items))draw_sprite_ext(spr_items,0,133,497.68+menu_y_offset,label_scale,label_scale,label_rot,c_white,1);

    } else if (global.battle_state == "skill_select") {
        // --- Draw Skill List ---
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        var _skills_array = (variable_struct_exists(active_p_data, "skills") && is_array(active_p_data.skills)) ? active_p_data.skills : [];
        var _skill_index = variable_struct_exists(active_p_data, "skill_index") ? active_p_data.skill_index : 0;
        var _current_mp = active_p_data.mp;

        if (array_length(_skills_array) > 0) {
            // Calculate Box dimensions
            var _list_items_to_draw = array_length(_skills_array); // Or clamp with list_max_items_shown if scrolling needed
            var _list_box_h = (_list_items_to_draw * list_line_h) + list_padding * 2;
            var _list_box_x = list_x_base - list_padding;
            var _list_box_y = list_y - list_padding;
            var _list_box_w = list_item_w + list_padding * 2; // Width only needs to encompass skill name/cost

            // Draw Background Box
            if (sprite_exists(spr_box1)) {
                var _spr_w = sprite_get_width(spr_box1); var _spr_h = sprite_get_height(spr_box1);
                if (_spr_w > 0 && _spr_h > 0) {
                    var _xscale = _list_box_w / _spr_w; var _yscale = _list_box_h / _spr_h;
                    draw_sprite_ext(spr_box1, 0, _list_box_x, _list_box_y, _xscale, _yscale, 0, c_white, 0.9); // Slightly transparent maybe
                } else { /* Fallback rect */ }
            } else { /* Fallback rect */ }

            // Draw Skills
            for (var j = 0; j < _list_items_to_draw; j++) { // Add scrolling logic here if needed
                var s = _skills_array[j]; if (!is_struct(s)) continue;
                var skill_name = variable_struct_exists(s, "name") ? s.name : "???";
                var skill_cost = variable_struct_exists(s, "cost") ? s.cost : 0;
                var current_draw_y = list_y + j * list_line_h;

                // Highlight selected item
                if (j == _skill_index) {
                    draw_set_color(list_select_color); draw_set_alpha(0.5);
                    // Draw highlight slightly wider than text area
                    draw_rectangle(_list_box_x, current_draw_y - 2, _list_box_x + _list_box_w, current_draw_y + list_line_h - 2, false);
                    draw_set_alpha(1);
                }

                // Text (Always White) - Maybe dim if not enough MP? User asked for all white.
                // var display_color = (_current_mp < skill_cost) ? c_dkgray : c_white; // Optional dimming
                draw_set_color(c_white); // Force white
                draw_text(list_x_base, current_draw_y, skill_name + " (MP " + string(skill_cost) + ")");
            }
        } else { // No skills
            draw_set_color(c_white); // Draw "No Skills" in white
            draw_text(list_x_base, list_y, "No Skills");
        }

    } else if (global.battle_state == "item_select") {
        // --- Draw Item List ---
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        // Make sure inventory source is correct (using global now)
        var _inventory = (variable_global_exists("party_inventory") && is_array(global.party_inventory)) ? global.party_inventory : [];
        var _item_index = variable_struct_exists(active_p_data, "item_index") ? active_p_data.item_index : 0;

        if (array_length(_inventory) > 0) {
             // Calculate Box dimensions
            var _list_items_to_draw = array_length(_inventory); // Or clamp with list_max_items_shown if scrolling needed
            var _list_box_h = (_list_items_to_draw * list_line_h) + list_padding * 2;
            var _list_box_x = list_x_base - list_padding;
            var _list_box_y = list_y - list_padding;
            // Use the wider list_box_w calculated earlier to accommodate quantity

            // Draw Background Box
            if (sprite_exists(spr_box1)) {
                var _spr_w = sprite_get_width(spr_box1); var _spr_h = sprite_get_height(spr_box1);
                if (_spr_w > 0 && _spr_h > 0) {
                    var _xscale = list_box_w / _spr_w; var _yscale = _list_box_h / _spr_h;
                    draw_sprite_ext(spr_box1, 0, _list_box_x, _list_box_y, _xscale, _yscale, 0, c_white, 0.9); // Slightly transparent maybe
                } else { /* Fallback rect */ }
            } else { /* Fallback rect */ }

            // Draw Items
            for (var j = 0; j < _list_items_to_draw; j++) { // Add scrolling logic here if needed
                var ie=_inventory[j]; if (!is_struct(ie)) continue;
                var ik=variable_struct_exists(ie,"item_key")?ie.item_key:undefined; var iq=variable_struct_exists(ie,"quantity")?ie.quantity:0; if (is_undefined(ik)||iq<=0) continue;
                var idf=scr_GetItemData(ik); var inm=is_struct(idf)?idf.name:"???";
                var current_draw_y = list_y + j * list_line_h;

                // Highlight selected item
                if (j == _item_index) {
                    draw_set_color(list_select_color); draw_set_alpha(0.5);
                    // Draw highlight slightly wider than text area
                    draw_rectangle(_list_box_x, current_draw_y - 2, _list_box_x + list_box_w, current_draw_y + list_line_h - 2, false);
                    draw_set_alpha(1);
                }

                // Text (Always White)
                draw_set_color(c_white);
                draw_set_halign(fa_left);
                draw_text(list_x_base, current_draw_y, inm); // Draw item name
                draw_set_halign(fa_right);
                // Draw quantity aligned to the right edge of the item name area
                draw_text(list_x_base + list_item_w + list_padding, current_draw_y, "x" + string(iq));
                draw_set_halign(fa_left); // Reset alignment
            }
        } else { // No items
            // Draw "No Items" message centered in a small box maybe?
             var _list_box_x = list_x_base - list_padding;
             var _list_box_y = list_y - list_padding;
             var _list_box_w = list_item_w + list_padding * 2;
             var _list_box_h = list_line_h + list_padding * 2;
              if (sprite_exists(spr_box1)) {
                 var _spr_w = sprite_get_width(spr_box1); var _spr_h = sprite_get_height(spr_box1);
                 if (_spr_w > 0 && _spr_h > 0) { var _xscale = _list_box_w / _spr_w; var _yscale = _list_box_h / _spr_h; draw_sprite_ext(spr_box1, 0, _list_box_x, _list_box_y, _xscale, _yscale, 0, c_white, 0.9); }
              }
             draw_set_color(c_white); // Draw message in white
             draw_text(list_x_base, list_y, "No Items");
        }
    } // End item_select drawing

} // End check for active_player_data_valid

// --- Draw Target Cursor --- (Only in TargetSelect state)
if (global.battle_state == "TargetSelect") {
    // Check global target variables exist
    if (variable_global_exists("battle_enemies") && ds_exists(global.battle_enemies, ds_type_list) && variable_global_exists("battle_target")) {
         var num_enemies = ds_list_size(global.battle_enemies);
         if (num_enemies > 0 && global.battle_target >= 0 && global.battle_target < num_enemies) {
             var _tid = global.battle_enemies[| global.battle_target];
             if (instance_exists(_tid)) { // Check target instance exists
                 var _tx = _tid.x; var _ty = _tid.bbox_top; var _coffy = 10;
                 if (sprite_exists(spr_target_cursor)) {
                      draw_sprite(spr_target_cursor, -1, _tx, _ty - _coffy); // Use image_index -1 for animation
                  }
                 else { // Fallback text cursor
                     draw_set_halign(fa_center); draw_set_valign(fa_bottom);
                     // Keep cursor yellow for visibility
                     draw_text_color(_tx, _ty - _coffy, "▼", c_yellow, c_yellow, c_yellow, c_yellow, 1);
                 }
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