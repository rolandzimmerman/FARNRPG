/// obj_npc_lexy :: User Event 1
// Dialog Definition Event for lexy - Overrides Parent's User Event 1

show_debug_message("lexy User Event 1: Defining dialog for instance ID " + string(id));

// --- lexy's Specific Dialog Data ---
// Define the dialog arrays here. These become instance variables.
dialog_initial = [
    { name: "lexy", msg: "Shinra's in there. I know it." },
    { name: "Boyo", msg: "What? Shinra?" },
    { name: "lexy", msg: "They know I took out the Mako reactor." },
    { name: "Boyo", msg: "Is that why my power went out and the saucer section fell and killed my parents?" },
    { name: "lexy", msg: "Whatever. I'm just here for the paycheck." }
];

dialog_repeat = [
    { name: "lexy", msg: "Whatever. I'm just here for the paycheck." }
];

// DO NOT CALL event_inherited() HERE!