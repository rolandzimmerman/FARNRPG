/// obj_pause_menu :: Create Event
/// Initialize menu options and “active” flag

// --- <<< MODIFIED Options Array >>> ---
menu_options = [
    "Items",       // Added
    "Spells",      // Added
    "Equipment",
    "Party",
    "Settings",
    "Load Game",
    "Quit",
    "Resume"       // Moved Resume to end for common placement
   // "Save Game" removed
];
// --- <<< END MODIFICATION >>> ---

menu_index      = 0; // Start at the first option ("Items")
menu_item_count = array_length(menu_options);

// Mark this menu as active so Draw() and Step() know to run
active = true; 

// (Optional) Sound effect handles
// snd_cursor = snd_menu_cursor;
// snd_select = snd_menu_select;
// snd_cancel = snd_menu_cancel;

show_debug_message("obj_pause_menu Create: Initialized with options: " + string(menu_options));