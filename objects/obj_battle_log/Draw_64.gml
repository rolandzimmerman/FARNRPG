/// obj_battle_log :: Draw Event
// 1) Snap to the very end
currentIndex = array_length(logEntries) - 1;

// 2) Draw background box
var sw = sprite_get_width(spr_box1);
var sh = sprite_get_height(spr_box1);
var bw = 500;    
var bh = maxVisibleLines * lineHeight + boxPadding * 2;
draw_sprite_ext(
    spr_box1, 0,
    logX - boxPadding,
    logY - boxPadding,
    bw / sw,
    bh / sh,
    0, c_white, 0.9
);

// 3) Draw only the last maxVisibleLines entries
var startIdx = max(0, currentIndex + 1 - maxVisibleLines);
for (var i = 0; i <= min(currentIndex, maxVisibleLines - 1); i++) {
    var entry = logEntries[startIdx + i];
    draw_set_color(c_white);
    draw_set_font(Font1);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_text(logX, logY + i * lineHeight, entry);
}
