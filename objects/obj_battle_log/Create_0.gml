/// Initialize the log
logEntries      = [];      // array of strings
currentIndex    = -1;      // last entry shown
timer           = 0;       // frame counter
advanceDelay    = 60;      // frames between lines
maxVisibleLines = 16;       // how many lines fit in the box
lineHeight      = 18;      // vertical spacing

// Where to draw
logX = display_get_gui_width() - 500;  // adjust to taste
logY = display_get_gui_height() - 300;
boxPadding = 8;
