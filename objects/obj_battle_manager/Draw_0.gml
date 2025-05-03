/// obj_battle_manager :: Draw Event

// First: draw the usual contents (e.g. the Instances layer)
draw_self(); // Optional depending on if anything is drawn directly in manager

// ✅ Then: draw the battle FX surface ABOVE everything
if (variable_global_exists("battle_fx_surface")) {
    if (surface_exists(global.battle_fx_surface)) {
        draw_surface(global.battle_fx_surface, 0, 0);
    } else {
        show_debug_message("⚠️ [Draw] battle_fx_surface does not exist!");
    }
} else {
    show_debug_message("⚠️ [Draw] global.battle_fx_surface not initialized.");
}
