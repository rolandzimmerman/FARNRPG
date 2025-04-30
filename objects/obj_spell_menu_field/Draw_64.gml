/// @description Draw the Field Spell Menu

if (!active) return; 

// --- Basic Setup ---
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();
if (font_exists(Font1)) { draw_set_font(Font1); } else { draw_set_font(-1); } 
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1.0);

// --- Menu State & Data ---
if (!variable_instance_exists(id, "menu_state")) exit; 
if (!variable_instance_exists(id, "character_index")) exit; 
if (!variable_instance_exists(id, "spell_index")) exit; 
if (!variable_instance_exists(id, "usable_spells")) exit; 

// --- Dim Background ---
draw_set_alpha(0.7); draw_set_color(c_black); 
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1.0); draw_set_color(c_white); 

// --- Menu Box Dimensions ---
var list_items_to_show = 10; 
var box_margin = 64;
var box_width = 400; 
var line_height = 36;
var pad = 16;
var title_h = line_height;

// --- Draw Character Selection Header (Always Visible?) ---
var party_list_keys = variable_global_exists("party_members") ? global.party_members : [];
var party_count = array_length(party_list_keys);
var char_box_h = 60; // Smaller height for just showing names/highlight
var char_box_w = party_count * 150 + pad * 2; 
     char_box_w = max(box_width, char_box_w); 
var char_box_x = (gui_w - char_box_w) / 2;
var char_box_y = box_margin; 

// Draw character box
if (sprite_exists(spr_box1)) { draw_sprite_stretched(spr_box1, 0, char_box_x, char_box_y, char_box_w, char_box_h); } 
else { /* Fallback draw */ } 
// Draw character names
draw_set_halign(fa_center); draw_set_valign(fa_middle);
var char_y = char_box_y + char_box_h / 2;
if (party_count > 0 && ds_exists(global.party_current_stats, ds_type_map)) {
     for (var i = 0; i < party_count; i++) {
         var p_key = party_list_keys[i];
         var p_data = ds_map_find_value(global.party_current_stats, p_key);
         var display_name = (is_struct(p_data)) ? (p_data.name ?? p_key) : p_key;
         var text_color = c_white; 
         var draw_x = char_box_x + (char_box_w * (i + 0.5) / party_count); 
         // Highlight selected character only in character select state
         if (menu_state == "character_select" && i == character_index) {
             draw_set_color(c_yellow); 
             var tw = string_width(display_name); 
             draw_rectangle(draw_x - tw/2 - 4, char_y + line_height/2 - 4, draw_x + tw/2 + 4, char_y + line_height/2, true); 
         } else { draw_set_color(text_color); }
         draw_text(draw_x, char_y, display_name);
         draw_set_color(c_white); 
     }
} else { draw_text(char_box_x + char_box_w / 2, char_y, "(No Party Members)"); }


// --- Draw Spell List / Target List based on state ---
if (menu_state == "spell_select" || menu_state == "target_select_ally") {
    // Box position below character select
    var list_box_w = box_width; // Use defined width
    var list_count = (menu_state == "spell_select") ? array_length(usable_spells) : party_count;
    var list_h = min(list_count, list_items_to_show) * line_height;
    if (list_count == 0) list_h = line_height; 
    var list_box_height = title_h + list_h + pad * 2;
    var list_box_x = (gui_w - list_box_w) / 2; // Center list box
    var list_box_y = char_box_y + char_box_h + pad; // Position below char box

    // Draw list box
    if (sprite_exists(spr_box1)) { draw_sprite_stretched(spr_box1, 0, list_box_x, list_box_y, list_box_w, list_box_height); } 
    else { /* Fallback draw */ } 

    // Draw Title
    var title_text = "Select Spell";
    if (menu_state == "target_select_ally") title_text = "Select Target";
    draw_set_halign(fa_center); draw_text(list_box_x + list_box_w / 2, list_box_y + pad, title_text); draw_set_halign(fa_left);

    // Draw List Content
    var list_x = list_box_x + pad;
    var list_start_y = list_box_y + pad + title_h;
    
    if (menu_state == "spell_select") {
         // --- Draw Spell List ---
         var spell_count = array_length(usable_spells);
         var list_cost_x = list_box_x + list_box_w - pad - 60; // X pos for MP cost
         if (spell_count > 0) {
             var spell_start_index = 0; // Basic scroll start
             for (var i = spell_start_index; i < min(spell_count, spell_start_index + list_items_to_show); i++) {
                 var spell_data = usable_spells[i];
                 var display_y = list_start_y + (i - spell_start_index) * line_height;
                 var display_name = spell_data.name ?? "???";
                 var display_cost = string(spell_data.cost ?? 0) + " MP";
                 var text_color = c_white; // TODO: Check if caster has enough MP and grey out if not
                 
                 if (i == spell_index) { // Highlight selected spell
                      draw_set_alpha(0.4); draw_set_color(c_yellow);
                      draw_rectangle(list_box_x + pad/2, display_y - 2, list_box_x + list_box_w - pad/2, display_y + line_height - 2, false); 
                      draw_set_alpha(1.0); draw_set_color(c_white);
                 }
                 draw_set_color(text_color); draw_text(list_x, display_y, display_name);
                 draw_set_halign(fa_right); draw_text(list_cost_x + 60, display_y, display_cost); 
                 draw_set_halign(fa_left); draw_set_color(c_white);
             }
         } else { /* Draw "No Usable Spells" */ 
             draw_set_halign(fa_center); draw_set_color(c_gray);
             draw_text(list_box_x + list_box_w / 2, list_start_y + list_h / 2, "(No Field Spells)");
             draw_set_halign(fa_left); draw_set_color(c_white);
         }
    } 
    else if (menu_state == "target_select_ally") {
         // --- Draw Target Ally List ---
          var target_start_index = 0; 
          if (party_count > 0 && ds_exists(global.party_current_stats, ds_type_map)) {
              for (var i = target_start_index; i < min(party_count, target_start_index + list_items_to_show); i++) {
                  var p_key = party_list_keys[i];
                  var p_data = ds_map_find_value(global.party_current_stats, p_key); 
                  var display_y = list_start_y + (i - target_start_index) * line_height;
                  var display_name = "(Invalid)"; var display_hp = ""; var text_color = c_gray;
                  if (is_struct(p_data)) { /* Get name/hp, set color based on HP */ }
                  
                  if (i == target_party_index) { // Highlight selected target
                      draw_set_alpha(0.4); draw_set_color(c_yellow);
                      draw_rectangle(list_box_x + pad/2, display_y - 2, list_box_x + list_box_w - pad/2, display_y + line_height - 2, false); 
                      draw_set_alpha(1.0); draw_set_color(c_white);
                  }
                  draw_set_color(text_color); draw_text(list_x, display_y, display_name);
                  draw_set_halign(fa_right); draw_text(list_box_x + list_box_w - pad, display_y, display_hp);
                  draw_set_halign(fa_left); draw_set_color(c_white);
              }
         } else { /* Draw "No Party Members" */ }
         
         // --- Draw Ally Target Cursor --- 
         // (Keep the logic from item menu to draw cursor over HUD)
         if (party_count > 0 && target_party_index >= 0) { /* Draw cursor over HUD using target_party_index */ }
    }
} // End if spell_select or target_select_ally

// --- Reset Draw State ---
draw_set_font(-1); draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_alpha(1.0); draw_set_color(c_white);