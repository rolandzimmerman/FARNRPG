// Script run at game start (or above obj_equipment_menu Create Event):
enum EEquipMenuState {
    BrowseSlots,   // Selecting Weapon/Armor/etc.
    SelectingItem    // Choosing an item from the list for the selected slot
}

// -----------------------------------------------------------------------------
// obj_equipment_menu :: Create Event
// -----------------------------------------------------------------------------
/// @description Initialize the equipment menu state and variables.

// Debug
show_debug_message(">> obj_equipment_menu :: CREATE Event");

// Mark this menu as active (overall menu visibility)
menu_active = true; // Control if Step/Draw run

// --- Menu State ---
menu_state = EEquipMenuState.BrowseSlots;

// --- Equipment Slots ---
equipment_slots = [ "weapon", "offhand", "armor", "helm", "accessory" ];
selected_slot   = 0; // Index for equipment_slots

// --- Party Member Selection ---
// Start on the first party member if available
if (variable_global_exists("party_members") && is_array(global.party_members) && array_length(global.party_members) > 0) {
    party_index = 0;
    equipment_character_key = global.party_members[party_index];
} else {
    // Fallback if party setup is wrong
    party_index = 0;
    equipment_character_key = "hero"; // Default to hero if no party found
    show_debug_message("WARNING: Equipment menu opened with no global.party_members. Defaulting to 'hero'.");
    if (!variable_global_exists("party_members")) global.party_members = ["hero"]; // Attempt to create if missing
}

// --- Item Selection Sub-menu Variables ---
item_submenu_choices = [];        // Array of item keys (including noone) for the selected slot
item_submenu_selected_index = 0;  // Index of the highlighted item in the sub-menu list
item_submenu_scroll_top = 0;      // Index of the item at the top of the visible list
item_submenu_display_count = 5;   // Max items to show in the list at once
item_submenu_stat_diffs = {};     // Struct to hold calculated stat differences {atk: +5, def: -2, ...}

// --- Fetch initial character data ---
// This gets base stats, class, and a *reference* to the persistent equipment struct
equipment_data = scr_GetPlayerData(equipment_character_key);
if (!is_struct(equipment_data)) {
    show_debug_message("ERROR: Create Event - scr_GetPlayerData returned invalid data for '" + string(equipment_character_key) + "'. Destroying menu.");
    instance_destroy();
    exit; // Stop creation if data is bad
}

// Store the reference to the calling pause menu if provided
// (The pause menu should set this variable when creating the equipment menu instance)
calling_menu = noone;

show_debug_message(">> Equipment Menu ready for '" + string(equipment_character_key) + "' (Class: " + string(equipment_data.class) + ")");

