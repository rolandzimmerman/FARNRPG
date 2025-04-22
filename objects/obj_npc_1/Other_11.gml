/// obj_npc_dom :: User Event 1
// Dialog Definition Event for Dom - Overrides Parent's User Event 1

show_debug_message("Dom User Event 1: Defining dialog for instance ID " + string(id));

// --- Dom's Specific Dialog Data ---
// Define the dialog arrays here. These become instance variables.
dialog_initial = [
    { name: "Dom", msg: "Welcome to Dom's Subs" },
    { name: "Boyo", msg: "What do you guys sell?" },
    { name: "Dom", msg: "Sandwiches. Just sandwiches. Submarine sandwiches and nothing else." },
    { name: "Boyo", msg: "Oh, that's nice." },
    { name: "Dom", msg: "Yeah. Yeah, you know what? Yeah, it is nice. It is nice to sell subs-- submarine sandwiches." }
];

dialog_repeat = [
    { name: "Dom", msg: "Yeah. Yeah, you know what? Yeah, it is nice. It is nice to sell subs-- submarine sandwiches." }
];

// DO NOT CALL event_inherited() HERE!