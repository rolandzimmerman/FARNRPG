/// obj_pause_menu :: Create Event
/// Initialize menu options and “active” flag

menu_options = [
    "Resume",
    "Save Game",
    "Load Game",
    "Equipment",
    "Quit"
];

menu_index      = 0;
menu_item_count = array_length(menu_options);

// Mark this menu as active so Draw() and Step() know to run
active = true;

// (Optional) Sound effect handles
// snd_cursor = snd_menu_cursor;
// snd_select = snd_menu_select;
// snd_cancel = snd_menu_cancel;
