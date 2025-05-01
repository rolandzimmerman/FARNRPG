/// obj_party_menu :: Draw GUI Event
if (!active) return;

// --- GUI dimensions ---
var guiWidth   = display_get_gui_width();
var guiHeight  = display_get_gui_height();

// --- Layout constants ---
var boxWidth   = 300;
var lineHeight = 32;
var pad        = 16;

// Number of slots in the party
var slotCount  = array_length(global.party_members);

// Compute box height & position
var boxHeight  = (slotCount + 1) * lineHeight + pad * 2;
var boxX       = (guiWidth  - boxWidth ) / 2;
var boxY       = (guiHeight - boxHeight) / 2;

// --- Dim background ---
draw_set_alpha(0.7);
draw_set_color(c_black);
draw_rectangle(0, 0, guiWidth, guiHeight, false);
draw_set_alpha(1);

// --- Draw the dialog box ---
if (sprite_exists(spr_box1)) {
    draw_sprite_stretched(spr_box1, 0, boxX, boxY, boxWidth, boxHeight);
}

// --- Title ---
if (font_exists(Font1)) draw_set_font(Font1);
draw_set_halign(fa_center);
draw_set_color(c_white);
draw_text(boxX + boxWidth * 0.5, boxY + pad, "Arrange Party");

// --- List each party slot ---
for (var i = 0; i < slotCount; i++) {
    // Y position for this line
    var lineY = boxY + pad + lineHeight * (i + 1);

    // The party member key & display name
    var memberKey   = global.party_members[i];
    var displayName = memberKey;
    if (variable_global_exists("party_current_stats")
     && ds_exists(global.party_current_stats, ds_type_map)
     && ds_map_exists(global.party_current_stats, memberKey)) {
        var stats = ds_map_find_value(global.party_current_stats, memberKey);
        if (is_struct(stats) && variable_struct_exists(stats, "name")) {
            displayName = stats.name;
        }
    }

    // Determine prefix and color
    var prefix    = "";
    var textColor = c_white;

    // Highlight the cursor
    if (i == member_index) {
        prefix    = "> ";
        textColor = c_yellow;
    }

    // If we're choosing the second slot, mark the first choice
    if (menu_state == "choose_second" && i == selected_index) {
        // If it's also the current cursor, combine both markers
        if (i == member_index) {
            prefix    = "> [1st] ";
            textColor = c_yellow;
        } else {
            prefix    = "[1st] ";
            textColor = c_aqua;
        }
    }

    // Draw the line
    draw_set_color(textColor);
    draw_set_halign(fa_left);
    draw_text(boxX + pad, lineY, prefix + displayName);
}

// --- Reset drawing state ---
draw_set_alpha(1);
draw_set_color(c_white);
draw_set_font(-1);
draw_set_halign(fa_left);
