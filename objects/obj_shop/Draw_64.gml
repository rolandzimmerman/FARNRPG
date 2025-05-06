/// obj_shop :: Draw GUI Event

// Only draw when the shop is open
if (!shop_active) return;

// Fetch GUI dimensions
var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// Common styling
var padding      = 8;
var line_h       = 24;
var title_h      = 32;
var box_w        = 300;
var max_visible  = 8;
var box_x        = 64;
var items        = shop_stock;
var itemCount    = array_length(items);

// Browse State: show stock list
if (shop_state == "browse") {
    // Compute how many lines to show
    var visibleCount = min(itemCount, max_visible);
    var box_h        = title_h + visibleCount * line_h + padding*2;
    var box_y        = (gui_h - box_h) / 2;

    // Background panel
    if (sprite_exists(spr_box1)) {
        draw_sprite_stretched(
            spr_box1, 0,
            box_x - padding, box_y - padding,
            box_w + padding*2, box_h + padding*2
        );
    } else {
        draw_set_alpha(0.8); draw_set_color(c_black);
        draw_rectangle(
            box_x - padding, box_y - padding,
            box_x + box_w + padding, box_y + box_h + padding,
            false
        );
        draw_set_alpha(1); draw_set_color(c_white);
    }

    // Title
    draw_set_font(Font1);
    draw_set_halign(fa_center);
    draw_text(box_x + box_w/2, box_y + padding, "Shop");
    draw_set_halign(fa_left);

    // List items
    for (var i = 0; i < visibleCount; i++) {
        var key = items[i];
        var data = scr_GetItemData(key);
        var name = data.name ?? key;
        var bp   = ceil((data.value ?? 0) * buyMultiplier);
        var sp   = ceil((data.value ?? 0) * sellMultiplier);
        var posY = box_y + title_h + padding + i * line_h;

        // Highlight selection
        if (i == shop_index) {
            draw_set_alpha(0.4); draw_set_color(c_yellow);
            draw_rectangle(
                box_x, posY - 2,
                box_x + box_w, posY + line_h - 2,
                false
            );
            draw_set_alpha(1); draw_set_color(c_white);
        }

        // Name
        draw_set_font(Font1);
        draw_set_halign(fa_left);
        draw_text(box_x + padding, posY, name);

        // Buy/Sell prices
        draw_set_halign(fa_right);
        draw_text(box_x + box_w - padding, posY, 
            "B:" + string(bp) + "  S:" + string(sp)
        );
    }

    // Player Gold (top-left)
    var goldX = 16, goldY = 16;
    var goldW = 120, goldH = 24;

    // Gold background
    if (sprite_exists(spr_box1)) {
        draw_sprite_stretched(
            spr_box1, 0,
            goldX - padding, goldY - padding,
            goldW + padding*2, goldH + padding*2
        );
    } else {
        draw_set_alpha(0.8); draw_set_color(c_black);
        draw_rectangle(
            goldX - padding, goldY - padding,
            goldX + goldW + padding, goldY + goldH + padding,
            false
        );
        draw_set_alpha(1); draw_set_color(c_white);
    }

    // Gold text
    draw_set_font(Font1);
    draw_set_halign(fa_left);
    draw_text(goldX, goldY, "Gold: " + string(global.party_currency));
    draw_set_color(c_white);
    draw_set_font(-1);
}

// Confirm State: show yes/no prompt
else if (shop_state == "confirm_purchase") {
    var box_h = 100;
    var box_x = (gui_w - box_w) / 2;
    var box_y = (gui_h - box_h) / 2;

    // Background
    if (sprite_exists(spr_box1)) {
        draw_sprite_stretched(
            spr_box1, 0,
            box_x - padding, box_y - padding,
            box_w + padding*2, box_h + padding*2
        );
    } else {
        draw_set_alpha(0.8); draw_set_color(c_black);
        draw_rectangle(
            box_x - padding, box_y - padding,
            box_x + box_w + padding, box_y + box_h + padding,
            false
        );
        draw_set_alpha(1); draw_set_color(c_white);
    }

    // Question text
    var key  = shop_stock[shop_index];
    var data = scr_GetItemData(key);
    var name = data.name ?? key;
    var price = ceil((data.value ?? 0) * buyMultiplier);

    draw_set_font(Font1);
    draw_set_halign(fa_center);
    draw_text(box_x + box_w/2, box_y + 16,
              "Buy " + name + " for " + string(price) + "g?");
    
    // YES / NO
    var yesCol = (shop_confirm_choice == 0) ? c_yellow : c_white;
    var noCol  = (shop_confirm_choice == 1) ? c_yellow : c_white;

    draw_set_halign(fa_center);
    draw_set_color(yesCol);
    draw_text(box_x + box_w * 0.3, box_y + box_h - 24, "YES");
    draw_set_color(noCol);
    draw_text(box_x + box_w * 0.7, box_y + box_h - 24, "NO");

    // Reset drawing state
    draw_set_color(c_white);
    draw_set_font(-1);
    draw_set_halign(fa_left);
}
