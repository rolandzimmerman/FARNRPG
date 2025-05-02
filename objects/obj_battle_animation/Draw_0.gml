/// obj_battle_animation :: Draw Event

if (surface_exists(battle_fx_surface)) {
    // Store the current drawing target
    var _old_target = surface_get_target();
    
    // Set the battle FX surface as the new drawing target
    surface_set_target(battle_fx_surface);
    
    // Set the desired blend mode (e.g., normal or additive)
    draw_set_blend_mode(bm_normal); // Use bm_add for glow effects
    
    // Draw the animation sprite onto the surface
    draw_sprite_ext(
        sprite_index, image_index,
        x, y,
        image_xscale, image_yscale,
        image_angle,
        image_blend, image_alpha
    );
    
    // Reset the drawing target to the previous one
    surface_reset_target();
    surface_set_target(_old_target);
}
