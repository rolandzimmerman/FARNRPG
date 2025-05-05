/// obj_npc_dom :: User Event 1
// Dialog Definition Event for Dom - Overrides Parent's User Event 1

show_debug_message("Dom User Event 1: Defining dialog for instance ID " + string(id));

// --- Dom's Specific Dialog Data ---
dialog_initial = [
    { name: "Dom", msg: "Welcome to Dom's Subs" },
    { name: "Boyo", msg: "What do you guys sell?" },
    { name: "Dom", msg: "Sandwiches. Just sandwiches. Submarine sandwiches and nothing else." },
    { name: "Boyo", msg: "Oh, that's nice." },
    {
        name: "Dom",
        msg: "Yeah. Yeah, you know what? Yeah, it is nice. It is nice to sell subs-- submarine sandwiches. Here, take this.",
        script_to_run: scr_AddInventoryItem, // <-- Directly reference the inventory script
        script_args: ["potion", 1]          // <-- Define arguments as an array
    },
     { name: "Boyo", msg: "Uh... thanks?"} // Optional reaction
];

dialog_repeat = [
    { name: "Dom", msg: "Yeah. Yeah, you know what? Yeah, it is nice. It is nice to sell subs-- submarine sandwiches." }
];

// DO NOT CALL event_inherited() HERE!

// Note: The intermediate 'scr_give_potion' script is no longer needed for this specific action.