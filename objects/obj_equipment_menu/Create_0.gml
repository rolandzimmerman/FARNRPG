/// obj_equipment_menu :: Create Event
/// ---------------------------------------------------------------------------
/// Initialize the equipment menu

// Debug
show_debug_message(">> obj_equipment_menu :: CREATE");

// Mark this menu as active
menu_active = true;

// Define the five equipment slots
equipment_slots = [ "weapon", "offhand", "armor", "helm", "accessory" ];
selected_slot    = 0;

// Start on the first party member
if (is_array(global.party_members) && array_length(global.party_members) > 0) {
    party_index = 0;
    equipment_character_key = global.party_members[0];
} else {
    party_index = 0;
    equipment_character_key = "hero";
}

// Fetch their battle-ready data
equipment_data = scr_GetPlayerData(equipment_character_key);
if (!is_struct(equipment_data)) {
    show_debug_message("ERROR: scr_GetPlayerData returned invalid data for '" + string(equipment_character_key) + "'. Destroying menu.");
    instance_destroy();
    exit;
}

show_debug_message(">> Equipment Menu ready for '" + string(equipment_character_key) + "'");
