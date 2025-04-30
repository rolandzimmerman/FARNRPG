/// @description Draw the Field Item Menu

if (!active) return; 

// --- Basic Setup ---
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();
if (font_exists(Font1)) { draw_set_font(Font1); } else { draw_set_font(-1); } 
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1.0);

// --- Menu State & Data (Safety checks) ---
if (!variable_instance_exists(id, "menu_state")) { show_debug_message("Draw GUI Error: menu_state missing"); exit; }
if (!variable_instance_exists(id, "usable_items")) { show_debug_message("Draw GUI Error: usable_items missing"); exit; } 
if (!variable_instance_exists(id, "item_index")) { show_debug_message("Draw GUI Error: item_index missing"); exit; } 
if (!variable_instance_exists(id, "target_party_index")) { show_debug_message("Draw GUI Error: target_party_index missing"); exit; } 

// --- <<< ADDED BACK: Constants needed for this menu's layout >>> ---
var list_items_to_show = 10;    // Max items visible at once
var box_margin = 64;            // Margin from screen edge
var box_width = 400;            // Width of the menu box
var line_height = 36;           // Height of one line/item
var pad = 16;                   // Padding inside the box
var title_h = line_height;      // Space for the title
var list_select_color = c_yellow; // <<< Color for the selection highlight DEFINED HERE >>>
// Party HUD positions needed for target cursor placement relative to HUD
var party_hud_positions_x = variable_global_exists("party_hud_positions_x") ? global.party_hud_positions_x : [64, 320, 576, 832]; 
var party_hud_y = variable_global_exists("party_hud_y") ? global.party_hud_y : 0;
var target_cursor_sprite = spr_target_cursor;    // Sprite for the target cursor
var target_cursor_y_offset = -20;                 // Y offset for target cursor
// --- <<< END ADDED BACK Constants >>> ---

// --- Dim Background ---
draw_set_alpha(0.7); draw_set_color(c_black); 
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1.0); draw_set_color(c_white); 

// --- Calculate Box Dimensions based on current state ---
var current_list_array;
if (menu_state == "item_select") { current_list_array = usable_items; }
else if (menu_state == "target_select") { current_list_array = variable_global_exists("party_members") ? global.party_members : []; }
else { current_list_array = []; } // Default empty for unknown state

var current_list_count = array_length(current_list_array);
var list_h = min(current_list_count, list_items_to_show) * line_height; 
if (current_list_count == 0) list_h = line_height; 
var box_height = title_h + list_h + pad * 2;
var box_x = box_margin; 
var box_y = (gui_h - box_height) / 2; 

// --- Draw Menu Box ---
if (sprite_exists(spr_box1)) { draw_sprite_stretched(spr_box1, 0, box_x, box_y, box_width, box_height); } 
else { draw_set_alpha(0.8); draw_set_color(c_black); draw_rectangle(box_x, box_y, box_x + box_width, box_y + box_height, false); draw_set_alpha(1.0); draw_set_color(c_white);} 

// --- Draw Title ---
var title_text = "Items";
if (menu_state == "target_select") title_text = "Use Item On:";
draw_set_halign(fa_center);
draw_text(box_x + box_width / 2, box_y + pad, title_text);
draw_set_halign(fa_left);

// --- Draw Item List OR Target List based on state ---
var list_x = box_x + pad;
var list_start_y = box_y + pad + title_h;

