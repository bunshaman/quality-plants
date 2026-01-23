local func = {}

local letters = {"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"}



--- Returns execute if a startup mod setting is set to true
--- @param mod_setting string
--- @param execute any
function func.if_mod_setting(mod_setting, execute) if settings.startup[mod_setting].value then return execute else return nil end end


--- @param variable number|table
--- @param quality_increase number
--- @return any
function func.mutiply_table(variable, quality_increase)
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
function func.rgb_to_hex(rgb)
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






--- Tints a plant prototypes leaves if the setting is enabled. Hardcoded for specific plants.
--- @param plant data.PlantPrototype
--- @param quality data.QualityPrototype
function func.tint_plant(plant, quality)
    if (quality.name.."-yumako-tree" == plant.name) or (quality.name.."-jellystem" == plant.name) or (quality.name.."-tree-plant" == plant.name) then
        local quality_color = {
            r = quality.color.r or quality.color[1],
            g = quality.color.g or quality.color[2],
            b = quality.color.b or quality.color[3]
        }
        
        if (quality_color.r > 1) and (quality_color.g > 1) and (quality_color.b > 1) then
            quality_color.r = quality_color.r / (255)
            quality_color.g = quality_color.g / (255)
            quality_color.b = quality_color.b / (255)
        end

        if plant.colors then
            for i, table in pairs(plant.colors) do    -- this table could be empty
                plant.colors[i] = {
                    r = (quality_color.r),
                    g = (quality_color.g),
                    b = (quality_color.b),
                }
            end
        end

        for i, variation in pairs(plant.variations) do
            if (quality.name.."-yumako-tree" == plant.name) then
                variation.leaves.filename = "__quality-plants__/plant/yumako-tree-harvest.png"
            elseif (quality.name.."-jellystem" == plant.name) then
                variation.leaves.filename = "__quality-plants__/plant/jellystem-harvest.png"
            elseif (quality.name.."-tree-plant" == plant.name) then
                variation.leaves.filename = "__quality-plants__/plant/tree-plant/tree-08-"..letters[i].."-leaves.png"
            end
        end
    end
end


--- Adds quality icons to an item prototype
--- @param itemPrototype data.ItemPrototype|data.CapsulePrototype|data.ToolPrototype
--- @param qualityPrototype data.QualityPrototype
function func.insert_quality_icons(itemPrototype, qualityPrototype)
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
function func.place_icon_on_item(itemPrototype, qualityPrototype)
    local icons = {}
	if itemPrototype.icons then
        icons = func.insert_quality_icons(itemPrototype, qualityPrototype)
	else
		itemPrototype.icons = {{ icon = itemPrototype.icon, icon_size = itemPrototype.icon_size }}
        icons = func.insert_quality_icons(itemPrototype, qualityPrototype)
		itemPrototype.icon = nil
	end
    return icons
end


--- Generates the item prototype
--- @param name any
--- @param quality any
function func.createMiningResult(name, quality)
    local newResult = table.deepcopy(data.raw["item"][name] or data.raw["capsule"][name] or data.raw["tool"][name])
    if newResult == nil then log("Error: mining result has a type that is not item, capsule, or tool. Please report to mod author with information about: Plants mined, mods used, and what the mining result is supposed to be.") return end


    -- Hidden
    newResult.hidden = true
    newResult.hidden_in_factoriopedia = true

    newResult.localised_name = {"", "[color=" .. func.rgb_to_hex(quality.color) .. "]", { "item-name." .. newResult.name }, " (", {"quality-name." .. quality.name }, ")", "[/color]"}
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
    newResult.icons = func.place_icon_on_item(newResult, quality)

    data:extend({newResult})
end

--- Updates every entry in a plants mining results to have quality attached to it.
--- @param plant data.PlantPrototype
--- @param quality data.QualityPrototype
--- @return table|nil|string
function func.updateMiningResults(plant, quality)
    local minable = plant.minable
    if minable == nil then return end

    if minable.result then
        func.createMiningResult(minable.result, quality)
        minable.result = quality.name.."-"..minable.result
    else
        for index, result in pairs(minable.results) do
            if result.type == "item" then
                func.createMiningResult(result.name, quality)
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
function func.generate_plant(plant, quality)
    local newPlant = table.deepcopy(plant)
    local quality_color = func.rgb_to_hex(quality.color)
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
        if newPlant.localised_name and newPlant.localised_name[1] then
            newPlant.localised_name = {"", "[color=" .. quality_color .. "]", { newPlant.localised_name[1] }, " (", {"quality-name." .. quality.name }, ")", "[/color]"}
        else
            newPlant.localised_name = {"", "[color=" .. quality_color .. "]", { "entity-name." .. newPlant.name }, " (", {"quality-name." .. quality.name }, ")", "[/color]"}
        end
    end
    newPlant.localised_description = newPlant.localised_description and newPlant.localised_description[1] or {"entity-description."..newPlant.name}
    newPlant.name = quality.name.."-"..newPlant.name

    -- Attributes
    newPlant.order = newPlant.order and (newPlant.order..quality.level) or nil
    if settings.startup["max_health"].value and newPlant.max_health then newPlant.max_health = func.mutiply_table(newPlant.max_health, settings.startup["max_health"].value) end
    if settings.startup["growth_ticks"].value and newPlant.growth_ticks then newPlant.growth_ticks = newPlant.growth_ticks * settings.startup["growth_ticks"].value end
    if settings.startup["harvest_emissions"].value and newPlant.harvest_emissions then newPlant.harvest_emissions = func.mutiply_table(newPlant.harvest_emissions, settings.startup["harvest_emissions"].value ^ 2) end
    if settings.startup["emmisions_per_second"].value and newPlant.harvest_emissions then newPlant.harvest_emissions = func.mutiply_table(newPlant.harvest_emissions, settings.startup["emmisions_per_second"].value) end

    -- Mining Results
    newPlant.minable = func.updateMiningResults(newPlant, quality)
    return newPlant
end


--- Will return true if a plant is able to be tinted.
--- @param plant_name string
--- @return boolean
function func.tintable(plant_name)
    if settings.startup["tint_plants"].value then
        for i, j in pairs(prototypes.quality) do
            if  (i.."-yumako-tree" == plant_name) or (i.."-jellystem" == plant_name) or (i.."-tree-plant" == plant_name) then 
                return true
            end
        end
    end
    return false
end


--- Updates the rendering of quality sprites for a player identified by their index.
--- @param plant_index integer
--- @param render_mode string
function func.update_rendering(plant_index, render_mode)
    storage.plants = storage.plants or {}
    storage.plants.always_render_to = storage.plants.always_render_to or {}
    storage.plants.sometimes_render_to = storage.plants.sometimes_render_to or {}

    local plant = storage.plants[plant_index]
    --plant = rendering.get_object_by_id(plant.id)

    if next(storage.plants.always_render_to) == nil then
        plant.visible = false
    elseif func.tintable(plant.target.entity.name) and (render_mode == "sometimes") then
        plant.players = storage.plants.sometimes_render_to
        plant.visible = true
    elseif render_mode == "always" then
        plant.players = storage.plants.always_render_to
        plant.visible = true
    end
    if not plant.players then 
        plant.visible = false 
    end
end


return func



--- Something is wrong with this block. Look into it tomorrow.
--- ---            storage.plants[i].players[player_index] = nil
--- ---            if next(storage.plants[i].players) == nil then storage.plants[i].visible = false end
--- 
                --- storage.plants[i].players = storage.plants.render_to
                --- storage.plants[i].visible = true
--- 
--- dog idk anymore okay?
--- plant is placed > no player index but need to render only to those who want to see it.