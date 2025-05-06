/// obj_shop :: Create Event

// 1) Ensure multipliers exist
if (!variable_instance_exists(id, "buyMultiplier"))  buyMultiplier  = 1.0;
if (!variable_instance_exists(id, "sellMultiplier")) sellMultiplier = 1.0;

// 2) Remember which player to reactivate when we close
shop_player_id = instance_find(obj_player, 0);

// 3) Open the shop
shop_active          = true;
shop_state           = "browse";      // or "confirm_purchase"
shop_index           = 0;
shop_confirm_choice  = 0;             // <— 0 == YES, 1 == NO

// 4) Stock default if the NPC didn’t supply any
if (!variable_instance_exists(id, "shop_stock")) {
    shop_stock = ["potion","bomb","antidote"];
}
