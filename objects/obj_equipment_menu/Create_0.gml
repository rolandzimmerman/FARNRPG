/// @description Initialize the equipment menu state and variables.
// Requires enum 'EEquipMenuState' to be defined globally (e.g., in scr_game_enums).

// Debug
show_debug_message(">> obj_equipment_menu :: CREATE Event");

// Mark this menu as active (overall menu visibility)
menu_active = true; 

// --- Menu State ---
// <<< This line requires EEquipMenuState to be defined globally >>>
menu_state = EEquipMenuState.BrowseSlots; 

// --- Equipment Slots ---
equipment_slots = [ "weapon", "offhand", "armor", "helm", "accessory" ];
selected_slot   = 0; 

// --- Party Member Selection ---
if (variable_global_exists("party_members") && is_array(global.party_members) && array_length(global.party_members) > 0) {
    party_index = 0;
    equipment_character_key = global.party_members[party_index];
} else {
    party_index = 0; equipment_character_key = "hero"; 
    show_debug_message("WARNING: Equipment menu opened with no global.party_members. Defaulting to 'hero'.");
    if (!variable_global_exists("party_members")) global.party_members = ["hero"]; 
}

// --- Item Selection Sub-menu Variables ---
item_submenu_choices = [];         
item_submenu_selected_index = 0; 
item_submenu_scroll_top = 0;       
item_submenu_display_count = 5;  
item_submenu_stat_diffs = {};     

// --- Fetch initial character data ---
equipment_data = scr_GetPlayerData(equipment_character_key); // Use the script that gets the full data
if (!is_struct(equipment_data)) {
    show_debug_message("ERROR: Create Event - scr_GetPlayerData returned invalid data for '" + string(equipment_character_key) + "'. Destroying menu.");
    instance_destroy();
    exit; 
}

// Store the reference to the calling pause menu if provided
calling_menu = noone;

// Use safe access for class in debug message
show_debug_message(">> Equipment Menu ready for '" + string(equipment_character_key) + "' (Class: " + string(variable_struct_get(equipment_data, "class") ?? "N/A") + ")");