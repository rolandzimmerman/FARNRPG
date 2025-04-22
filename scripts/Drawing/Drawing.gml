/// scr_DrawShadow(offset)
// Draws spr_shadow underneath a 96×192 sprite whose origin is top‑left.
//   offset : extra vertical offset (e.g. to tweak how “low” the shadow sits)

function draw_shadow(_offset = 0) {
    // dimensions of the character sprite
    var sprite_w = 96;
    var sprite_h = 192;

    // compute where to draw the shadow:
    //   X: half‑width in from left edge
    //   Y: full height down from top edge, plus any extra offset
    var draw_x = x;
    var draw_y = y + .7 * sprite_h;

    // draw with 40% alpha, black tint
    draw_sprite_ext(
        spr_shadow,    // your shadow sprite
        0,             // sub‑image
        draw_x,        // x position
        draw_y,        // y position
        1,             // x scale
        1,             // y scale
        0,             // rotation
        c_black,       // color
        1           // alpha
    );
}
