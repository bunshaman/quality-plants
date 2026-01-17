---@param plant LuaEntity?
---@param quality string
function draw_quality_sprite(plant, quality)
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
	}
	local render = rendering.draw_sprite(info)
	return render
end


--- ABANDONED unless there exists a way to get the mouse cursor position.
--- Draws a quality sprite upon the cursor when planting quality seeds manually
--- @param player LuaPlayer
--function draw_quality_on_mouse(player)
--	if not (player and player.valid == true) then return end
--	local cursor_stack = player.cursor_stack
--	if cursor_stack == nil or cursor_stack.valid == false then return end
--
--	if cursor_stack.valid_for_read then
--		local x = prototypes.item[cursor_stack.name].place_result.type
--		if not (prototypes.item[cursor_stack.name].place_result.type == "plant") then return end
--		rendering.draw_sprite{sprite = "quality."..cursor_stack.quality.name, target = player.hand_location, surface = player.physical_surface, x_scale = 0.5, y_scale = 0.5, time_to_live = 60}
--		game.print(player.cursor_stack)
--	else
--		-- delete rendering object.
--	end
--end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Called when a plant is planted
--- @param event EventData|EventData.on_tower_planted_seed|EventData.on_built_entity|EventData.on_robot_built_entity|EventData.on_space_platform_built_entity
function on_planted(event)
	local plant = event.entity or event.plant
	local seed = event.seed.name or event.stack.name or event.consumed_items.get_contents() and event.consumed_items.get_contents()[1]
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
		draw_quality_sprite(newPlant, quality)
	end
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