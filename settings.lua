data:extend{
    {
        name = "growth_ticks",
        type = 'double-setting',
        default_value = 1.3,
        minimum_value = 0,
        setting_type = "startup",
        order = "aa",
    }, {
        name = "max_health",
        type = 'double-setting',
        default_value = 1.3,
        minimum_value = 0,
        setting_type = "startup",
        order = "ab"
    }, {
        name = "harvest_emissions",
        type = 'double-setting',
        default_value = 1.3,
        minimum_value = 0,
        setting_type = "startup",
        order = "ac"
    }, {
        name = "emmisions_per_second",
        type = 'double-setting',
        default_value = 1.3,
        minimum_value = 0,
        setting_type = "startup",
        order = "ad"
    }, {
        name = "draw_quality_sprite",
        type = "string-setting",
        default_value = "always",
        allowed_values = {
            "none",
            "sometimes",
            "always"
        },
        setting_type = "runtime-per-user",
        order = "ba"
    }, {
        name = "tint_plants",
        type = 'bool-setting',
        default_value = true,
        setting_type = "startup",
        order = "bb"
    }
}
