show_debug_message("🧪 [Room Start] Initializing battle FX surface...");

// ✅ Only try to free surface if the variable exists AND the surface exists
if (variable_global_exists("battle_fx_surface")) {
    if (surface_exists(global.battle_fx_surface)) {
        surface_free(global.battle_fx_surface);
        show_debug_message(" -> Freed old global.battle_fx_surface.");
    }
}

// ✅ Create the surface and assign it to the global
global.battle_fx_surface = surface_create(room_width, room_height);
show_debug_message(" -> Created new global.battle_fx_surface: " + string(global.battle_fx_surface));

// ✅ Clear the surface to transparent black
var old_target = surface_get_target();
surface_set_target(global.battle_fx_surface);
draw_clear_alpha(c_black, 0);
surface_reset_target();

// ✅ Restore old surface target *only if valid*
if (surface_exists(old_target)) {
    surface_set_target(old_target);
}
