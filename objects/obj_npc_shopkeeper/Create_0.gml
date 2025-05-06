/// obj_npc_shopkeeper :: Create Event
event_inherited();  // calls obj_npc_parent :: Create

// shop parameters for *this* NPC:
buyMultiplier   = 1.2;
sellMultiplier  = 0.5;
shop_stock      = ["potion","bomb","antidote"];

// suppress parent‐dialog errors:
dialog_initial = [];
dialog_repeat  = [];

