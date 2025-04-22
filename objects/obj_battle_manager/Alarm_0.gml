/// obj_battle_manager :: Alarm[0]
// Handles timed transitions. UI layer visibility handled by obj_battle_menu Draw GUI event.

show_debug_message("⏰ BattleManager Alarm[0] Triggered — Current State: " + string(global.battle_state) + " !!!");

switch (global.battle_state) {

    case "waiting_after_player": global.battle_state = "check_win_loss"; break;
    case "waiting_next_enemy": global.battle_state = "enemy_turn"; break;
    case "waiting_enemy": global.battle_state = "enemy_turn"; break;

    case "victory":
        // ... (Victory processing: XP, dialogue call etc.) ...
        if (instance_exists(obj_player)) { with (obj_player) { add_xp(other.total_xp_from_battle); } } if (script_exists(scr_dialogue)) { if (!variable_global_exists("char_colors") || !is_struct(global.char_colors)) { /* Warning */ } create_dialog([{ name:"Victory!", msg: "You gained " + string(total_xp_from_battle) + " XP!" }]); } global.battle_state = "return_to_field"; alarm[0] = 120;
        break;

     case "defeat":
        // ... (Defeat processing: dialogue call etc.) ...
         if (script_exists(scr_dialogue)) { create_dialog([{ name:"Defeat", msg:"You have been defeated..." }]); } global.battle_state = "return_to_field"; alarm[0] = 120;
         break;

    case "return_to_field":
        show_debug_message("   Alarm 0: Returning to field map.");
        // --- Layer visibility code REMOVED ---

        // --- Update persistent obj_player stats ---
        if (instance_exists(obj_player)) { if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) { if (ds_list_size(global.battle_party) > 0) { var bp = global.battle_party[| 0]; if (instance_exists(bp) && variable_instance_exists(bp,"data") && is_struct(bp.data)) { if (variable_instance_exists(obj_player,"hp")) obj_player.hp = max(1, bp.data.hp); if (variable_instance_exists(obj_player,"mp")) obj_player.mp = bp.data.mp; }}}}

        // --- Cleanup DS Lists & Reset Vars ---
        if (variable_global_exists("battle_enemies") && ds_exists(global.battle_enemies, ds_type_list)) { ds_list_destroy(global.battle_enemies); global.battle_enemies = -1;} if (variable_global_exists("battle_party") && ds_exists(global.battle_party, ds_type_list)) { ds_list_destroy(global.battle_party); global.battle_party = -1; } total_xp_from_battle = 0; global.battle_state = undefined; alarm[0] = -1; global.battle_target = 0; global.enemy_turn_index = 0; stored_action_data = undefined; selected_target_id = noone;

        // --- Go to room ---
        if (variable_global_exists("original_room") && room_exists(global.original_room)) { if (instance_exists(obj_player) && variable_global_exists("return_x") && variable_global_exists("return_y")) { with(obj_player) { x = global.return_x; y = global.return_y; } } room_goto(global.original_room); }
        else { instance_destroy(); exit; }

        instance_destroy(); // Manager destroys self
        break;

    default:
        show_debug_message("   -> Alarm[0] triggered in unhandled state: " + string(global.battle_state));
        alarm[0] = -1;
        break;
}
