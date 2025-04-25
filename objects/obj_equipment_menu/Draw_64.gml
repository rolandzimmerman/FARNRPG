/// obj_equipment_menu :: Draw GUI Event

// 1) GUI dims
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// 2) Dim background
draw_set_color(c_black);
draw_set_alpha(0.7);
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1);

// 3) Header
draw_set_font(Font1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
var char_name = "Unknown";
if (is_struct(equipment_data) && variable_struct_exists(equipment_data, "name")) {
    char_name = equipment_data.name;
}
draw_text(32, 16, "Equipment: " + char_name);

// 4) Slots list
var slot_start_x = 32;
var item_start_x = 160;
var slot_start_y = 64;
var line_h       = 28;
var slot_count   = array_length(equipment_slots);

for (var i = 0; i < slot_count; i++) {
    var row_y     = slot_start_y + i * line_h;
    var slot_name = equipment_slots[i];
    var sel       = (i == selected_slot);

    // Slot label
    draw_set_color(sel ? c_yellow : make_color_rgb(150,150,150));
    draw_text(slot_start_x, row_y, slot_name + ":");

    // Figure out what’s equipped in this slot
    var item_key = noone;
    if (is_struct(equipment_data) && variable_struct_exists(equipment_data, "equipment")) {
        var eq = equipment_data.equipment;
        if (is_struct(eq)) {
            if (variable_struct_exists(eq, slot_name)) {
                // dynamic struct access:
                item_key = variable_struct_get(eq, slot_name);
            }
        } else if (ds_exists(eq, ds_type_map)) {
            if (ds_map_exists(eq, slot_name)) {
                item_key = ds_map_find_value(eq, slot_name);
            }
        }
    }

    // Determine text to draw
    var label = "(none)";
    if (is_string(item_key)) {
        var info = scr_GetItemData(item_key);
        if (is_struct(info) && variable_struct_exists(info, "name")) {
            label = info.name;
        } else {
            label = "(invalid)";
        }
    }

    // Draw item name
    draw_set_color(sel ? c_white : make_color_rgb(200,200,200));
    draw_text(item_start_x, row_y, label);
}

// 5) Footer controls
draw_set_color(c_aqua);
draw_text(32, gui_h - 32, "↑/↓:Move   Enter:Cycle   Esc:Close");

// 6) Reset
draw_set_font(-1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
