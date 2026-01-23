local func = require("functions")

-- Generate all the prototypes
local quality_tiers = table.deepcopy(data.raw["quality"])
quality_tiers["quality-unknown"] = nil
quality_tiers["normal"] = nil

if mods["Combo-Technology"] then
    local p = data.raw["plant"]
    local c = data.raw["plant"]["seed-crystal-plant"]
    local d = data.raw["simple-entity"]["seed-crystal"]

    local normalSeedCrystal = table.deepcopy(data.raw["simple-entity"]["seed-crystal"])
    local normalSeedCrystalPlant = table.deepcopy(data.raw["plant"]["seed-crystal-plant"])
    normalSeedCrystal.name = "normal-"..normalSeedCrystal.name
    normalSeedCrystalPlant.name = "normal-"..normalSeedCrystalPlant.name
    data:extend({normalSeedCrystal})
    data:extend({normalSeedCrystalPlant})
    data.raw["plant"]["seed-crystal-plant"]["created_effect"] = nil

    for _, quality in pairs(quality_tiers) do
        local quality_name = quality.name
        if quality_name == "normal" then
            --data.raw["plant"]["seed-crystal-plant"].created_effect.action_delivery.source_effects[2].entity_name = "normal-"..data.raw["plant"]["seed-crystal-plant"].created_effect.action_delivery.source_effects[2].entity_name
        else
            data.raw["plant"][quality_name.."-seed-crystal-plant"].created_effect.action_delivery.source_effects[2].entity_name = quality_name.."-"..data.raw["plant"][quality_name.."-seed-crystal-plant"].created_effect.action_delivery.source_effects[2].entity_name
        end

        -- Creating the quality seed-crystal simple entity
        local seedCrystal = table.deepcopy(data.raw["simple-entity"]["seed-crystal"])
        --seedCrystal.minable.result = quality_name.."-seed-crystal"
        if quality_name ~= "normal" then
            local newSeedCrystal = func.generate_plant(seedCrystal, quality)
            data:extend{newSeedCrystal}
            --seedCrystal.dying_trigger_effect.entity_name = quality_name.."-fulgurite-plant" 
            --seedCrystal.localised_name = {"", "[color=" .. util.rgb_to_hex(quality.color) .. "]", { "entity-name." .. seedCrystal.name }, " (", {"quality-name." .. quality.name }, ")", "[/color]"}
            --seedCrystal.localised_description = {"entity-description."..seedCrystal.name}
            --seedCrystal.name = quality_name.."-seed-crystal"
            --data:extend({seedCrystal})
        end



        -- Creating the intermediate quality seed-crystal-plant
        local x = data.raw["plant"]
        --local effects = data.raw["plant"][quality_name.."-seed-crystal-plant"].created_effect.action_delivery.source_effects
        data.raw["plant"][quality_name.."-seed-crystal-plant"].created_effect.action_delivery.source_effects[1].damage.amount = 99999999
        data.raw["plant"][quality_name.."-seed-crystal-plant"].created_effect.action_delivery.source_effects[2].entity_name = quality_name.."-seed-crystal"
    end
end