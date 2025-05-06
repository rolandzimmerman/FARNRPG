/// obj_shop :: Step Event

// 1) Only run while the shop is active
if (!shop_active) exit;

// 2) Gather inputs
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

// 3) Ensure our variables exist
shop_index           = shop_index           ?? 0;
shop_state           = shop_state           ?? "browse";
shop_confirm_choice  = shop_confirm_choice  ?? 0;
var stock            = shop_stock;

// 4) BROWSE STATE: navigate list, confirm to buy, cancel to close
if (shop_state == "browse") {
    var count = array_length(stock);
    if (count) {
        if (up)   shop_index = (shop_index - 1 + count) mod count;
        if (down) shop_index = (shop_index + 1) mod count;
    }

    if (confirm && count) {
        shop_state          = "confirm_purchase";
        shop_confirm_choice = 0;
    }

    if (cancel) {
        shop_active = false;
        instance_activate_object(obj_player);  
        exit;
    }
}

// 5) CONFIRM STATE: choose YES/NO, commit with dialog
else if (shop_state == "confirm_purchase") {
    // toggle between YES (0) and NO (1)
    if (left  || right) {
        shop_confirm_choice = clamp(shop_confirm_choice + (right - left), 0, 1);
    }

    if (confirm) {
        var key  = stock[shop_index];
        var data = scr_GetItemData(key);
        var base = data.value ?? 0;
        var price = ceil(base * buyMultiplier);

        if (shop_confirm_choice == 0) {
            // YES branch
            if (global.party_currency >= price) {
                scr_SpendCurrency(price);
                scr_AddInventoryItem(key, 1);
                audio_play_sound(snd_buy, 1, false);

                create_dialog([
                  { name:"Shop", msg:"Bought 1 " 
                                   + (data.name ?? key) 
                                   + " for " + string(price) + "g." }
                ]);
            } else {
                create_dialog([
                  { name:"Shop", msg:"You don’t have enough gold!" }
                ]);
            }
        }
        // go back to browsing once the dialog is up
        shop_state = "browse";
    }

    if (cancel) {
        // NO branch: just return to list
        shop_state = "browse";
    }
}
