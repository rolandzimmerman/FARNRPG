/// @function scr_draw_sprite_nine_slice_manual(sprite, subimg, x, y, width, height)
/// @description Manually draws a sprite using 9-slice scaling logic.
///              Reads 9-slice data directly from the sprite asset.
/// @param {Asset.GMSprite} sprite    The sprite asset to draw (must have 9-slice enabled).
/// @param {Real}           subimg    The image index (frame) of the sprite to draw.
/// @param {Real}           x         The x coordinate to draw the top-left corner at.
/// @param {Real}           y         The y coordinate to draw the top-left corner at.
/// @param {Real}           width     The desired total width of the drawn sprite.
/// @param {Real}           height    The desired total height of the drawn sprite.
function scr_draw_sprite_nine_slice_manual(_sprite, _subimg, _x, _y, _width, _height) {

    // Check if sprite is valid and has 9-slice enabled
    if (!sprite_exists(_sprite)) {
        show_debug_message("ERROR [scr_draw_sprite_nine_slice_manual]: Sprite " + string(_sprite) + " does not exist.");
        return;
    }
    var _nineslice_data = sprite_get_nineslice(_sprite);
    if (!is_struct(_nineslice_data) || !_nineslice_data.enabled) {
        show_debug_message("WARNING [scr_draw_sprite_nine_slice_manual]: Sprite " + sprite_get_name(_sprite) + " does not have 9-slice enabled. Using stretched draw.");
        draw_sprite_stretched(_sprite, _subimg, _x, _y, _width, _height);
        return;
    }

    // Get original sprite dimensions and slice guide values from the struct
    var _orig_w = sprite_get_width(_sprite);
    var _orig_h = sprite_get_height(_sprite);
    var _left   = _nineslice_data.left;
    var _top    = _nineslice_data.top;
    var _right  = _nineslice_data.right;  // Note: sprite_get_nineslice returns distance from edge
    var _bottom = _nineslice_data.bottom; // Note: sprite_get_nineslice returns distance from edge

    // Calculate widths/heights of the 3x3 grid sections on the original sprite
    var _left_w   = _left;
    var _right_w  = _right;
    var _center_w = _orig_w - _left_w - _right_w;
    var _top_h    = _top;
    var _bottom_h = _bottom;
    var _center_h = _orig_h - _top_h - _bottom_h;

    // Ensure calculated dimensions aren't negative if guides overlap etc.
     _center_w = max(0, _center_w);
     _center_h = max(0, _center_h);

    // Calculate the target widths/heights of the sections in the drawn sprite
    // Corners keep original size. Edges stretch in one dim. Center stretches in both.
    var _target_center_w = max(0, _width - _left_w - _right_w);
    var _target_center_h = max(0, _height - _top_h - _bottom_h);

    // --- Define source coordinates for draw_sprite_part ---
    // (x, y, width, height) on the original sprite sheet
    var _source_x = [0,       _left_w, _left_w + _center_w];
    var _source_y = [0,       _top_h,  _top_h + _center_h ];
    var _source_w = [_left_w, _center_w, _right_w];
    var _source_h = [_top_h,  _center_h, _bottom_h];

    // --- Define target coordinates and scales for draw_sprite_part_ext ---
    // (x, y) on the screen/GUI layer
    var _target_x = [_x,           _x + _left_w, _x + _left_w + _target_center_w];
    var _target_y = [_y,           _y + _top_h,  _y + _top_h + _target_center_h ];
    // (xscale, yscale) - Use 1 for non-stretching dims, calculate scale for stretching dims
    var _center_x_scale = (_center_w > 0) ? _target_center_w / _center_w : 1;
    var _center_y_scale = (_center_h > 0) ? _target_center_h / _center_h : 1;

    // --- Draw the 9 parts ---
    var _c = draw_get_color(); // Preserve current draw color & alpha
    var _a = draw_get_alpha();

    for (var _row = 0; _row < 3; _row++) {
        for (var _col = 0; _col < 3; _col++) {

            // Determine scale for this part
            var _xscale = 1;
            var _yscale = 1;

            if (_row == 1) { // Center Row
                 _yscale = _center_y_scale;
            }
            if (_col == 1) { // Center Column
                 _xscale = _center_x_scale;
            }

             // Skip drawing if source width/height is zero
             if (_source_w[_col] <= 0 || _source_h[_row] <= 0) continue;
             // Skip drawing if target width/height is zero (can happen if target size is smaller than borders)
             // Although draw_sprite_part_ext handles this okay usually.

            draw_sprite_part_ext(
                _sprite, _subimg,
                _source_x[_col], _source_y[_row], // Source x, y on sprite sheet
                _source_w[_col], _source_h[_row], // Source width, height
                _target_x[_col], _target_y[_row], // Target x, y on screen/GUI
                _xscale, _yscale,                 // Target scale
                c_white, 1.0                      // Blend color (use c_white, alpha 1 to draw normally)
            );
        }
    }

    // Restore original draw color and alpha (optional, good practice)
    // draw_set_color(_c);
    // draw_set_alpha(_a);
}