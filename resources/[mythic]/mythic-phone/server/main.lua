-- Utility functions for building MySQL WHERE clauses from MongoDB-style query objects
function buildWhereClause(query)
	if not query or type(query) ~= "table" then
		return "1=1"
	end
	
	local conditions = {}
	
	for field, value in pairs(query) do
		if type(value) == "table" then
			-- Handle MongoDB-style operators
			for operator, operatorValue in pairs(value) do
				local fieldName = field
				-- Handle JSON path queries (e.g., "Alias.twitter.name")
				if string.find(field, "%.") then
					local baseField = string.match(field, "([^.]+)")
					local jsonPath = string.sub(field, string.find(field, "%.") + 1)
					fieldName = "JSON_EXTRACT(" .. baseField .. ", '$." .. jsonPath .. "')"
				end
				
				if operator == "$ne" then
					table.insert(conditions, fieldName .. " != ?")
				elseif operator == "$eq" then
					table.insert(conditions, fieldName .. " = ?")
				elseif operator == "$gt" then
					table.insert(conditions, fieldName .. " > ?")
				elseif operator == "$gte" then
					table.insert(conditions, fieldName .. " >= ?")
				elseif operator == "$lt" then
					table.insert(conditions, fieldName .. " < ?")
				elseif operator == "$lte" then
					table.insert(conditions, fieldName .. " <= ?")
				elseif operator == "$in" then
					if type(operatorValue) == "table" then
						local placeholders = {}
						for i = 1, #operatorValue do
							table.insert(placeholders, "?")
						end
						table.insert(conditions, fieldName .. " IN (" .. table.concat(placeholders, ",") .. ")")
					end
				elseif operator == "$nin" then
					if type(operatorValue) == "table" then
						local placeholders = {}
						for i = 1, #operatorValue do
							table.insert(placeholders, "?")
						end
						table.insert(conditions, fieldName .. " NOT IN (" .. table.concat(placeholders, ",") .. ")")
					end
				elseif operator == "$like" then
					table.insert(conditions, fieldName .. " LIKE ?")
				end
			end
		else
			-- Simple equality
			local fieldName = field
			-- Handle JSON path queries (e.g., "Alias.twitter.name")
			if string.find(field, "%.") then
				local baseField = string.match(field, "([^.]+)")
				local jsonPath = string.sub(field, string.find(field, "%.") + 1)
				fieldName = "JSON_EXTRACT(" .. baseField .. ", '$." .. jsonPath .. "')"
			end
			table.insert(conditions, fieldName .. " = ?")
		end
	end
	
	return table.concat(conditions, " AND ")
end

function buildWhereParams(query)
	if not query or type(query) ~= "table" then
		return {}
	end
	
	local params = {}
	
	for field, value in pairs(query) do
		if type(value) == "table" then
			-- Handle MongoDB-style operators
			for operator, operatorValue in pairs(value) do
				if operator == "$ne" or operator == "$eq" or operator == "$gt" or operator == "$gte" or operator == "$lt" or operator == "$lte" or operator == "$like" then
					table.insert(params, operatorValue)
				elseif operator == "$in" or operator == "$nin" then
					if type(operatorValue) == "table" then
						for i = 1, #operatorValue do
							table.insert(params, operatorValue[i])
						end
					end
				end
			end
		else
			-- Simple equality
			table.insert(params, value)
		end
	end
	
	return params
end

function defaultApps()
	local defApps = {}
	local dock = { "contacts", "phone", "messages" }
	for k, v in pairs(PHONE_APPS) do
		if not v.canUninstall then
			table.insert(defApps, v.name)
		end
	end
	return {
		installed = defApps,
		home = defApps,
		dock = dock,
	}
end

function hasValue(tbl, value)
	for k, v in ipairs(tbl) do
		if v == value or (type(v) == "table" and hasValue(v, value)) then
			return true
		end
	end
	return false
end

