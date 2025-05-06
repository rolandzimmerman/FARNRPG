/// obj_npc_shopkeeper :: User Event 0
if (!can_talk || instance_exists(obj_shop)) exit;

// spawn shop controller
var shop = instance_create_layer(0, 0, "Instances", obj_shop);
shop.buyMultiplier  = 1.2;
shop.sellMultiplier = 0.5;
shop.shop_stock     = ["potion","bomb","antidote"];
shop.shop_player_id = instance_find(obj_player,0);

// freeze the player
instance_deactivate_object(obj_player);
