/// obj_battle_enemy :: Step Event (Example Parent)
// Handles combat animation state machine.

// — AUTO-TRIGGER ENEMY DEATH —
if (variable_instance_exists(id, "data")
 && is_struct(data)
 && data.hp <= 0
 && combat_state != "dying"
 && combat_state != "corpse"
 && combat_state != "dead") {
    death_started = false;
    combat_state  = "dying";

    // Log enemy death
    scr_AddBattleLog("Enemy dying");

    show_debug_message("Enemy " + string(id) + " entering dying state");
    return;
}

// Update origin AND original scale while idle
if (combat_state == "idle") {
    origin_x = x;
    origin_y = y;
    // <<< MODIFICATION: Store original scale reliably >>>
    if (!variable_instance_exists(id, "original_scale")) {
        original_scale = image_xscale;
    } else {
        original_scale = image_xscale;
    }
    // Ensure scale matches original
    if (image_xscale != original_scale) {
        image_xscale = original_scale;
        image_yscale = original_scale;
    }
    // <<< END MODIFICATION >>>
}

// --- Combat Animation State Machine ---
switch (combat_state) {
    case "idle":
        // Wait for attack_start; stop any anim speed
        if (image_speed != 0) image_speed = 0;
        break;

    case "attack_start":
        show_debug_message(object_get_name(object_index)
                         + " " + string(id)
                         + ": State -> attack_start, Target: "
                         + string(target_for_attack));

        origin_x = x;
        origin_y = y;
        if (!variable_instance_exists(id, "original_scale"))
            original_scale = image_xscale;

        // Calculate target position
        var _target_x = origin_x;
        var _target_y = origin_y;
        var target_exists = instance_exists(target_for_attack);
        if (target_exists) {
            _target_x = target_for_attack.x;
            _target_y = target_for_attack.y;
        }
        var _offset = 192;
        var _dir = point_direction(x, y, _target_x, _target_y);
        var _move_x = _target_x - lengthdir_x(_offset, _dir);
        var _move_y = _target_y - lengthdir_y(_offset, _dir);

        // <<< MODIFICATION: Match target scale >>>
        if (target_exists) {
            var _sx = variable_instance_get(target_for_attack, "image_xscale") ?? 1;
            var _sy = variable_instance_get(target_for_attack, "image_yscale") ?? 1;
            image_xscale = _sx;
            image_yscale = _sy;
            show_debug_message("    -> Matched enemy scale: " + string(_sx));
        }
        // <<< END MODIFICATION >>>

        // Teleport in front of target
        x = _move_x;
        y = _move_y;

        // Play chosen sound
        var _snd = variable_instance_get(id, "current_attack_fx_sound") ?? snd_punch;
        if (audio_exists(_snd)) audio_play_sound(_snd, 10, false);

        // --- LOG DAMAGE ---
        var _old_hp = 0;
        if (target_exists && variable_instance_exists(target_for_attack, "data")) {
            _old_hp = target_for_attack.data.hp;
        }

        // Apply the attack (AI script)
        var _action_succeeded = false;
        if (script_exists(scr_EnemyAttackRandom)) {
            _action_succeeded = scr_EnemyAttackRandom(id);
        }

        // After damage is applied:
        if (_action_succeeded && instance_exists(target_for_attack)
         && variable_instance_exists(target_for_attack, "data")) {
            var _new_hp = target_for_attack.data.hp;
            var _dmg    = _old_hp - _new_hp;
            var _tname  = target_for_attack.data.name ?? "Unknown";
            var _ename  = data.name ?? object_get_name(object_index);
            scr_AddBattleLog(_ename + " deals " + string(_dmg)
                           + " damage to " + _tname);
        }

        // Create visual effect
        if (_action_succeeded && instance_exists(target_for_attack)
         && object_exists(obj_attack_visual)) {
            var _fx_x = target_for_attack.x;
            var _fx_y = target_for_attack.y - 32;
            var _layer = layer_get_id("Instances");
            if (_layer != -1) {
                var fx = instance_create_layer(
                    _fx_x, _fx_y, _layer, obj_attack_visual
                );
                if (instance_exists(fx)) {
                    var _spr = variable_instance_get(id, "current_attack_fx_sprite") ?? spr_pow;
                    fx.sprite_index = sprite_exists(_spr) ? _spr : spr_pow;
                    // <<< MOD: set FX depth over target >>>
                    fx.depth       = target_for_attack.depth - 1;
                    fx.image_speed = 1;
                    show_debug_message("    -> FX (" + string(fx)
                                    + ") depth=" + string(fx.depth));
                    // <<< END MOD >>>
                    fx.owner_instance = id;
                    attack_animation_finished = false;
                } else {
                    attack_animation_finished = true;
                }
            } else {
                attack_animation_finished = true;
                show_debug_message("ERROR: Instances layer not found for FX!");
            }
        } else {
            attack_animation_finished = true;
        }

        combat_state = "attack_waiting";
        break;

    case "attack_waiting":
        if (attack_animation_finished) {
            combat_state = "attack_return";
            attack_animation_finished = false;
        }
        break;

    case "attack_return":
        show_debug_message("ENEMY_STEP: " + string(id)
                         + ": State -> attack_return");
        x = origin_x;
        y = origin_y;
        var _rs = variable_instance_get(id, "original_scale") ?? 1.0;
        image_xscale = _rs;
        image_yscale = _rs;
        show_debug_message("    -> Restored scale: " + string(_rs));
        if (instance_exists(obj_battle_manager)) {
            obj_battle_manager.current_attack_animation_complete = true;
        }
        target_for_attack = noone;
        combat_state = "idle";
        break;

    case "dying":
        if (!death_started) {
            var anim = spr_death;
            if (variable_struct_exists(data, "death_anim_sprite")
             && sprite_exists(data.death_anim_sprite)) {
                anim = data.death_anim_sprite;
            }
            sprite_index  = anim;
            image_index   = 0;
            image_speed   = death_anim_speed;
            death_started = true;
        } else if (image_index >= sprite_get_number(sprite_index) - 1) {
            var corpse = spr_dead;
            if (variable_struct_exists(data, "corpse_sprite")
             && sprite_exists(data.corpse_sprite)) {
                corpse = data.corpse_sprite;
            }
            sprite_index = corpse;
            image_index  = 0;
            image_speed  = 0;
            combat_state = "corpse";
        }
        break;

    case "corpse":
        // Drop logic once
        if (!has_been_dropped) {
            has_been_dropped = true;
            for (var i = 0; i < array_length(data.drop_table); i++) {
                var e = data.drop_table[i];
                if (irandom(999)/1000 < e.chance) {
                    scr_AddInventoryItem(e.item_key, 1);
                    // Log the drop
                    var _ename = data.name ?? object_get_name(object_index);
                    scr_AddBattleLog(_ename + " dropped " + e.item_key);
                    show_debug_message(" Enemy " + string(id)
                                    + " dropped: " + e.item_key);
                }
            }
        }
        break;
} // End switch
