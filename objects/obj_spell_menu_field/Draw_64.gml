/// @description Draw the Field Spell Menu

if (!active) return; 

// --- Basic Setup ---
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();
// Ensure Font1 exists before trying to set it
if (font_exists(Font1)) { draw_set_font(Font1); } else { draw_set_font(-1); } 
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white); // Start with white
draw_set_alpha(1.0);   // Start with full alpha

// --- Menu State & Data (Safety checks) ---
if (!variable_instance_exists(id, "menu_state")) exit; 
if (!variable_instance_exists(id, "character_index")) exit; 
if (!variable_instance_exists(id, "spell_index")) exit; 
if (!variable_instance_exists(id, "usable_spells")) exit; 
if (!variable_instance_exists(id, "selected_caster_key")) exit; 
if (menu_state == "target_select_ally") { if (!variable_instance_exists(id, "target_party_index")) exit; }

// --- Dim Background ---
draw_set_alpha(0.7); draw_set_color(c_black); 
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1.0); draw_set_color(c_white); // Reset after dim

// --- Constants Defined Locally ---
var list_items_to_show = 10;    
var box_margin = 64;            
var box_width = 400;            
var line_height = 36;           
var pad = 16;                   
var title_h = line_height;      
var list_select_color = c_yellow; 
var party_list_keys = global.party_members ?? [];
var party_count = array_length(party_list_keys);
// Define HUD positions locally, ensure these match your layout
var party_hud_positions_x = [64, 320, 576, 832]; 
var party_hud_y = 0;                            
var target_cursor_sprite = spr_target_cursor;    // Ensure this sprite exists
var target_cursor_y_offset = -20;                 
// Get caster data safely
var caster_data = (selected_caster_key != "" && ds_exists(global.party_current_stats,ds_type_map) && ds_map_exists(global.party_current_stats,selected_caster_key)) ? global.party_current_stats[? selected_caster_key] : undefined;

// --- Draw Character Selection Header ---
var char_box_h = 60; 
var char_box_w = party_count * 150 + pad * 2; char_box_w = max(box_width, char_box_w); 
var char_box_x = (gui_w - char_box_w) / 2; var char_box_y = box_margin; 
if (party_count > 0) { 
    // Draw box background (assuming spr_box1 exists)
    if (sprite_exists(spr_box1)) { draw_sprite_stretched(spr_box1, 0, char_box_x, char_box_y, char_box_w, char_box_h); } 
    else { draw_set_alpha(0.8);draw_set_color(c_black);draw_rectangle(char_box_x, char_box_y, char_box_x+char_box_w, char_box_y+char_box_h, false);draw_set_alpha(1.0); } 
    
    // Draw character names
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    var char_y = char_box_y + char_box_h / 2;
    if (ds_exists(global.party_current_stats, ds_type_map)) {
         for (var i = 0; i < party_count; i++) {
             var p_key = party_list_keys[i]; var p_data = ds_map_find_value(global.party_current_stats, p_key);
             var display_name = (is_struct(p_data)) ? (p_data.name ?? p_key) : p_key;
             var text_color; 
             var draw_x = char_box_x + (char_box_w * (i + 0.5) / party_count); 
             // Highlight selected character
             if (menu_state == "character_select" && i == character_index) {
                 draw_set_color(list_select_color); 
                 var tw = string_width(display_name); 
                 draw_rectangle(draw_x - tw/2 - 4, char_y + line_height/2 - 4, draw_x + tw/2 + 4, char_y + line_height/2, true); 
                 text_color = list_select_color; 
             } else { text_color = c_white; }
             // Draw text with determined color
             draw_set_color(text_color); 
             draw_text(draw_x, char_y, display_name);
         }
    } else { draw_set_color(c_white); draw_text(char_box_x + char_box_w / 2, char_y, "(No Party Data!)"); }
} else { /* Optionally draw message if no party */ }


// --- Draw Spell List OR Target List based on state ---
var list_box_w = box_width; 
var list_box_x = (gui_w - list_box_w) / 2; 
var list_box_y = char_box_y + char_box_h + pad; // Position below character box
var list_x = list_box_x + pad;
var list_start_y = list_box_y + pad + title_h; 
var title_text = "";

