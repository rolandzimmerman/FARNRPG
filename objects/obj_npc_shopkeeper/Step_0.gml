/// obj_npc_shopkeeper :: Step Event

// if the shop UI is already open, skip
if (instance_exists(obj_shop)) exit;

// otherwise let the parent handle proximity/talk
event_inherited();

// when player presses the interact key, open the shop
if (can_talk
 && keyboard_check_pressed(input_key)
 && !instance_exists(obj_dialog)
 && !instance_exists(obj_shop)) {

    var S = instance_create_layer(0, 0, "Instances", obj_shop);
    S.buyMultiplier  = buyMultiplier;
    S.sellMultiplier = sellMultiplier;
    S.shop_stock     = shop_stock;
    S.shop_player_id = instance_find(obj_player, 0);
}
