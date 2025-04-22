/// @description Initialize pause menu options and state

menu_options = [
    "Resume",
    "Save Game",
    "Load Game",
    "Quit"
];

menu_index = 0; // Index of the currently selected option
menu_item_count = array_length(menu_options);

// Optional: Sound effects
// snd_cursor = snd_menu_cursor; // Assign your sounds
// snd_select = snd_menu_select;
// snd_cancel = snd_menu_cancel;