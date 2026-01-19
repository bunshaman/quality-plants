local func = require("functions")

---@param plant LuaEntity?
---@param quality string
---@param render? boolean
local function create_quality_sprite(plant, quality, render)
	storage.plants = storage.plants or {}
	storage.plants.render_to = storage.plants.render_to or {}
	render = render or true
	if plant == nil then log("Error drawing quality sprite. Plant was considered nil") return end
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
		players = storage.plants.render_to,
		visible = true
	}
	if next(info.players) == nil then info.visible = false end
	local render = rendering.draw_sprite(info)
	return render
end




------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Called when a plant is planted
--- @param event EventData|EventData.on_tower_planted_seed|EventData.on_built_entity|EventData.on_robot_built_entity|EventData.on_space_platform_built_entity
local function on_planted(event)
	local plant = event.entity or event.plant
	local seed = ""
	if event.consumed_items then
		local consumed = event.consumed_items.get_contents()
		seed = consumed[1]
	else
		seed = event.seed.name or event.stack.name
	end
	--local seed = event.seed.name or event.stack.name or (event.consumed_items.get_contents() and event.consumed_items.get_contents()[1])
	local quality = ""
	if event.name == 6 then
		quality = event.consumed_items.get_contents()[1].quality
	else
		quality = event.seed.quality.name or event.stack.quality.name
	end
	if plant == nil or plant.valid == false or plant.type ~= "plant" or quality == nil then log("Error planting a quality plant. Plant was invalid, not a plant, or had no quality.") return end
	if quality ~= "normal" or seed.name == "seed-crystal" then
		--game.print("Planted a "..quality.." "..plant.name)

		local newPlant = plant.surface.create_entity{
			name = quality.."-"..plant.name,
			position = plant.position,
			force = plant.force,
			fast_replace = true,
			snap_to_grid = false,
			spill=false
		}
		plant.destroy()
		if newPlant == nil then return end

		storage.plants = storage.plants or {}
		storage.plants.render_to = storage.plants.render_to or {}

		-- Draw quality sprites 
		--if settings.global["draw_quality_sprite"].value == "sometimes" then
			

		--storage.plants = storage.plants or {}
		--if func.tintable(quality, newPlant.name) then
		--	storage.plants[script.register_on_object_destroyed(newPlant)] = create_quality_sprite(newPlant, quality, false)
		--else
		--	storage.plants[script.register_on_object_destroyed(newPlant)] = create_quality_sprite(newPlant, quality, false)
		--end
		storage.plants[script.register_on_object_destroyed(newPlant)] = create_quality_sprite(newPlant, quality, false)
	end
end

--- comment
--- @param event EventData|EventData.on_runtime_mod_setting_changed
local function runtime_setting_changed(event)
	storage.plants = storage.plants or {}
	storage.plants.render_to = storage.plants.render_to or {}

	if event.setting == "draw_quality_sprite" then
		local value = settings.get_player_settings(event.player_index)["draw_quality_sprite"].value
		if value ~= "none" then
			storage.plants.render_to[event.player_index] = event.player_index
		else
			for i, j in pairs(storage.plants.render_to) do
				if j == event.player_index then storage.plants.render_to[i] = nil end
			end
		end

		func.update_rendering(event.player_index)
	end
end


local function on_object_destroyed(event)
    local registration_number = event.registration_number
    if storage.plants[registration_number] == nil then log("registration_number "..registration_number.." not found in storage.plants") return end

	rendering.get_object_by_id(storage.plants[registration_number]).destroy()
	storage.plants[registration_number] = nil
end


--Register replace item on spoil event
script.on_event("on_script_trigger_effect", function(event)
	if event.effect_id and string.find(event.effect_id, "QUALITYPLANTS", 1, true) then
		local target_quality, target_item = event.effect_id:match("{%s*quality%s*=%s*([^,]+),%s*item%s*=%s*([^}]+)}QUALITYPLANTS$")
		local entity = event.target_entity
		local item = {name=target_item, quality = target_quality}

		--Handle missing entity / item on ground by spawning the item on the ground
		if entity == nil then 
			if (game.players[1].position.x == event.target_position.x) and (game.players[1].position.y == event.target_position.y) then
				game.players[1].get_main_inventory().insert(item)
			else
				game.surfaces[event.surface_index].spill_item_stack{position = event.target_position, stack = item}
				return
			end
		else
			--Check how the item was removed from the machine
			if entity.type == "inserter" then
				--why doesn't .insert() work with inserters???????
				item.count = entity.held_stack.count + 1
				entity.held_stack.set_stack(item)
			elseif entity.type == "loader" then
				--gotta check both or else the items get eaten
				if entity.get_transport_line(1).can_insert_at_back() then
					entity.get_transport_line(1).insert_at_back(item)
				else
					entity.get_transport_line(2).insert_at_back(item)
				end
			elseif entity.type == "construction-robot" then
				entity.get_inventory(defines.inventory.robot_cargo).insert(item)
			elseif entity.type == "character" or entity.type == "container" then
				--so simple i love it
				entity.insert(item)
			elseif entity.type == "agricultural-tower" or entity.type == "assembling-machine" then
				entity.get_output_inventory().insert(item)
			end
		end
	end
end)


script.on_event(defines.events.on_tower_planted_seed, 				on_planted)
script.on_event(defines.events.on_built_entity,                 	on_planted, {{filter = "type", type = "plant"}})
script.on_event(defines.events.on_robot_built_entity,           	on_planted, {{filter = "type", type = "plant"}})
script.on_event(defines.events.on_space_platform_built_entity,  	on_planted, {{filter = "type", type = "plant"}})

script.on_event(defines.events.on_runtime_mod_setting_changed,		runtime_setting_changed)
script.on_event(defines.events.on_object_destroyed, 				on_object_destroyed)