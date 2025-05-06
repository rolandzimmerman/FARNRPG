/// obj_shop :: Step Event

// 1) If shop isn't active, nothing to do
if (!shop_active) exit;

// 2) Read inputs (keyboard + gamepad)
var device  = 0;
var up      = keyboard_check_pressed(vk_up)    || gamepad_button_check_pressed(device, gp_padu);
var down    = keyboard_check_pressed(vk_down)  || gamepad_button_check_pressed(device, gp_padd);
var left    = keyboard_check_pressed(vk_left)  || gamepad_button_check_pressed(device, gp_padl);
var right   = keyboard_check_pressed(vk_right) || gamepad_button_check_pressed(device, gp_padr);
var confirm = keyboard_check_pressed(vk_enter) 
            || keyboard_check_pressed(vk_space) 
            || gamepad_button_check_pressed(device, gp_face1);
var cancel  = keyboard_check_pressed(vk_escape) 
            || gamepad_button_check_pressed(device, gp_face2);

// Ensure we have all our shop variables
shop_index           = shop_index           ?? 0;
shop_state           = shop_state           ?? "browse";
shop_confirm_choice  = shop_confirm_choice  ?? 0;
var stock            = shop_stock;

// 3) Browse state: show list, up/down moves, confirm enters yes/no
if (shop_state == "browse") {
    var count = array_length(stock);
    if (count > 0) {
        if (up)   shop_index = (shop_index - 1 + count) mod count;
        if (down) shop_index = (shop_index + 1) mod count;
    }

    if (confirm && count > 0) {
        // move into confirmation
        shop_state          = "confirm_purchase";
        shop_confirm_choice = 0; // default to YES
    }
    if (cancel) {
        // close the shop
        shop_active = false;
        // reactivate player control if you deactivated it on open:
        instance_activate_object(obj_player);
        exit;
    }
}

// 4) Confirm state: left/right toggles YES/NO; confirm commits
else if (shop_state == "confirm_purchase") {
    // toggle between 0 (YES) and 1 (NO)
    if (left  || right) {
        shop_confirm_choice = clamp(shop_confirm_choice + (right - left), 0, 1);
    }

    if (confirm) {
        if (shop_confirm_choice == 0) {
            // YES: attempt purchase
            var key   = stock[shop_index];
            var data  = scr_GetItemData(key);
            var base  = (data.value ?? 0);
            var price = ceil(base * buyMultiplier);

            if (global.party_currency >= price) {
                scr_SpendCurrency(price);
                scr_AddInventoryItem(key, 1);
                audio_play_sound(snd_buy, 1, false);
                show_message("Bought 1 " + (data.name ?? key) + " for " + string(price) + "g.");
            } else {
                show_message("Not enough gold!");
            }
        }
        // return to browse (or close if you want)
        shop_state = "browse";
    }

    if (cancel) {
        // NO: just go back
        shop_state = "browse";
    }
}
