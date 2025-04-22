show_debug_message("🔧 obj_battle_manager Create Event running");


/// obj_battle_manager :: Create Event

enemy_turn = 0;
damage_to_enemy = 0;

// ✅ DEBUG: Show which object we're trying to spawn
show_debug_message("Creating enemy from object reference: " + string(global.current_enemy));

// ✅ Safely create the enemy instance using the object index stored in global.current_enemy
enemy_instance = instance_create_layer(600, 200, "Instances", global.current_enemy);

// ✅ DEBUG: Confirm instance was created
if (enemy_instance != noone) {
    show_debug_message("✅ Enemy instance created successfully.");
} else {
    show_debug_message("❌ Failed to create enemy instance.");
}

// ✅ Define attack logic
player_attack = function (_damage) {
    damage_to_enemy = _damage;
    enemy_turn = 1;
    alarm[0] = 40;

    if (instance_exists(obj_battle_player)) {
        obj_battle_player.alarm[0] = 10;
    }
}

// ✅ Win/Loss condition checker
check_for_end = function () {
    return (
        instance_exists(enemy_instance) && enemy_instance.data.hp <= 0
    ) || (
        instance_exists(obj_battle_player) && obj_battle_player.data.hp <= 0
    );
}
