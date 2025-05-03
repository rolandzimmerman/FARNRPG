/// obj_attack_visual :: Animation End Event
show_debug_message(
    ">>> obj_attack_visual Animation End ("
  + string(id)
  + ") Owner: "
  + string(owner_instance)
);

if (instance_exists(owner_instance)
 && variable_instance_exists(owner_instance, "attack_animation_finished")) {
    owner_instance.attack_animation_finished = true;
}

instance_destroy();
