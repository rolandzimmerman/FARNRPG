/// obj_pause_menu :: Create Event
menu_active = true;

// --- Initialize pause menu options ---
menu_options = [
    "Resume",
    "Save Game",
    "Load Game",
    "Equipment",
    "Quit"
];
menu_index      = 0;
menu_item_count = array_length(menu_options);
