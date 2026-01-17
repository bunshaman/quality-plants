local util = {}


--- Returns execute if a startup mod setting is set to true
--- @param mod_setting string
--- @param execute any
function util.if_mod_setting(mod_setting, execute) if settings.startup[mod_setting].value then return execute else return nil end end


--- @param variable number|table
--- @param quality_increase number
--- @return any
function util.mutiply_table(variable, quality_increase)
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

--- Converts an rgb table into a hex number
--- @param rgb {r: number, g: number, b: number}|{[1]: number, [2]: number, [3]: number}  -- table with red, green, blue values
--- @return string   
function util.rgb_to_hex(rgb)
    rgb = {rgb[1] or rgb.r, rgb[2] or rgb.g, rgb[3] or rgb.b}
    local hex = ""
    if (rgb[1] <= 1) and (rgb[2] <= 1) and (rgb[3] <= 1) then  -- If all numbers are between 0 and 1, the game treats the values differently
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


--- Adds quality icons to an item prototype
--- @param itemPrototype data.ItemPrototype|data.CapsulePrototype|data.ToolPrototype
--- @param qualityPrototype data.QualityPrototype
function util.insert_quality_icons(itemPrototype, qualityPrototype)
    if qualityPrototype.icons then
        for _, icon in pairs(qualityPrototype.icons) do
		    table.insert(itemPrototype.icons, { icon = icon.icon, tint = icon.tint, icon_size = icon.icon_size, scale = 0.25, shift = { -10, 10 }})
        end
    else
        table.insert(itemPrototype.icons, { icon = qualityPrototype.icon, icon_size = qualityPrototype.icon_size, scale = 0.25, shift = { -10, 10 }})
    end
    return itemPrototype.icons
end

--- Adds quality icons to an item prototype
--- @param itemPrototype data.ItemPrototype|data.CapsulePrototype|data.ToolPrototype
--- @param qualityPrototype data.QualityPrototype
function util.place_icon_on_item(itemPrototype, qualityPrototype)
    local icons = {}
	if itemPrototype.icons then
        icons = util.insert_quality_icons(itemPrototype, qualityPrototype)
	else
		itemPrototype.icons = {{ icon = itemPrototype.icon, icon_size = itemPrototype.icon_size }}
        icons = util.insert_quality_icons(itemPrototype, qualityPrototype)
		itemPrototype.icon = nil
	end
    return icons
end


--- Generates the item prototype
--- @param name any
--- @param quality any
function util.createMiningResult(name, quality)
    local newResult = table.deepcopy(data.raw["item"][name] or data.raw["capsule"][name] or data.raw["tool"][name])
    if newResult == nil then log("Error: mining result has a type that is not item, capsule, or tool. Please report to mod author with information about: Plants mined, mods used, and what the mining result is supposed to be.") return end


    -- Hidden
    newResult.hidden = true
    newResult.hidden_in_factoriopedia = true

    newResult.localised_name = {"", "[color=" .. util.rgb_to_hex(quality.color) .. "]", { "item-name." .. newResult.name }, " (", {"quality-name." .. quality.name }, ")", "[/color]"}
    newResult.spoil_result = nil
    newResult.spoil_ticks = 1
    newResult.spoil_to_trigger_result = {
        items_per_trigger = 1,
        trigger = {
            type = "direct",
            action_delivery = {
                type = "instant",
                source_effects = {
                    {
                        type = "script",
                        effect_id = "{quality = "..quality.name..", item = "..newResult.name.."}QUALITYPLANTS"
                    }
                }
                }
        }
    }

    newResult.name = quality.name.."-"..newResult.name
    newResult.icons = util.place_icon_on_item(newResult, quality)

    data:extend({newResult})
end

--- Updates every entry in a plants mining results to have quality attached to it.
--- @param plant data.PlantPrototype
--- @param quality data.QualityPrototype
--- @return table|nil|string
function util.updateMiningResults(plant, quality)
    local minable = plant.minable
    if minable == nil then return end

    if minable.result then
        util.createMiningResult(minable.result, quality)
        minable.result = quality.name.."-"..minable.result
    else
        for index, result in pairs(minable.results) do
            if result.type == "item" then
                util.createMiningResult(result.name, quality)
                minable.results[index].name = quality.name.."-"..result.name
            end
        end
    end

    return minable
end


--- Generate Fake Quality Plant Entity
--- @param plant data.PlantPrototype
--- @param quality data.QualityPrototype
--- @return data.PlantPrototype
function util.generate_plant(plant, quality)
    local newPlant = table.deepcopy(plant)
    local quality_color = util.rgb_to_hex(quality.color)
    local quality_multiplier = 1 + quality.level * 0.3

    -- Hidden
    newPlant.hidden = true
    newPlant.hidden_in_factoriopedia = true
    newPlant.fast_replaceable_group = newPlant.name
    newPlant.autoplace = {probability_expression = 0}

    -- Name and description
    if newPlant.name == "tree-plant" then    -- Hardcoding a fix for wood trees...
        newPlant.localised_name = {"", "[color=" .. quality_color .. "]", { "entity-name.tree"}, " (", {"quality-name." .. quality.name }, ")", "[/color]"}
    else
        newPlant.localised_name = {"", "[color=" .. quality_color .. "]", { "entity-name." .. newPlant.name }, " (", {"quality-name." .. quality.name }, ")", "[/color]"}
    end
    newPlant.localised_description = {"entity-description."..newPlant.name}
    newPlant.name = quality.name.."-"..newPlant.name

    -- Attributes
    newPlant.order = newPlant.order and (newPlant.order..quality.level) or nil
    if settings.startup["max_health"].value and newPlant.max_health then newPlant.max_health = util.mutiply_table(newPlant.max_health, quality_multiplier) end
    if settings.startup["growth_ticks"].value and newPlant.growth_ticks then newPlant.growth_ticks = newPlant.growth_ticks * quality_multiplier end
    if settings.startup["harvest_emissions"].value and newPlant.harvest_emissions then newPlant.harvest_emissions = util.mutiply_table(newPlant.harvest_emissions, quality_multiplier) end

    -- Mining Results
    newPlant.minable = util.updateMiningResults(newPlant, quality)
    return newPlant
end



return util