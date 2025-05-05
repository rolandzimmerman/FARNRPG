/// obj_battle_log :: Create Event
logEntries      = [];     // array of strings
currentIndex    = -1;     // last entry shown
maxVisibleLines = 16;     // how many lines fit in the box
lineHeight      = 18;     // vertical spacing

// Where to draw
logX       = display_get_gui_width() - 500;  
logY       = display_get_gui_height() - 300;
boxPadding = 8;
