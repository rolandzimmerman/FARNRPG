/// scr_AllEnemiesDefeated()
// Returns true if every entry in global.battle_enemies
// is either destroyed or at 0 HP.

if (!variable_global_exists("battle_enemies")) return false;

var arr = global.battle_enemies;
for (var i = 0; i < array_length(arr); ++i) {
    var foe = arr[i];
    // if it still exists *and* has HP > 0, we're not done
    if (instance_exists(foe) && foe.data.hp > 0)
        return false;
}
return true;
