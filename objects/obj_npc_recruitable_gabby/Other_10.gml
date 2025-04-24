/// obj_npc_recruitable_gabby :: User Event 0 (Interaction)

// Check if this NPC can still be recruited
if (can_recruit) { // This line caused the crash if 'can_recruit' wasn't set in Create
    // Check if character is already in the party (safety check)
    var _already_in_party = false;
    if (variable_global_exists("party_members") && is_array(global.party_members)) {
        for (var i = 0; i < array_length(global.party_members); i++) {
            if (global.party_members[i] == character_key) {
                _already_in_party = true;
                break;
            }
        }
    } else {
        show_debug_message("ERROR: global.party_members missing!");
        exit; // Exit if party list doesn't exist
    }

    if (_already_in_party) {
        show_debug_message("Recruit attempt failed: " + character_key + " is already in the party.");
        dialogue_data = [ { name: "Gabby", msg: "Ready when you are!" } ];
        can_recruit = false; // Prevent further recruit attempts
        create_dialog(dialogue_data); // Show the updated dialogue
    } else {
        // Add character to party
        show_debug_message("Recruiting " + character_key + "!");
        array_push(global.party_members, character_key);
        show_debug_message("Party is now: " + string(global.party_members));

        // Change state - no longer recruitable, update dialogue
        can_recruit = false;
        dialogue_data = [
             { name: "Gabby", msg: "Alright, let's do this! Lead the way!" },
             { name: "System", msg: "Gabby joined the party!" } // System message confirmation
        ];
        create_dialog(dialogue_data); // Show recruitment dialogue

        // Optional: Change sprite, destroy instance, or move instance off-screen
        // instance_destroy(); // Example: NPC disappears after joining
    }

} else {
    // NPC already recruited, just show their current dialogue
    create_dialog(dialogue_data);
}