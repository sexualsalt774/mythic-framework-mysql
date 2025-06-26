AddEventHandler("Proxy:Shared:RegisterReady", function()
	exports["mythic-base"]:RegisterComponent("Locations", LOCATIONS)
end)

AddEventHandler("Locations:Shared:DependencyUpdate", RetrieveComponents)
function RetrieveComponents()
	Chat = exports["mythic-base"]:FetchComponent("Chat")
	Callbacks = exports["mythic-base"]:FetchComponent("Callbacks")
	Locations = exports["mythic-base"]:FetchComponent("Locations")
	Logger = exports["mythic-base"]:FetchComponent("Logger")
	Default = exports["mythic-base"]:FetchComponent("Default")
end

AddEventHandler("Core:Shared:Ready", function()
	exports["mythic-base"]:RequestDependencies("Locations", {
		"Database",
		"Chat",
		"Callbacks",
		"Locations",
		"Logger",
		"Default",
	}, function(error)
		if #error > 0 then
			return
		end -- Do something to handle if not all dependencies loaded
		RetrieveComponents()
		RegisterCallbacks()
		RegisterChatCommands()
		Startup()
		TriggerEvent("Locations:Server:Startup")
	end)
end)

function RegisterCallbacks()
	Callbacks:RegisterServerCallback("Locations:GetAll", function(source, data, cb)
		Locations:GetAll(data.type, cb)
	end)
end

function RegisterChatCommands()
	Chat:RegisterAdminCommand("location", function(source, args, rawCommand)
		local playerPed = GetPlayerPed(source)
		local coords = GetEntityCoords(playerPed)
		local heading = GetEntityHeading(playerPed)
		if args[1]:lower() == "add" and args[2] then
			Locations:Add(coords, heading, args[2], args[3])
		end
	end, {
		help = "Add Location",
		params = {
			{
				name = "Action",
				help = "Available: add",
			},
			{
				name = "Type",
				help = "Type of Location",
			},
			{
				name = "Name",
				help = "Name of Location",
			},
		},
	}, 3)
end

LOCATIONS = {
	Add = function(self, coords, heading, type, name, cb)
		local doc = {
			Coords = {
				x = coords.x,
				y = coords.y,
				z = coords.z,
			},
			Heading = heading,
			Type = type,
			Name = name,
		}
		MySQL.insert('INSERT INTO locations (Coords, Heading, Type, Name) VALUES (?, ?, ?, ?)', {
			json.encode(doc.Coords), heading, type, name
		}, function(insertId)
			if insertId then
			TriggerEvent("Locations:Server:Added", type, doc)
			if cb ~= nil then
					cb(true)
				end
			else
				if cb ~= nil then
					cb(false)
				end
			end
		end)
	end,
	GetAll = function(self, type, cb)
		MySQL.query('SELECT * FROM locations WHERE Type = ?', {type}, function(results)
			if results then
			for k, location in ipairs(results) do
					-- Parse Coords from JSON if it's stored as JSON
					if type(location.Coords) == "string" then
						local coords = json.decode(location.Coords)
						results[k].Coords = vector3(coords.x, coords.y, coords.z)
					else
				results[k].Coords = vector3(location.Coords.x, location.Coords.y, location.Coords.z)
					end
			end
			cb(results)
			else
				cb({})
			end
		end)
	end,
}
