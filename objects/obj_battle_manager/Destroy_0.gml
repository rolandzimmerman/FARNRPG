/// obj_battle_manager :: Destroy Event

if (surface_exists(battle_fx_surface)) {
    surface_free(battle_fx_surface);
    show_debug_message(" -> Freed battle_fx_surface on destroy.");
}
