local Functions = require("functions")

-- Generate all the prototypes
local quality_tiers = table.deepcopy(data.raw["quality"])
quality_tiers["quality-unknown"] = nil
--quality_tiers["normal"] = nil


if mods["Combo-Technology"] then
    local normalSeedCrystal = table.deepcopy(data.raw["simple-entity"]["seed-crystal"])
    local normalSeedCrystalPlant = table.deepcopy(data.raw["plant"]["seed-crystal-plant"])
    normalSeedCrystal.name = "normal-"..normalSeedCrystal.name
    normalSeedCrystalPlant.name = "normal-"..normalSeedCrystalPlant.name
    data:extend({normalSeedCrystal})
    data:extend({normalSeedCrystalPlant})
    data.raw["plant"]["seed-crystal-plant"]["created_effect"] = nil

    --local plant_prototype = data.raw["plant"]["seed-crystal-plant"]


    for _, quality in pairs(quality_tiers) do
        local quality_name = quality.name
        -- Creating the quality seed-crystal
        local seedCrystal = table.deepcopy(data.raw["simple-entity"]["seed-crystal"])
        --seedCrystal.minable.result = quality_name.."-seed-crystal"
        seedCrystal.name = quality_name.."-seed-crystal"
        if quality_name ~= "normal" then
            seedCrystal.dying_trigger_effect.entity_name = quality_name.."-fulgurite-plant" 
            data:extend({seedCrystal})
        end



        -- Creating the intermediate quality seed-crystal-plant
        local effects = data.raw["plant"][quality_name.."-seed-crystal-plant"].created_effect.action_delivery.source_effects
        data.raw["plant"][quality_name.."-seed-crystal-plant"].created_effect.action_delivery.source_effects[1].damage.amount = 99999999
        data.raw["plant"][quality_name.."-seed-crystal-plant"].created_effect.action_delivery.source_effects[2].entity_name = quality_name.."-seed-crystal"
    end
end


--- add a script trigger to each seed-crystal-plant with the quality of the seed so I can detect when a seed was placed.
--- 
--- Well actually, could possibly remove the trigger event so the ag tower stuff can run, and then replace at the end?