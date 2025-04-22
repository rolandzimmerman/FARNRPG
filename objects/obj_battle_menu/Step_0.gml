/// obj_battle_menu :: Step Event

// #FIX 1: Removed all button input checks (A, B, X, Y).
// This object is now only responsible for drawing the UI.
// All player battle input is handled by obj_battle_player.

// Example: Could have logic here for animating the menu appearance/disappearance if needed
// if (alpha < 1) alpha += 0.1; // Fade in example (needs alpha variable in Create)