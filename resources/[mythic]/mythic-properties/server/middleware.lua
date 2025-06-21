function RegisterMiddleware()
	Middleware:Add("Characters:Spawning", function(source)
		TriggerLatentClientEvent("Properties:Client:Load", source, 800000, _properties)
	end)

	Middleware:Add("Characters:Logout", function(source)
		local char = Fetch:Source(source):GetData("Character")
		if char ~= nil then
			GlobalState[string.format("Char:Properties:%s", charId)] = nil
		end
		local property = GlobalState[string.format("%s:Property", source)]
		if property then
			TriggerClientEvent("Properties:Client:Cleanup", source, property)
			if _insideProperties[property] then
				_insideProperties[property][source] = nil
			end

			GlobalState[string.format("%s:Property", source)] = nil
		end

		if Player(source)?.state?.tpLocation then
			Player(source).state.tpLocation = nil
		end
	end)

	Middleware:Add("Characters:GetSpawnPoints", function(source, charId)
		local p = promise.new()

		MySQL.query('SELECT * FROM properties WHERE JSON_EXTRACT(`keys`, "$.' .. charId .. '") IS NOT NULL AND (foreclosed IS NULL OR foreclosed = 0) AND type NOT IN ("container", "warehouse")', {}, function(success, results)
			if not success or not results or #results == 0 then
				p:resolve({})
				return
			end
			local spawns = {}

			local keys = {}

			for k, v in pairs(results) do
				-- Decode JSON fields
				if v.location then
					v.location = json.decode(v.location)
				end
				if v.upgrades then
					v.upgrades = json.decode(v.upgrades)
				end
				if v.data then
					v.data = json.decode(v.data)
				end
				if v.keys then
					v.keys = json.decode(v.keys)
				end
				if v.owner then
					v.owner = json.decode(v.owner)
				end
				
				table.insert(keys, v.id)
				local property = _properties[v.id]
				if property ~= nil then
					local interior = property.upgrades?.interior
					local interiorData = PropertyInteriors[interior]

					local icon = "house"
					if property.type == "warehouse" then
						icon = "warehouse"
					elseif property.type == "office" then
						icon = "building"
					end

					if interiorData ~= nil then
						table.insert(spawns, {
							id = property.id,
							label = property.label,
							location = {
								x = interiorData.locations.front.coords.x,
								y = interiorData.locations.front.coords.y,
								z = interiorData.locations.front.coords.z,
								h = interiorData.locations.front.heading,
							},
							icon = icon,
							event = "Properties:SpawnInside",
						})
					end
				end
			end
			GlobalState[string.format("Char:Properties:%s", charId)] = keys
			p:resolve(spawns)
		end)

		return Citizen.Await(p)
	end, 3)
end