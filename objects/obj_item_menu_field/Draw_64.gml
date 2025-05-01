/// obj_item_menu_field :: Draw GUI Event
if (!active) return;

// --- Basic Setup ---
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();
if (font_exists(Font1)) {
    draw_set_font(Font1);
} else {
    draw_set_font(-1);
}
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1.0);

// --- Safety Checks ---
if (!variable_instance_exists(id, "menu_state")) {
    show_debug_message("Draw GUI Error: menu_state missing");
    return;
}
if (!variable_instance_exists(id, "usable_items")) {
    show_debug_message("Draw GUI Error: usable_items missing");
    return;
}
if (!variable_instance_exists(id, "item_index")) {
    show_debug_message("Draw GUI Error: item_index missing");
    return;
}
if (!variable_instance_exists(id, "target_party_index")) {
    show_debug_message("Draw GUI Error: target_party_index missing");
    return;
}

// --- Layout Constants ---
var list_items_to_show = 10;
var box_margin         = 64;
var box_width          = 400;
var line_height        = 36;
var pad                = 16;
var title_h            = line_height;
var list_select_color  = c_yellow;

// --- Dim Background ---
draw_set_alpha(0.7);
draw_set_color(c_black);
draw_rectangle(0, 0, gui_w, gui_h, false);
draw_set_alpha(1.0);
draw_set_color(c_white);

// --- Determine List & Box Dimensions ---
var current_list_array = (menu_state == "item_select")
    ? usable_items
    : ((menu_state == "target_select" && variable_global_exists("party_members"))
       ? global.party_members
       : []);
var current_list_count = array_length(current_list_array);
var list_h = (current_list_count > 0)
    ? min(current_list_count, list_items_to_show) * line_height
    : line_height;
var box_height = title_h + list_h + pad * 2;
var box_x      = box_margin;
var box_y      = (gui_h - box_height) / 2;

// --- Draw Menu Box ---
if (sprite_exists(spr_box1)) {
    draw_sprite_stretched(spr_box1, 0, box_x, box_y, box_width, box_height);
} else {
    draw_set_alpha(0.8);
    draw_set_color(c_black);
    draw_rectangle(box_x, box_y, box_x + box_width, box_y + box_height, false);
    draw_set_alpha(1.0);
    draw_set_color(c_white);
}

// --- Draw Title ---
var title_text = (menu_state == "item_select") ? "Items" : "Use Item On:";
draw_set_halign(fa_center);
draw_text(box_x + box_width / 2, box_y + pad, title_text);
draw_set_halign(fa_left);

// --- Draw Item or Target List ---
var list_start_y = box_y + pad + title_h;
var list_x       = box_x + pad;

if (menu_state == "item_select") {
    var qty_x = box_x + box_width - pad;
    for (var i = 0; i < min(array_length(usable_items), list_items_to_show); i++) {
        var entry = usable_items[i];
        var row_y = list_start_y + i * line_height;

        // Highlight
        if (i == item_index) {
            draw_set_alpha(0.4);
            draw_set_color(list_select_color);
            draw_rectangle(
                box_x + pad/2, 
                row_y - 2,
                box_x + box_width - pad/2,
                row_y + line_height - 2,
                false
            );
            draw_set_alpha(1.0);
            draw_set_color(c_white);
        }

        // Name & Quantity
        draw_set_halign(fa_left);
        draw_text(list_x + 40, row_y, entry.name);
        draw_set_halign(fa_right);
        draw_text(qty_x, row_y, "x" + string(entry.quantity));
        draw_set_color(c_white);
    }

} else if (menu_state == "target_select") {
    var party_keys = variable_global_exists("party_members") ? global.party_members : [];
    var qty_x      = box_x + box_width - pad;

    for (var i = 0; i < min(array_length(party_keys), list_items_to_show); i++) {
        var memberKey = party_keys[i];
        var stats     = (variable_global_exists("party_current_stats")
                        && ds_exists(global.party_current_stats, ds_type_map)
                        && ds_map_exists(global.party_current_stats, memberKey))
                      ? ds_map_find_value(global.party_current_stats, memberKey)
                      : undefined;
        var row_y     = list_start_y + i * line_height;
        var dispName  = (is_struct(stats) && variable_struct_exists(stats, "name"))
                      ? stats.name 
                      : memberKey;
        var dispHP    = is_struct(stats)
                      ? "HP " + string(stats.hp ?? 0) + "/" + string(stats.maxhp ?? 0)
                      : "";
        var textCol   = (is_struct(stats) && stats.hp > 0) ? c_white : c_dkgray;

        // Highlight
        if (i == target_party_index) {
            draw_set_alpha(0.4);
            draw_set_color(list_select_color);
            draw_rectangle(
                box_x + pad/2,
                row_y - 2,
                box_x + box_width - pad/2,
                row_y + line_height - 2,
                false
            );
            draw_set_alpha(1.0);
            draw_set_color(c_white);
        }

        // Draw Name & HP
        draw_set_color(textCol);
        draw_set_halign(fa_left);
        draw_text(list_x, row_y, dispName);
        draw_set_halign(fa_right);
        draw_text(qty_x, row_y, dispHP);
        draw_set_color(c_white);
    }
}

// --- Preview Box (96×96) with spr_box1 background ---
var PREVIEW_SIZE = 96;
var PREVIEW_X    = box_x + box_width + pad;
var PREVIEW_Y    = box_y + pad;

// Draw the black 9-slice background
if (sprite_exists(spr_box1)) {
    draw_set_color(c_black);
    draw_sprite_stretched(spr_box1, 0,
        PREVIEW_X, PREVIEW_Y,
        PREVIEW_SIZE, PREVIEW_SIZE
    );
} else {
    draw_set_color(c_black);
    draw_rectangle(
        PREVIEW_X, PREVIEW_Y,
        PREVIEW_X + PREVIEW_SIZE,
        PREVIEW_Y + PREVIEW_SIZE,
        false
    );
}

// Draw the selected item’s icon inside
if (menu_state == "item_select"
 && item_index >= 0
 && item_index < array_length(usable_items)) {
    var sprID = usable_items[item_index].sprite;
    if (sprID >= 0 && sprite_exists(sprID)) {
        var sw = sprite_get_width(sprID);
        var sh = sprite_get_height(sprID);
        var dx = PREVIEW_X + (PREVIEW_SIZE - sw) * 0.5;
        var dy = PREVIEW_Y + (PREVIEW_SIZE - sh) * 0.5;
        draw_sprite(sprID, 0, dx, dy);
    }
}

// --- Reset Drawing State ---
draw_set_alpha(1.0);
draw_set_color(c_white);
draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
