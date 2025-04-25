/// obj_equipment_menu :: CREATE EVENT

// Debug
show_debug_message("Equipment Menu Create Event Starting.");

// Will re-show the pause menu when we exit
calling_menu = noone;

// Who we’re editing
equipment_character_key = "hero";

// Grab the full battle struct
equipment_data = scr_GetPlayerData(equipment_character_key);
if (!is_struct(equipment_data)) {
    show_debug_message("ERROR: scr_GetPlayerData returned invalid data! Destroying instance.");
    instance_destroy();
    exit;
}

// Slot order
equipment_slots = ["weapon","offhand","armor","helm","accessory"];
selected_slot    = 0;

// TURN ON the step event
menu_active = true;

show_debug_message("Equipment Menu Create Event Finished Successfully.");