function table.copy(t)
	local u = {}
	for k, v in pairs(t) do
		u[k] = v
	end
	return setmetatable(u, getmetatable(t))
end

local defaultSettings = {
	wallpaper = "wallpaper",
	ringtone = "ringtone1.ogg",
	texttone = "text1.ogg",
	colors = {
		accent = "#1a7cc1",
	},
	zoom = 75,
	volume = 100,
	notifications = true,
	appNotifications = {},
}

local defaultPermissions = {
	redline = {
		create = false,
	},
}

AddEventHandler("onResourceStart", function(resource)
	if resource == GetCurrentResourceName() then
		TriggerClientEvent("Phone:Client:SetApps", -1, PHONE_APPS)
	end
end)

AddEventHandler("Phone:Shared:DependencyUpdate", RetrieveComponents)

function RetrieveComponents()
	Fetch = exports["mythic-base"]:FetchComponent("Fetch")
	Callbacks = exports["mythic-base"]:FetchComponent("Callbacks")
	Logger = exports["mythic-base"]:FetchComponent("Logger")
	Utils = exports["mythic-base"]:FetchComponent("Utils")
	Chat = exports["mythic-base"]:FetchComponent("Chat")
	Phone = exports["mythic-base"]:FetchComponent("Phone")
	Middleware = exports["mythic-base"]:FetchComponent("Middleware")
	Execute = exports["mythic-base"]:FetchComponent("Execute")
	Config = exports["mythic-base"]:FetchComponent("Config")
	MDT = exports["mythic-base"]:FetchComponent("MDT")
	Jobs = exports["mythic-base"]:FetchComponent("Jobs")
	Labor = exports["mythic-base"]:FetchComponent("Labor")
	Crypto = exports["mythic-base"]:FetchComponent("Crypto")
	VOIP = exports["mythic-base"]:FetchComponent("VOIP")
	Generator = exports["mythic-base"]:FetchComponent("Generator")
	Properties = exports["mythic-base"]:FetchComponent("Properties")
	Vehicles = exports["mythic-base"]:FetchComponent("Vehicles")
	Inventory = exports["mythic-base"]:FetchComponent("Inventory")
	Loot = exports["mythic-base"]:FetchComponent("Loot")
	Loans = exports["mythic-base"]:FetchComponent("Loans")
	Billing = exports["mythic-base"]:FetchComponent("Billing")
	Banking = exports["mythic-base"]:FetchComponent("Banking")
	Reputation = exports["mythic-base"]:FetchComponent("Reputation")
	Robbery = exports["mythic-base"]:FetchComponent("Robbery")
	Wallet = exports["mythic-base"]:FetchComponent("Wallet")
	Sequence = exports["mythic-base"]:FetchComponent("Sequence")
	Vendor = exports["mythic-base"]:FetchComponent("Vendor")
	RegisterChatCommands()
end

AddEventHandler("Core:Shared:Ready", function()
	exports["mythic-base"]:RequestDependencies("Phone", {
		"Fetch",
		"Database",
		"Callbacks",
		"Logger",
		"Utils",
		"Chat",
		"Phone",
		"Middleware",
		"Execute",
		"Config",
		"MDT",
		"Jobs",
		"Labor",
		"Crypto",
		"VOIP",
		"Generator",
		"Properties",
		"Vehicles",
		"Inventory",
		"Loot",
		"Loans",
		"Billing",
		"Banking",
		"Reputation",
		"Robbery",
		"Wallet",
		"Sequence",
		"Vendor",
	}, function(error)
		if #error > 0 then
			return
		end
		-- Do something to handle if not all dependencies loaded
		RetrieveComponents()
		Startup()
		TriggerEvent("Phone:Server:RegisterMiddleware")
		TriggerEvent("Phone:Server:RegisterCallbacks")

		Reputation:Create("Racing", "LS Underground", {
			{ label = "Rank 1",  value = 1000 },
			{ label = "Rank 2",  value = 2500 },
			{ label = "Rank 3",  value = 5000 },
			{ label = "Rank 4",  value = 10000 },
			{ label = "Rank 5",  value = 25000 },
			{ label = "Rank 6",  value = 50000 },
			{ label = "Rank 7",  value = 100000 },
			{ label = "Rank 8",  value = 250000 },
			{ label = "Rank 9",  value = 500000 },
			{ label = "Rank 10", value = 1000000 },
		}, true)
	end)
end)

