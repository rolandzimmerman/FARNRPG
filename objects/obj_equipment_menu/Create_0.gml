/// obj_equipment_menu :: Create Event
/// ---------------------------------------------------------------------------
/// Initialize the equipment menu

// Debug
show_debug_message(">> obj_equipment_menu :: CREATE");

// Mark this menu as active (overall menu visibility)
menu_active = true;

// --- Menu States ---
enum EEquipMenuState {
    BrowseSlots,   // Selecting Weapon/Armor/etc.
    SelectingItem    // Choosing an item from the list for the selected slot
}
menu_state = EEquipMenuState.BrowseSlots;

// Define the five equipment slots
equipment_slots = [ "weapon", "offhand", "armor", "helm", "accessory" ];
selected_slot   = 0; // Index for equipment_slots

// --- Party Member Selection ---
// Start on the first party member
if (is_array(global.party_members) && array_length(global.party_members) > 0) {
    party_index = 0;
    equipment_character_key = global.party_members[0];
} else {
    // Fallback if party setup is wrong (shouldn't happen in normal gameplay)
    party_index = 0;
    equipment_character_key = "hero";
    show_debug_message("WARNING: Equipment menu opened with no party members. Defaulting to 'hero'.");
}

// --- Item Selection Sub-menu ---
item_submenu_choices = []; // Array of item keys (including noone) for the selected slot
item_submenu_selected_index = 0;
item_submenu_scroll_top = 0; // For scrolling long item lists
item_submenu_display_count = 5; // Max items to show in the list at once
item_submenu_stat_diffs = {}; // Struct to hold calculated stat differences {atk: +5, def: -2, ...}

// Fetch initial character data (base stats + equipped items references)
// We will calculate display stats in the Draw event using scr_CalculateEquippedStats
equipment_data = scr_GetPlayerData(equipment_character_key);
if (!is_struct(equipment_data)) {
    show_debug_message("ERROR: scr_GetPlayerData returned invalid data for '" + string(equipment_character_key) + "'. Destroying menu.");
    instance_destroy();
    exit;
}

// Store the reference to the calling pause menu if provided
// (Assuming the pause menu sets this when creating the equip menu)
calling_menu = noone;

show_debug_message(">> Equipment Menu ready for '" + string(equipment_character_key) + "'");