// --- Draw Spell List ---
if (menu_state == "spell_select") {
    title_text = is_struct(caster_data) ? (caster_data.name ?? selected_caster_key) + " - Spells" : "Select Spell";
    var spell_count = array_length(usable_spells); 
    var list_h = min(spell_count, list_items_to_show) * line_height; if (spell_count == 0) list_h = line_height; 
    var list_box_height = title_h + list_h + pad * 2;
    
    // Draw Box & Title
    draw_set_color(c_white); // Reset color before drawing box
    if (sprite_exists(spr_box1)) { draw_sprite_stretched(spr_box1, 0, list_box_x, list_box_y, list_box_w, list_box_height); } 
    else { /* Fallback draw */ }
    draw_set_halign(fa_center); draw_text(list_box_x + list_box_w / 2, list_box_y + pad, title_text); draw_set_halign(fa_left);
    var list_cost_x = list_box_x + list_box_w - pad; // Position for right-aligned cost

    // Draw List Content
    if (spell_count > 0 && is_struct(caster_data)) { 
        var current_mp = caster_data.mp ?? 0;
        var spell_start_index = 0; 
        for (var i = spell_start_index; i < min(spell_count, spell_start_index + list_items_to_show); i++) { 
             var spell_data = usable_spells[i]; 
             var display_y = list_start_y + (i - spell_start_index) * line_height;
             var display_name = "(Error)"; var display_cost = "?? MP"; var text_color = c_red;
             if (is_struct(spell_data)) { 
                 display_name = spell_data.name ?? "???"; 
                 var cost = spell_data.cost ?? 0; 
                 display_cost = string(cost) + " MP";
                 var can_afford = (current_mp >= cost); 
                 text_color = can_afford ? c_white : c_gray; 
             }
             
             // Draw Highlight
             if (i == spell_index) { 
                 draw_set_alpha(0.4); draw_set_color(list_select_color); 
                 draw_rectangle(list_box_x + pad/2, display_y - 2, list_box_x + list_box_w - pad/2, display_y + line_height - 2, false); 
                 draw_set_alpha(1.0); 
                 text_color = list_select_color; 
             }
             
             // Draw Text (Name Left, Cost Right)
             draw_set_color(text_color); 
             draw_text(list_x, display_y, display_name); 
             draw_set_halign(fa_right); 
             draw_text(list_cost_x, display_y, display_cost); // Use calculated X for right align
             draw_set_halign(fa_left); 
        }
    } else { // Draw "No Field Spells" message if list is empty
         draw_set_halign(fa_center); draw_set_color(c_gray);
         draw_text(list_box_x + list_box_w / 2, list_start_y + list_h / 2, "(No Field Spells)");
         draw_set_halign(fa_left); 
    }
} 
// --- Draw Target Ally List ---
else if (menu_state == "target_select_ally") {
    // --- Draw Target Ally List ---
    title_text = "Select Target"; // Correct title
    var list_h = min(party_count, list_items_to_show) * line_height; if (party_count == 0) list_h = line_height; 
    var list_box_height = title_h + list_h + pad * 2;
    
    // Draw Box & Title
    draw_set_color(c_white); 
    if (sprite_exists(spr_box1)) { draw_sprite_stretched(spr_box1, 0, list_box_x, list_box_y, list_box_w, list_box_height); } else { /* Fallback */ }
    draw_set_halign(fa_center); draw_text(list_box_x + list_box_w / 2, list_box_y + pad, title_text); draw_set_halign(fa_left);
    list_start_y = list_box_y + pad + title_h; // Recalculate start Y

    // Draw Target List Content
    if (party_count > 0 && ds_exists(global.party_current_stats, ds_type_map)) {
         var spell_data_for_target_check = usable_spells[spell_index] ?? noone; // Get current spell for validation checks
         
         for (var i = 0; i < min(party_count, list_items_to_show); i++) {
             var p_key = party_list_keys[i]; var p_data = ds_map_find_value(global.party_current_stats, p_key); 
             var display_y = list_start_y + i * line_height;
             var display_name = "(Invalid)"; var display_hpmp = ""; var text_color = c_gray;
             var can_target_this_ally = false; // Assume invalid initially
             
             if (is_struct(p_data)) { 
                 display_name = p_data.name ?? p_key; 
                 display_hpmp = "HP " + string(p_data.hp ?? 0) + "/" + string(p_data.maxhp ?? 0) + " MP " + string(p_data.mp ?? 0) + "/" + string(p_data.maxmp ?? 0); // Show HP and MP
                 can_target_this_ally = true; // Assume valid initially if data exists
                 
                 // --- Check if target is valid for the CURRENT spell ---
                 if (is_struct(spell_data_for_target_check)) {
                     if (spell_data_for_target_check.effect == "heal_hp" && p_data.hp <= 0) { can_target_this_ally = false; } // Cannot heal dead
                     // if (spell_data_for_target_check.effect == "revive" && p_data.hp > 0) { can_target_this_ally = false; } // Cannot revive living
                     // Add more checks here
                 }
                 text_color = can_target_this_ally ? (p_data.hp > 0 ? c_white : c_dkgray) : c_red; // Default white, gray if KO, red if invalid target
             }
             
             // Draw Highlight
             if (i == target_party_index) { 
                 draw_set_alpha(0.4); draw_set_color(list_select_color); 
                 draw_rectangle(list_box_x + pad/2, display_y - 2, list_box_x + list_box_w - pad/2, display_y + line_height - 2, false); 
                 draw_set_alpha(1.0); 
                 text_color = list_select_color; // Use highlight color for text too
             }
             
             // Draw Text (Name Left, HP/MP Right)
             draw_set_color(text_color); 
             draw_text(list_x, display_y, display_name);
             draw_set_halign(fa_right); 
             draw_text(list_box_x + list_box_w - pad, display_y, display_hpmp);
             draw_set_halign(fa_left); 
         }
    } else { /* Draw "(No Party Members)" */ }
    
    // Draw Ally Target Cursor over HUD 
    if (party_count > 0 && target_party_index >= 0 && target_party_index < party_count && target_party_index < array_length(party_hud_positions_x)) { 
         var hud_x = party_hud_positions_x[target_party_index]; var hud_center_x = hud_x + 128; var hud_top_y = party_hud_y; 
         var tx = hud_center_x; var ty = hud_top_y + target_cursor_y_offset; 
         if (sprite_exists(target_cursor_sprite)) { draw_sprite(target_cursor_sprite, -1, tx, ty); } 
         else { draw_set_halign(fa_center); draw_set_valign(fa_bottom); draw_text_color(tx, ty, "▼", c_yellow, c_yellow, c_yellow, c_yellow, 1); }
     }
}

// --- Reset Draw State ---
draw_set_font(-1); draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_alpha(1.0); draw_set_color(c_white);