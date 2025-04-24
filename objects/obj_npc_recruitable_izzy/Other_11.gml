/// obj_npc_izzy :: User Event 1
// Dialog Definition Event for izzy - Overrides Parent's User Event 1

show_debug_message("izzy User Event 1: Defining dialog for instance ID " + string(id));

// --- izzy's Specific Dialog Data ---
// Define the dialog arrays here. These become instance variables.
dialog_initial = [
    { name: "izzy", msg: "Shinra's in there. I know it." },
    { name: "Boyo", msg: "What? Shinra?" },
    { name: "izzy", msg: "They know I took out the Mako reactor." },
    { name: "Boyo", msg: "Is that why my power went out and the saucer section fell and killed my parents?" },
    { name: "izzy", msg: "Whatever. I'm just here for the paycheck." }
];

dialog_repeat = [
    { name: "izzy", msg: "Whatever. I'm just here for the paycheck." }
];

// DO NOT CALL event_inherited() HERE!