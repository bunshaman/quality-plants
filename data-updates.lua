function convert_to_hex(rgb)
    rgb = {rgb[1] or rgb.r, rgb[2] or rgb.g, rgb[3] or rgb.b}
    local hex = ""
    if (rgb[1] < 1) and (rgb[2] < 1) and (rgb[3] < 1) then
        rgb[1] = math.ceil(rgb[1] * 255)
        rgb[2] = math.ceil(rgb[2] * 255)
        rgb[3] = math.ceil(rgb[3] * 255)
    end
    for i = 1 , #rgb do
        local hex_table = {"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}
        local num =  rgb[i]/16 
        local whole = math.floor( num )
        local remainder = num - whole
        hex = hex .. hex_table[whole+1] .. hex_table[remainder*16 + 1]
    end
    return "#"..hex
end


function insert_quality_icons(item, quality)
    if quality.icons then
        for _, icon in pairs(quality.icons) do
		    table.insert(item.icons, { icon = icon.icon, tint = icon.tint, icon_size = icon.icon_size, scale = 0.25, shift = { -10, 10 }})
        end
    else
        table.insert(item.icons, { icon = quality.icon, tint = quality.tint, icon_size = quality.icon_size, scale = 0.25, shift = { -10, 10 }})
    end
end


function place_icon_on_item(item, target_quality)
	local quality = data.raw.quality[target_quality]

	if item.icons then
		--item.icons.insert({ icon = quality.icon, icon_size = item.icon_size, scale = 0.25, shift = { -10, 10 } })
        insert_quality_icons(item, quality)
	else
		item.icons = {
			{ icon = item.icon, icon_size = item.icon_size }
		}
		--item.icons.insert({ icon = quality.icon, icon_size = item.icon_size, scale = 0.25, shift = { -10, 10 } })
        insert_quality_icons(item, quality)
		item.icon = nil
	end
end


-- Scales every entry in a table, or a number only if it exists already in a normal prototype
---@param variable number|table
---@param quality_increase number
---@return number|table|nil
function scale_existing_target(variable, quality_increase)
    if variable ~= nil then
        if type(variable) == "table" then
            for i, j in pairs(variable) do
                variable[i] = variable[i] * quality_increase
            end
            return variable
        else
            return variable * quality_increase
        end
    else
        log("Error attempting to scale an attribute by quality, skipping")
        return nil
    end
end

---@param minable any
---@param quality_name any
function update_mining_results(minable, quality_name)
    if minable.result then
        minable.result = quality_name.."-"..minable.result
    end
    if minable.results then
        for i, result in pairs(minable.results) do
            minable.results[i].name = quality_name.."-"..result.name
        end
    end
    if not minable then return nil end
    return minable
end





---@param condition_name string
---@param execute any
function if_mod_setting(condition_name, execute) if settings.startup[condition_name].value then return execute else return nil end end

-- Generate Fake Quality Plant Entity
function generate_plant(prototype, quality_color, quality_name, quality_increase, quality_level)
    local plant_prototype = table.deepcopy(prototype)

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
    plant_prototype.harvest_emissions = if_mod_setting("harvest_emissions", scale_existing_target(plant_prototype.harvest_emissions, quality_increase)) or plant_prototype.harvest_emissions
    plant_prototype.max_health = if_mod_setting("max_health", scale_existing_target(plant_prototype.max_health, quality_increase)) or plant_prototype.max_health
    plant_prototype.autoplace = nil
    plant_prototype.minable = update_mining_results(plant_prototype.minable, quality_name)
    return plant_prototype
end




-- Generate Fake Quality Fruit/Item
function generate_plant_products(prototype, quality_color, quality_name, quality_increase, quality_level) -- Generates the product from the plant
    local products = prototype.minable.results
    local product_prototypes = {}
    for i, product in pairs(products) do
        local product_prototype = table.deepcopy(data.raw[product.type][product.name])
        if product_prototype == nil then    -- weird thing with item types. Possibly do better in the future
            product_prototype = table.deepcopy(data.raw["capsule"][product.name]) or table.deepcopy(data.raw["tool"][product.name])
        end

        product_prototype.localised_name = {"", "[color=" .. quality_color .. "]", { "item-name." .. product_prototype.name }, " (", {"quality-name." .. quality_name }, ")", "[/color]"}

        product_prototype.hidden = true
        product_prototype.hidden_in_factoriopedia = true
        product_prototype.subgroup = nil
        product_prototype.order = product_prototype.order and ("z"..product_prototype.order..quality_level) or nil
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
                            effect_id = "{quality = "..quality_name..", item = "..product_prototype.name.."}"
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
    local quality_color = convert_to_hex(quality.color)
    local quality_name = quality.name
    local quality_increase = 1 + 0.3 * quality.level

    -- Generate the plant and product prototypes
    for _, plant in pairs(plants) do
        local plant_prototype = generate_plant(plant, quality_color, quality_name, quality_increase, quality.level)
        local product_prototypes = generate_plant_products(plant, quality_color, quality_name, quality_increase, quality.level)
        for i, product_prototype in pairs(product_prototypes) do
            place_icon_on_item(product_prototype, quality_name)
        end

        data:extend{plant_prototype}
        data:extend(product_prototypes)
    end
end



--data.raw["tile"]["empty-space"].collision_mask.layers = {["ground_tile"] = true}      -- for thumbnail