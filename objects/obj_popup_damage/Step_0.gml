/// obj_popup_damage :: Step Event

y += vspd;
lifespan -= 1;
alpha = lifespan / 30;

if (lifespan <= 0) {
    instance_destroy();
}