AddEventHandler("Phone:Server:RegisterMiddleware", function()
	Middleware:Add("Characters:Spawning", function(source)
		Phone:UpdateJobData(source)

		local char = Fetch:Source(source):GetData("Character")
		local myPerms = char:GetData("PhonePermissions")
		local mySettings = char:GetData("PhoneSettings")
		local myApps = char:GetData("Apps")
		local modified = false

		if type(myApps) ~= "table" then
			myApps = defaultApps()
			char:SetData("Apps", myApps)
			modified = true
		else
			if type(myApps.installed) ~= "table" then
				myApps.installed = {}
				for k, v in pairs(PHONE_APPS) do
					if not v.canUninstall then
						table.insert(myApps.installed, v.name)
					end
				end
				modified = true
			end
			if type(myApps.home) ~= "table" then
				myApps.home = table.copy(myApps.installed)
				modified = true
			end
			if type(myApps.dock) ~= "table" then
				myApps.dock = { "contacts", "phone", "messages" }
				modified = true
			end
		end

		if type(mySettings) ~= "table" then
			mySettings = table.copy(defaultSettings)
			char:SetData("PhoneSettings", mySettings)
			modified = true
		else
			for k, v in pairs(defaultSettings) do
				if mySettings[k] == nil then
					mySettings[k] = v
					modified = true
				end
			end
		end

		if modified then
			char:SetData("PhoneSettings", mySettings)
		end

		if type(myPerms) ~= "table" then
			myPerms = {}
			for app, perms in pairs(defaultPermissions) do
				myPerms[app] = {}
				for perm, state in pairs(perms) do
					myPerms[app][perm] = state
				end
			end
			modified = true
		else
			for app, perms in pairs(defaultPermissions) do
				if type(myPerms[app]) ~= "table" then
					myPerms[app] = {}
					modified = true
				end
				for perm, state in pairs(perms) do
					if myPerms[app][perm] == nil then
						myPerms[app][perm] = state
						modified = true
					end
				end
			end
		end

		if modified then
			char:SetData("PhonePermissions", myPerms)
		end

		TriggerClientEvent("Phone:Client:SetApps", source, PHONE_APPS)
		TriggerClientEvent("Phone:Client:SetUserApps", source, myApps)
	end, 1)
	Middleware:Add("Phone:UIReset", function(source)
		Phone:UpdateJobData(source)
		TriggerClientEvent("Phone:Client:SetApps", source, PHONE_APPS)
	end)
	Middleware:Add("Characters:Creating", function(source, cData)
		local t = Middleware:TriggerEventWithData("Phone:CharacterCreated", source, cData)
		local aliases = {}

		for k, v in ipairs(t) do
			aliases[v.app] = v.alias
		end

		return {
			{
				Alias = aliases,
				Apps = defaultApps(),
				PhoneSettings = defaultSettings,
				PhonePermissions = defaultPermissions,
			},
		}
	end)
end)

RegisterNetEvent("Phone:Server:UIReset", function()
	Middleware:TriggerEvent("Phone:UIReset", source)
end)

