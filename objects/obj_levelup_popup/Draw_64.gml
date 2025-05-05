/// obj_levelup_popup :: Draw Event

// ————————————————
// 1) SETUP & DATA
// ————————————————
draw_set_font(Font1);
draw_set_halign(fa_left);
draw_set_valign(fa_middle);

// The array of level‐up infos
var infos = global.battle_level_up_infos;
if (!is_array(infos) || array_length(infos) == 0) {
    exit; // nothing to show
}

// Stat keys and layout
var keys       = ["maxhp","maxmp","atk","def","matk","mdef","spd","luk"];
var lineH      = 24;           // spacing per line
var blockLines = array_length(keys) + 1; // 1 for the name
var chars      = array_length(infos);

// Padding inside the box
var padX = 16;
var padY = 16;

// ————————————————
// 2) MEASURE CONTENT DIMENSIONS
// ————————————————
var nameColX    = 0;
var oldColX     = 0;
var arrowColX   = 0;
var newColX     = 0;

// Compute max widths
var maxNameW = 0, maxOldW = 0, maxNewW = 0;
var arrowW   = string_width(">");

for (var j = 0; j < chars; j++) {
    var info = infos[j];
    // Name
    maxNameW = max(maxNameW, string_width(info.name));
    // Old & New stats
    for (var i = 0; i < array_length(keys); i++) {
        var k      = keys[i];
        var oldV   = variable_struct_get(info.old, k);
        var newV   = variable_struct_get(info.new, k);
        maxOldW   = max(maxOldW, string_width(string(oldV)));
        maxNewW   = max(maxNewW, string_width(string(newV)));
    }
}

// Column positions relative to left of content
nameColX  = 0;
oldColX   = nameColX + maxNameW + 20;
arrowColX = oldColX  + maxOldW  + 12;
newColX   = arrowColX + arrowW   + 12;

// Total content size
var contentW = newColX + maxNewW;
var contentH = chars * blockLines * lineH;

// Box on screen center
var guiW = display_get_gui_width();
var guiH = display_get_gui_height();
var boxX = (guiW - (contentW + padX*2)) * 0.5;
var boxY = (guiH - (contentH + padY*2)) * 0.5;

// ————————————————
// 3) DRAW BACKGROUND BOX
// ————————————————
var sw = sprite_get_width(spr_box1);
var sh = sprite_get_height(spr_box1);
draw_sprite_ext(
    spr_box1, 0,
    boxX, boxY,
    (contentW + padX*2) / sw,
    (contentH + padY*2) / sh,
    0, c_white, 0.9
);

// ————————————————
// 4) DRAW EACH CHARACTER BLOCK
// ————————————————
for (var j = 0; j < chars; j++) {
    var info  = infos[j];
    // Top of this block
    var topY  = boxY + padY + j * blockLines * lineH;

    // — Name (first line)
    draw_set_color(c_white);
    draw_text(boxX + padX + nameColX, topY + lineH*0.5, info.name);

    // — Stats
    for (var i = 0; i < array_length(keys); i++) {
        var k     = keys[i];
        var lineY = topY + (i + 1) * lineH + lineH*0.5;

        var oldV  = variable_struct_get(info.old, k);
        var newV  = variable_struct_get(info.new, k);

        // Old value
        draw_set_color(c_white);
        draw_text(boxX + padX + oldColX, lineY, string(oldV));

        // Arrow
        draw_text(boxX + padX + arrowColX, lineY, ">");

        // New value (green if increased)
        draw_set_color(newV > oldV ? c_lime : c_white);
        draw_text(boxX + padX + newColX, lineY, string(newV));
    }
}

// Reset draw color
draw_set_color(c_white);
