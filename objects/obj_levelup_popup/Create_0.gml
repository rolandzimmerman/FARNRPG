/// obj_levelup_popup :: Create Event
/// — Initialize everything we need for this popup
// index into the array of infos
if (!variable_global_exists("battle_levelup_index")) global.battle_levelup_index = 0;
// fetch the info struct for this character
info = global.battle_level_up_infos[ global.battle_levelup_index ];
// the list of stat-keys we'll display
keys = ["maxhp","maxmp","atk","def","matk","mdef","spd","luk"];
// box position/size (tweak as needed)
boxX =  (display_get_gui_width()  - 400) / 2;
boxY =  (display_get_gui_height() - 300) / 2;
boxW =  400;
boxH =  300;
padding = 16;
lineH   = 28;

// preload colors/fonts
font = Font1;
fontSize = 0; // leave at default
titleColor = c_white;
oldColor   = c_gray;
sepColor   = c_white;
newColorUp = c_lime;
newColor   = c_white;
