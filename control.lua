--Register replace item on spoil event
script.on_event("on_script_trigger_effect", function(event)
	if event.effect_id and string.find(event.effect_id, "QUALITYPLANTS", 1, true) then

		--local target_quality, target_item = event.effect_id:match("([^%-]+)%-(.+)") -- Matches "quality-item"		-- If a quality name has several hyphens, it goofs
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


function draw_quality_sprite(plant, quality)
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

-- Called when a tower plants a seed
function EVENT_on_tower_planted_seed(event)
	if type(event) == "table" and event.name == 207 then
		local plant = event.plant
		if event.seed.quality.name ~= "normal" then
			--game.print("Seed planted: "..event.seed.quality.name.."-"..event.seed.name.name)
			--local position = {["y"] = math.floor(plant.position.y or plant.position[1]), ["x"] = math.floor(plant.position.x or plant.position[2])}
			local new_plant = plant.surface.create_entity{
				name = event.seed.quality.name.."-"..plant.name,
				position = plant.position,
				force = plant.force,
				fast_replace = true,
				snap_to_grid = false,
				spill=false
			}
			draw_quality_sprite(new_plant, event.seed.quality.name)
		end
	end
end

-- When player builds plant
function EVENT_on_built_entity(event)
	if type(event) == "table" and event.name == 6 then
		if event.entity.type == "plant" and event.consumed_items[1].quality.name ~= "normal" then
			--game.print(event.consumed_items[1].name)

			local plant = event.entity
			local seed = event.consumed_items[1]
			--game.print("Seed planted: "..seed.quality.name.."-"..seed.name)
			local new_plant = plant.surface.create_entity{
				name = seed.quality.name.."-"..plant.name,
				position = plant.position,
				force = plant.force,
				fast_replace = true,
				snap_to_grid = false,
				spill=false
			}
			draw_quality_sprite(new_plant, seed.quality.name)
		end
	end
end

script.on_event(defines.events.on_tower_planted_seed, EVENT_on_tower_planted_seed)
script.on_event(defines.events.on_built_entity, EVENT_on_built_entity)