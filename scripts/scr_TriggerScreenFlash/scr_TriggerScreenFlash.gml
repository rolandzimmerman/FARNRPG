/// @function scr_TriggerScreenFlash(_duration_frames, _peak_alpha = 0.8)
/// @description Initiates a screen flash effect managed by obj_battle_manager.
/// @param {Real} _duration_frames How long the flash should last in frames.
/// @param {Real} [_peak_alpha=0.8] The maximum alpha the flash should reach.
function scr_TriggerScreenFlash(_duration_frames, _peak_alpha = 0.8) {
    if (instance_exists(obj_battle_manager)) {
        with (obj_battle_manager) {
            screen_flash_timer = max(screen_flash_timer, _duration_frames); // Reset timer or extend if already flashing
            screen_flash_duration = screen_flash_timer; // Store original duration
            screen_flash_peak_alpha = _peak_alpha;
            // Instantly set alpha towards peak based on timer? Or just let Step handle it. Let Step handle fade in/out.
             // screen_flash_alpha = screen_flash_peak_alpha; // Instant flash version
        }
    } else {
        show_debug_message("ERROR [TriggerScreenFlash]: obj_battle_manager not found!");
    }
}