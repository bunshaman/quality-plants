local Functions = {}

---@param rgb { r: number, g: number, b: number }  -- table with red, green, blue values
---@return string   
function Functions.convert_to_hex(rgb)
    rgb = {rgb[1] or rgb.r, rgb[2] or rgb.g, rgb[3] or rgb.b}
    local hex = ""
    if (rgb[1] < 1) and (rgb[2] < 1) and (rgb[3] < 1) then  -- If all numbers are between 0 and 1, the game treats the values differently
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


function Functions.insert_quality_icons(item, quality)
    if quality.icons then
        for _, icon in pairs(quality.icons) do
		    table.insert(item.icons, { icon = icon.icon, tint = icon.tint, icon_size = icon.icon_size, scale = 0.25, shift = { -10, 10 }})
        end
    else
        table.insert(item.icons, { icon = quality.icon, tint = quality.tint, icon_size = quality.icon_size, scale = 0.25, shift = { -10, 10 }})
    end
end


function Functions.place_icon_on_item(item, target_quality)
	local quality = data.raw.quality[target_quality]

	if item.icons then
        Functions.insert_quality_icons(item, quality)
	else
		item.icons = {{ icon = item.icon, icon_size = item.icon_size }}
        Functions.insert_quality_icons(item, quality)
		item.icon = nil
	end
end


-- Scales every entry in a table, or a number only if it exists already in a normal prototype
---@param variable number|table
---@param quality_increase number
---@return number|table|nil
function Functions.scale_existing_target(variable, quality_increase)
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
function Functions.update_mining_results(minable, quality_name)
    if not minable then return nil end
    if minable.result then
        minable.result = quality_name.."-"..minable.result
    end
    if minable.results then
        for i, result in pairs(minable.results) do
            minable.results[i].name = quality_name.."-"..result.name
        end
    end
    return minable
end

---@param plant LuaEntity
---@param quality data.QualityPrototype
function Functions.draw_quality_sprite(plant, quality)
    local bb = plant.bounding_box
    local height = (bb.right_bottom.y - bb.left_top.y) / 2
	local width = (bb.right_bottom.x - bb.left_top.x) / 2
	local info = {
		sprite = "quality."..quality,
		target = {entity = plant, offset = {-width * 0.8, height * 0.8}},
		surface = plant.surface,
		x_scale = 0.5,
		y_scale = 0.5,
		render_layer = "entity-info-icon",
	}
	local render = rendering.draw_sprite(info)
end


---@param plant_prototype data.PlantPrototype
---@param quality_color { r: number, g: number, b: number }
function Functions.tintPlantPrototype(plant_prototype, quality_color)
    quality_color = {
        r = quality_color.r or quality_color[1],
        g = quality_color.g or quality_color[2],
        b = quality_color.b or quality_color[3]
    }
    
    if (quality_color.r > 1) and (quality_color.g > 1) and (quality_color.b > 1) then
        quality_color.r = quality_color.r / 255
        quality_color.g = quality_color.g / 255
        quality_color.b = quality_color.b / 255
    end

    for i, table in pairs(plant_prototype.colors) do    -- this table could be empty
        plant_prototype.colors[i] = {
            r = (quality_color.r),
            g = (quality_color.g),
            b = (quality_color.b),
        }
    end

    --plant_prototype.map_color = quality_color
end



return Functions