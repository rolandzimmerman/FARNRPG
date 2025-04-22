 // ✅ Delay destruction until next frame so data can be read
    alarm[0] = 1;
if (room == rm_battle) {
    show_debug_message("⚙️ Entered rm_battle, creating manager manually");
    instance_create_layer(0, 0, "Instances", obj_battle_manager);
    alarm[0] = 1; // destroy self after one frame
}
