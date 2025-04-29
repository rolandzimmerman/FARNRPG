/// obj_npc_gabby :: User Event 1
// Dialog Definition Event for gabby - Overrides Parent's User Event 1

show_debug_message("gabby User Event 1: Defining dialog for instance ID " + string(id));

// --- gabby's Specific Dialog Data ---
// Define the dialog arrays here. These become instance variables.
dialog_initial = [
    { name: "gabby", msg: "Shinra's in there. I know it." },
    { name: "Boyo", msg: "What? Shinra?" },
    { name: "gabby", msg: "They know I took out the Mako reactor." },
    { name: "Boyo", msg: "Is that why my power went out and the saucer section fell and killed my parents?" },
    { name: "gabby", msg: "Whatever. I'm just here for the paycheck." }
];

dialog_repeat = [
    { name: "gabby", msg: "Whatever. I'm just here for the paycheck." }
];

// DO NOT CALL event_inherited() HERE!