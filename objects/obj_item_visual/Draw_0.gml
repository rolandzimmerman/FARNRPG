// obj_item_visual :: Draw Event
// Draws the assigned item sprite

if (sprite_exists(sprite_index)) { // Only draw if a valid sprite is assigned
    // Draw self using current properties (x, y, alpha, scale etc.)
    // Scale/angle could be set by creator if needed
    draw_self();
}