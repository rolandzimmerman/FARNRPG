/// @function GetResistanceMultiplier(_resistances_struct, _element)
/// @description Calculates the damage multiplier based on target resistances and attack element.
/// @param {Struct} _resistances_struct The target's resistance data struct { physical: 0.1, fire: -0.5, ... } (Values are % reduction/increase)
/// @param {String} _element The element of the incoming attack (e.g., "physical", "fire").
/// @returns {Real} Damage multiplier (e.g., 1.0 for normal, 0.9 for 10% resist, 1.5 for 50% weakness).
function GetResistanceMultiplier(_resistances_struct, _element) {
    var _multiplier = 1.0; // Default: normal damage

    if (is_struct(_resistances_struct) && is_string(_element) && _element != "") {
        // Check if the specific element exists in the resistance struct
        if (variable_struct_exists(_resistances_struct, _element)) {
            var _resistance_value = variable_struct_get(_resistances_struct, _element);
            
            // Convert resistance percentage to multiplier
            // E.g., 0.1 (10% resist) -> multiplier 0.9
            // E.g., -0.5 (50% weak) -> multiplier 1.5
            // E.g., 1.0 (100% resist/immune) -> multiplier 0.0
             _multiplier = 1.0 - _resistance_value;

            // Clamp multiplier (e.g., can't heal from weakness, immunity is 0x)
            _multiplier = max(0, _multiplier); // Ensure multiplier doesn't go below 0 (healing from damage)

        } else {
            // Element not found in struct, assume neutral resistance
            _multiplier = 1.0;
        }
    } else {
         // Invalid input, assume neutral resistance
         _multiplier = 1.0;
    }
    
    // show_debug_message(" -> Resistance Check: Element='" + _element + "', Multiplier=" + string(_multiplier));
    return _multiplier;
}