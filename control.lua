local func = require("functions")
require("mod-compat.control")

---@param plant LuaEntity?
---@param quality string
local function create_quality_sprite(plant, quality)
	storage.plants = storage.plants or {}
	storage.plants.always_render_to = storage.plants.always_render_to or {}
	storage.plants.sometimes_render_to = storage.plants.sometimes_render_to or {}

	if plant == nil then log("Error drawing quality sprite. Plant was considered nil") return end
    local bb = plant.bounding_box
    local height = (bb.right_bottom.y - bb.left_top.y) / 2
	local width = (bb.right_bottom.x - bb.left_top.x) / 2

	local render_mode = storage.plants.always_render_to
	if func.tintable(plant.name) then 
		render_mode = storage.plants.sometimes_render_to
	end
	local info = {
		sprite = "quality."..quality,
		target = {entity = plant, offset = {-width * 0.8, height * 0.8}},
		surface = plant.surface,
		x_scale = 0.5,
		y_scale = 0.5,
		render_layer = "entity-info-icon",
		players = render_mode,
		visible = true,
		only_in_alt_mode = true
	}
	if next(info.players) == nil then info.visible = false end
	local render = rendering.draw_sprite(info)
	return render
end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function ensure_storage()
    storage.plants = storage.plants or {}
    storage.plants.always_render_to = storage.plants.always_render_to or {}
    storage.plants.sometimes_render_to = storage.plants.sometimes_render_to or {}
	storage.tintable = {}
	
	for plant_name, _ in pairs(func.base_tintable) do
		for j, quality_prototype in pairs(prototypes.quality) do
			if not (quality_prototype.name == "quality-unknown") then storage.tintable[quality_prototype.name.."-"..plant_name] = plant_name end
		end
	end
end


local function pipette_mimic(event)
	if not event.selected_prototype then return end
	if not (event.selected_prototype.derived_type == "plant") then return end

	local selected_plant = prototypes.entity[event.selected_prototype.name]
	local normal_plant = prototypes.entity[selected_plant.fast_replaceable_group]
	local quality = ""
	if selected_plant.name ~= selected_plant.fast_replaceable_group then
		quality = selected_plant.name:sub(1, #selected_plant.name - #selected_plant.fast_replaceable_group - 1)
	else
		return
	end
	
	local player = game.players[event.player_index]
	if player.cursor_stack == nil then return end
	local seed = normal_plant.items_to_place_this[1]
	local pick_sound = "item-pick/"..seed.name
	local drop_sound = "item-move/"..seed.name
	

	-- gotta find if player has the correct seed in the inventory and then grab the index
	local cursor = player.cursor_stack
	local item_stack, index = player.get_main_inventory().find_item_stack({name = seed.name, quality = quality, count = seed.count})
	if item_stack then
		-- put item into cursor
		player.cursor_stack.swap_stack(item_stack)
		if helpers.is_valid_sound_path(pick_sound) then player.play_sound({path = pick_sound}) end
	elseif player.cursor_ghost == nil then
		-- put ghost item into cursor
		player.cursor_stack.swap_stack(item_stack)
		player.cursor_ghost= {name = seed.name, quality = quality}
		if helpers.is_valid_sound_path("utility/smart_pipette") then player.play_sound({path = "utility/smart_pipette"}) end
	end



	
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
		storage.plants.always_render_to = storage.plants.always_render_to or {}
		storage.plants.sometimes_render_to = storage.plants.sometimes_render_to or {}

		-- Draw quality sprites 
		storage.plants[script.register_on_object_destroyed(newPlant)] = create_quality_sprite(newPlant, quality)
	end
end

--- comment
--- @param event EventData|EventData.on_runtime_mod_setting_changed
local function runtime_setting_changed(event)
    storage.plants = storage.plants or {}
    storage.plants.always_render_to = storage.plants.always_render_to or {}
    storage.plants.sometimes_render_to = storage.plants.sometimes_render_to or {}
    storage.plants.render_to = nil

    --storage.plants = {}
    --storage.plants.render_to =  {}
    --storage.plants.always_render_to =  {}
    --storage.plants.sometimes_render_to =  {}
	if event.setting == "draw_quality_sprite" then
		func.update_all_plants(event.player_index)
	end
end


local function on_object_destroyed(event)
    local registration_number = event.registration_number
    if storage.plants[registration_number] == nil then log("registration_number "..registration_number.." not found in storage.plants") return end

	storage.plants[registration_number].destroy()
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


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


script.on_init(														ensure_storage)
script.on_configuration_changed(									ensure_storage)

script.on_event(defines.events.on_tower_planted_seed, 				on_planted)
script.on_event(defines.events.on_built_entity,                 	on_planted, {{filter = "type", type = "plant"}})
script.on_event(defines.events.on_robot_built_entity,           	on_planted, {{filter = "type", type = "plant"}})
script.on_event(defines.events.on_space_platform_built_entity,  	on_planted, {{filter = "type", type = "plant"}})

script.on_event(defines.events.on_runtime_mod_setting_changed,		runtime_setting_changed)
script.on_event(defines.events.on_object_destroyed, 				on_object_destroyed)

script.on_event("plants-pipette-used",									pipette_mimic)