AddEventHandler("Phone:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("Phone:Apps:Home", function(src, data, cb)
		local char = Fetch:Source(src):GetData("Character")
		local apps = char:GetData("Apps")
		if data.action == "add" then
			if #apps.home < 20 then
				table.insert(apps.home, data.app)
			end
		else
			local newHome = {}
			for k, v in ipairs(apps.home) do
				if v ~= data.app then
					table.insert(newHome, v)
				end
			end

			apps.home = newHome
		end
		char:SetData("Apps", apps)
	end)

	Callbacks:RegisterServerCallback("Phone:Apps:Dock", function(src, data, cb)
		local char = Fetch:Source(src):GetData("Character")
		local apps = char:GetData("Apps")
		if data.action == "add" then
			if #apps.dock < 4 then
				table.insert(apps.dock, data.app)
			end
		else
			local newDock = {}
			for k, v in ipairs(apps.dock) do
				if v ~= data.app then
					table.insert(newDock, v)
				end
			end

			apps.dock = newDock
		end
		char:SetData("Apps", apps)
	end)

	Callbacks:RegisterServerCallback("Phone:Apps:Reorder", function(src, data, cb)
		local char = Fetch:Source(src):GetData("Character")
		local apps = char:GetData("Apps")
		apps[data.type] = data.apps
		char:SetData("Apps", apps)
	end)

	Callbacks:RegisterServerCallback("Phone:UpdateAlias", function(src, data, cb)
		local char = Fetch:Source(src):GetData("Character")
		local alias = char:GetData("Alias") or {}
		if data.unique then
			local query = {
				["Alias." .. data.app] = data.alias,
				Phone = {
					["$ne"] = char:GetData("Phone"),
				},
				Deleted = {
					["$ne"] = true,
				},
			}

			if data.alias and data.alias.name ~= nil then
				query = {
					["Alias." .. data.app .. ".name"] = data.alias.name,
					Phone = {
						["$ne"] = char:GetData("Phone"),
					},
					Deleted = {
						["$ne"] = true,
					},
				}
			end
			MySQL.query('SELECT * FROM characters WHERE ' .. buildWhereClause(query), buildWhereParams(query),
				function(results)
					if #results > 0 then
						cb(false)
					else
						local upd = {
							["Alias." .. data.app] = data.alias,
						}
						if data.alias and data.alias.name ~= nil then
							upd = {
								["Alias." .. data.app .. ".name"] = data.alias.name,
							}
						end
						MySQL.update('UPDATE characters SET Alias = ? WHERE ID = ?',
							{ json.encode(upd), char:GetData('ID') }, function(affectedRows)
								cb(affectedRows > 0)
							end)
					end
				end)
		else
			alias[data.app] = data.alias
			char:SetData("Alias", alias)
			cb(true)
			TriggerEvent("Phone:Server:AliasUpdated", src)
		end
	end)

	Callbacks:RegisterServerCallback("Phone:ShareMyContact", function(src, data, cb)
		local char = Fetch:Source(src):GetData("Character")
		local myPed = GetPlayerPed(src)
		local myCoords = GetEntityCoords(myPed)
		local myBucket = GetPlayerRoutingBucket(src)
		for k, v in pairs(Fetch:All()) do
			local tsrc = v:GetData("Source")
			local tped = GetPlayerPed(tsrc)
			local coords = GetEntityCoords(tped)
			if tsrc ~= src and #(myCoords - coords) <= 5.0 and GetPlayerRoutingBucket(tsrc) == myBucket then
				TriggerClientEvent("Phone:Client:ReceiveShare", tsrc, {
					type = "contacts",
					data = {
						name = char:GetData("First") .. " " .. char:GetData("Last"),
						number = char:GetData("Phone"),
					},
				}, os.time() * 1000)
			end
		end
	end)

	Callbacks:RegisterServerCallback("Phone:Permissions", function(src, data, cb)
		local char = Fetch:Source(src):GetData("Character")

		if char ~= nil then
			local perms = char:GetData("PhonePermissions")

			for k, v in pairs(data) do
				for k2, v2 in ipairs(v) do
					if not perms[k][v2] then
						cb(false)
						return
					end
				end
			end
			cb(true)
		else
			cb(false)
		end
	end)
end)
