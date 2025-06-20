local _started

function Startup()
	if _started then
		return
	end
	_started = true

	MySQL.query('SELECT * FROM weed', {}, function(results)
		local count = 0
		for k, v in ipairs(results) do
			local plant = {
				isMale = v.is_male == 1,
				location = {x = v.x, y = v.y, z = v.z},
				growth = v.growth,
				output = v.output,
				material = v.material,
				planted = v.planted,
				water = v.water,
				fertilizer = v.fertilizer_type and {type = v.fertilizer_type, value = v.fertilizer_value, time = v.fertilizer_time} or nil,
				_id = v.id
			}
			if os.time() - plant.planted <= Config.Lifetime then
				_plants[plant._id] = {
					plant = plant,
					stage = getStageByPct(plant.growth),
				}
				count = count + 1
			end
		end
		Logger:Trace("Weed", string.format("Loaded ^2%s^7 Weed Plants", count), { console = true })
	end)

	Reputation:Create("weed", "Weed", {
		{ label = "Rank 1", value = 3000 },
		{ label = "Rank 2", value = 6000 },
		{ label = "Rank 3", value = 12000 },
		{ label = "Rank 4", value = 21000 },
		{ label = "Rank 5", value = 50000 },
	}, true)
end
