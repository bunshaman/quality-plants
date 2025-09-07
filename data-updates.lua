local Functions = require("functions")

--- Runs execute if a mod setting is set to true
---@param mod_setting string
---@param execute any
function if_mod_setting(mod_setting, execute) if settings.startup[mod_setting].value then return execute else return nil end end

-- Generate Fake Quality Plant Entity
function generate_plant(prototype, quality_color, quality_name, quality_increase, quality_level)
    local plant_prototype = table.deepcopy(prototype)

    if settings.startup["tint_plants"].value then
        Functions.tintPlantPrototype(plant_prototype, quality_color)
    end
    quality_color = Functions.convert_to_hex(quality_color)

    plant_prototype.fast_replaceable_group = plant_prototype.name
    if plant_prototype.name == "tree-plant" then    -- Hardcoding a fix for wood trees...
        plant_prototype.localised_name = {"", "[color=" .. quality_color .. "]", { "entity-name.tree"}, " (", {"quality-name." .. quality_name }, ")", "[/color]"}
    else
        plant_prototype.localised_name = {"", "[color=" .. quality_color .. "]", { "entity-name." .. plant_prototype.name }, " (", {"quality-name." .. quality_name }, ")", "[/color]"}
    end
    plant_prototype.localised_description = {"entity-description."..plant_prototype.name}
    plant_prototype.name = quality_name.."-"..plant_prototype.name

    plant_prototype.hidden = true
    plant_prototype.hidden_in_factoriopedia = true
    plant_prototype.order = plant_prototype.order and (plant_prototype.order .. quality_level) or nil
    plant_prototype.growth_ticks = if_mod_setting("growth_ticks", plant_prototype.growth_ticks * quality_increase) or plant_prototype.growth_ticks
    plant_prototype.harvest_emissions = if_mod_setting("harvest_emissions", Functions.scale_existing_target(plant_prototype.harvest_emissions, quality_increase)) or plant_prototype.harvest_emissions
    plant_prototype.max_health = if_mod_setting("max_health", Functions.scale_existing_target(plant_prototype.max_health, quality_increase)) or plant_prototype.max_health
    plant_prototype.autoplace = nil
    plant_prototype.minable = Functions.update_mining_results(plant_prototype.minable, quality_name)
    return plant_prototype
end




-- Generate Fake Quality Fruit/Item
function generate_plant_products(prototype, quality_color, quality_name, quality_increase, quality_level) -- Generates the product from the plant
    if prototype.minable then -- why run this whole thing if no mining results?
        local products = prototype.minable.results
        local product_prototypes = {}
        for i, product in pairs(products) do
            local product_prototype = table.deepcopy(data.raw[product.type][product.name])
            if product_prototype == nil then    -- weird thing with item types. Possibly do better in the future
                product_prototype = table.deepcopy(data.raw["capsule"][product.name]) or table.deepcopy(data.raw["tool"][product.name])
            end

            quality_color = Functions.convert_to_hex(quality_color)
            product_prototype.localised_name = {"", "[color=" .. quality_color .. "]", { "item-name." .. product_prototype.name }, " (", {"quality-name." .. quality_name }, ")", "[/color]"}

            product_prototype.hidden = true
            product_prototype.hidden_in_factoriopedia = true
            product_prototype.subgroup = nil
            product_prototype.order = product_prototype.order and (product_prototype.order..quality_level) or nil
            product_prototype.spoil_result = nil
            product_prototype.spoil_ticks = 1
            product_prototype.spoil_to_trigger_result =
            {
                items_per_trigger = 1,
                trigger = {
                    type = "direct",
                    action_delivery = {
                        type = "instant",
                        source_effects = {
                            {
                                type = "script",
                                effect_id = "{quality = "..quality_name..", item = "..product_prototype.name.."}QUALITYPLANTS"
                            }
                        }
                        }
                }
            }
            product_prototype.name = quality_name.."-"..product_prototype.name

            table.insert(product_prototypes, product_prototype)
        end
        return product_prototypes
    end
end



-- Generate all the prototypes
local quality_tiers = table.deepcopy(data.raw["quality"])
quality_tiers["quality-unknown"] = nil
quality_tiers["normal"] = nil

local plants = {}
for name, prototype in pairs(data.raw["plant"]) do
    prototype.fast_replaceable_group = prototype.name
    table.insert(plants, prototype)
end


for _, quality in pairs(quality_tiers) do
    local quality_name = quality.name
    local quality_increase = 1 + 0.3 * quality.level

    -- Generate the plant and product prototypes
    for _, plant in pairs(plants) do
        local plant_prototype = generate_plant(plant, quality.color, quality_name, quality_increase, quality.level)
        local product_prototypes = generate_plant_products(plant, quality.color, quality_name, quality_increase, quality.level)
        if product_prototypes then 
            for i, product_prototype in pairs(product_prototypes) do
                Functions.place_icon_on_item(product_prototype, quality_name)
            end
            data:extend(product_prototypes)
        end

        data:extend{plant_prototype}
    end
end

--data.raw["tile"]["empty-space"].collision_mask.layers = {["ground_tile"] = true}      -- for thumbnail