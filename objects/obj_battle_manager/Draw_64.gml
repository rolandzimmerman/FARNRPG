/// obj_battle_manager :: Draw GUI Event
// Draws screen flash effect. Other UI is drawn by obj_battle_menu.

// --- Draw Screen Flash --- (Draw first so UI is on top)
if (screen_flash_alpha > 0) {
    var _gui_w = display_get_gui_width();
    var _gui_h = display_get_gui_height();
    draw_set_color(c_white);
    draw_set_alpha(screen_flash_alpha);
    draw_rectangle(0, 0, _gui_w, _gui_h, false);
    draw_set_alpha(1); // Reset alpha
    draw_set_color(c_white); // Reset color
}
if (!surface_exists(battle_fx_surface)) {
    battle_fx_surface = surface_create(room_width, room_height);
    surface_set_target(battle_fx_surface);
    draw_clear_alpha(c_black, 0); // Transparent background
    surface_reset_target();
}


// Potentially draw manager-specific debug info here if needed
// draw_text(10, display_get_gui_height() - 30, "Manager State: " + global.battle_state);
// draw_text(10, display_get_gui_height() - 50, "Current Actor: " + string(currentActor));