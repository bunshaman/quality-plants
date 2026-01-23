local func = require("functions")

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


    --if settings.startup["tint_plants"].value then
    --    Functions.tintPlantPrototype(plant_prototype, quality_color)
    --end


-- Generate all the prototypes
local plants = {}
for name, prototype in pairs(data.raw["plant"]) do
    prototype.fast_replaceable_group = prototype.name
    table.insert(plants, prototype)
end

for _, quality in pairs(data.raw["quality"]) do
    if not (quality.name == "quality-unknown" or quality.name == "normal") then
        -- Generate the plant prototypes
        for _, plant in pairs(plants) do
            local new_plant = func.generate_plant(plant, quality)
            if settings.startup["tint_plants"].value then
                func.tint_plant(new_plant, quality)
            end
            data:extend{new_plant}
        end
    end
end