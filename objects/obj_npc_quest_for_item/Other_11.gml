// obj_npc_dom :: User Event 1
// Quest: Bring me a potion; reward is 1 bomb + 500 XP.
show_debug_message("Dom Quest Triggered (ID " + string(id) + ")");

// Initial prompt
dialog_initial = [
    { name:"Dom", msg:"Listen, I really need a potion. I'll give you a bomb and 500 XP as a reward." }
];

// Branch on whether the player has at least 1 potion
if (scr_HaveItem("potion", 1)) {
    dialog_repeat = [
        { name:"Dom", msg:"Ah, perfect, just what I needed!" },
        { name:"Dom", msg:"Here—take your bomb and XP." },

        // Remove the potion
        {
          name:"", msg:"",
          script_to_run: scr_RemoveInventoryItem,
          script_args:   ["potion", 1]
        },
        // Add the bomb
        {
          name:"", msg:"",
          script_to_run: scr_AddInventoryItem,
          script_args:   ["bomb",   1]
        },
        // Award XP to the whole party
        {
          name:"", msg:"",
          script_to_run: scr_AddXPToParty,
          script_args:   [500]
        },
        {
          name:"", msg:"",
          script_to_run: scr_AddCurrency,
          script_args:   [500]
        },
        { name:"Boyo", msg:"Thanks, Dom!" }
    ];
} else {
    dialog_repeat = [
        { name:"Dom",  msg:"Hey, did you grab that potion yet?" },
        { name:"Boyo", msg:"Not yet, sorry!" },
        { name:"Dom",  msg:"Come back when you have one." }
    ];
}

// We override Dom’s normal talk, so do NOT call event_inherited().