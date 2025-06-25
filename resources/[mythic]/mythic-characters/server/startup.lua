Spawns = {}

local _ran = false

function Startup()
	if _ran then
		return
	end

	MySQL.query('SELECT * FROM locations WHERE Type = ?', {'spawn'}, function(results)
		if not results then
			return
		end

		Logger:Trace('Characters', 'Loaded ^2' .. (results and #results or 0) .. '^7 Spawn Locations', { console = true })

		Spawns = { table.unpack(Config.DefaultSpawns) }
		for _, v in ipairs(results) do
			v.Coords = json.decode(v.Coords)
			print(json.encode(v.Coords, {indent = true}))
			local spawn = {
				id = v.id,
				label = v.Name,
				location = { x = v.Coords.x, y = v.Coords.y, z = v.Coords.z, h = v.Heading },
			}
			table.insert(Spawns, spawn)
		end
	end)

	_ran = true
end

AddEventHandler('Locations:Server:Added', function(type, location)
	if type == 'spawn' then
		table.insert(Spawns, {
			label = location.Name,
			location = { x = location.Coords.x, y = location.Coords.y, z = location.Coords.z, h = location.Coords.h },
		})
		Logger:Info('Characters', 'New Spawn Point Created: ^5' .. location.Name, { console = true })
	end
end)