if (menu_state == "item_select") {
    var list_item_w = box_width - (pad * 4) - 60; 
    var list_qty_x = list_x + list_item_w + pad;  
    var item_count = array_length(usable_items);

    if (item_count > 0) {
        var item_start_index = 0; // Basic scroll start
        for (var i = item_start_index; i < min(item_count, item_start_index + list_items_to_show); i++) {
             var item_data = usable_items[i];
             var display_y = list_start_y + (i - item_start_index) * line_height;
             var display_text = item_data.name ?? "???";
             var display_qty = "x" + string(item_data.quantity ?? 0);
             var text_color = c_white; 
             // Highlight & Logging
             if (i == item_index) { 
                 // show_debug_message("Drawing Item Highlight: i=" + string(i) + " item_index=" + string(item_index)); // Optional Log
                 var rect_x1 = box_x + pad/2; var rect_y1 = display_y - 2; var rect_x2 = box_x + box_width - pad/2; var rect_y2 = display_y + line_height - 2;
                 // show_debug_message(" -> Rect Coords: " + string([rect_x1, rect_y1, rect_x2, rect_y2])); // Optional Log
                 draw_set_alpha(0.4); draw_set_color(list_select_color); // Use constant
                 draw_rectangle(rect_x1, rect_y1, rect_x2, rect_y2, false); // Draw Highlight
                 draw_set_alpha(1.0); draw_set_color(c_white);
             }
             // Draw Text
             draw_set_color(text_color); draw_text(list_x, display_y, display_text);
             draw_set_halign(fa_right); draw_text(list_qty_x + 60, display_y, display_qty); 
             draw_set_halign(fa_left); draw_set_color(c_white);
        }
    } else { 
         // Draw "No Items" message 
         draw_set_halign(fa_center); draw_set_color(c_gray);
         draw_text(box_x + box_width / 2, list_start_y + list_h / 2, "(No Usable Items)");
         draw_set_halign(fa_left); draw_set_color(c_white);
    }
} 
else if (menu_state == "target_select") {
    draw_set_halign(fa_left);
    var party_list_keys = variable_global_exists("party_members") ? global.party_members : [];
    var party_count = array_length(party_list_keys);
    var target_start_index = 0; 
    
    if (party_count > 0 && ds_exists(global.party_current_stats, ds_type_map)) {
         for (var i = target_start_index; i < min(party_count, target_start_index + list_items_to_show); i++) {
             var p_key = party_list_keys[i];
             var p_data = ds_map_find_value(global.party_current_stats, p_key); 
             var display_y = list_start_y + (i - target_start_index) * line_height;
             var display_name = "(Invalid)"; var display_hp = ""; var text_color = c_gray;
             if (is_struct(p_data)) { 
                 display_name = p_data.name ?? p_key;
                 display_hp = "HP " + string(p_data.hp ?? 0) + "/" + string(p_data.maxhp ?? 0);
                 text_color = (p_data.hp > 0) ? c_white : c_dkgray; 
             }
             // Highlight & Logging
             if (i == target_party_index) {
                 // show_debug_message("Drawing Target Highlight: i=" + string(i) + " target_party_index=" + string(target_party_index)); 
                 var rect_x1 = box_x + pad/2; var rect_y1 = display_y - 2; var rect_x2 = box_x + box_width - pad/2; var rect_y2 = display_y + line_height - 2;
                 // show_debug_message(" -> Rect Coords: " + string([rect_x1, rect_y1, rect_x2, rect_y2])); 
                 draw_set_alpha(0.4); draw_set_color(list_select_color); // Use constant
                 draw_rectangle(rect_x1, rect_y1, rect_x2, rect_y2, false); 
                 draw_set_alpha(1.0); draw_set_color(c_white);
             }
             // Draw Text
             draw_set_color(text_color);
             draw_text(list_x, display_y, display_name);
             draw_set_halign(fa_right);
             draw_text(box_x + box_width - pad, display_y, display_hp);
             draw_set_halign(fa_left);
             draw_set_color(c_white);
         }
    } else { 
        // Draw "No Party Members" message
        draw_set_halign(fa_center); draw_set_color(c_gray);
        draw_text(box_x + box_width / 2, list_start_y + list_h / 2, "(No Party Members)");
        draw_set_halign(fa_left); draw_set_color(c_white);
    }
    
    // --- Draw Ally Target Cursor --- 
     if (party_count > 0 && target_party_index >= 0 && target_party_index < party_count) {
         // Get party member's HUD X position
          var hud_x = (target_party_index < array_length(party_hud_positions_x)) ? party_hud_positions_x[target_party_index] : (box_x + box_width + 20); // Fallback position
         var hud_center_x = hud_x + 128; // Adjust '128' based on your HUD width / 2
         var hud_top_y = party_hud_y; 
         // Use the offset defined in constants
         var tx = hud_center_x;
         var ty = hud_top_y + target_cursor_y_offset; 
         
         if (sprite_exists(target_cursor_sprite)) { 
             draw_sprite(target_cursor_sprite, -1, tx, ty); 
         } else { 
             // Fallback text cursor
             draw_set_halign(fa_center); draw_set_valign(fa_bottom); 
             draw_text_color(tx, ty, "▼", c_yellow, c_yellow, c_yellow, c_yellow, 1); 
             draw_set_halign(fa_left); draw_set_valign(fa_top); // Reset alignment
         }
     }
}

// --- Reset Draw State ---
draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top); 
draw_set_alpha(1.0); draw_set_color(c_white);