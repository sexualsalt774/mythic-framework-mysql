local _tempLastLocation = {}
local _lastSpawnLocations = {}

RegisterNetEvent('characters:Server:StoreUpdate')
AddEventHandler('characters:Server:StoreUpdate', function()
	local src = source
	local char = Fetch:Source(src):GetData('Character')

	if char ~= nil then
		local data = char:GetData()
	end
end)

function RegisterCallbacks()
	Callbacks:RegisterServerCallback('Characters:GetServerData', function(source, data, cb)
		while Fetch:Source(source) == nil do
			Wait(100)
		end

		local motd = GetConvar('motd', 'Welcome to Mythic RP')
		MySQL.query('SELECT * FROM changelogs ORDER BY date DESC LIMIT 1', {}, function(results)
			if not results then
				Logger:Error("Characters", "Failed to load changelog", { console = true })
				cb({ changelog = nil, motd = '' })
				return
			end
			if results and #results > 0 then
				cb({ changelog = results[1], motd = motd })
			else
				cb({ changelog = nil, motd = motd })
			end
		end)
	end)

	Callbacks:RegisterServerCallback('Characters:GetCharacters', function(source, data, cb)
		local player = Fetch:Source(source)
		MySQL.query('SELECT * FROM characters WHERE User = ? AND (Deleted IS NULL OR Deleted != 1)', { player:GetData('AccountID') }, function(results)
			if not results then
				cb({})
				return
			end

			local cData = {}
			local promises = {}

			for k, v in ipairs(results) do
				local p = promise.new()
				table.insert(promises, p)

				if not v.ID then
					Logger:Error("Characters", "Character ID is nil", { console = true })
					p:resolve(true)
				else
					MySQL.query('SELECT * FROM peds WHERE `Char` = ? LIMIT 1', {v.ID}, function(pedData)
						local previewData = pedData and pedData[1] and pedData[1].Ped or false
						if previewData and type(previewData) == 'string' then
							previewData = json.decode(previewData)
						end

						table.insert(cData, {
							ID = v.ID,
							First = v.First,
							Last = v.Last,
							Phone = v.Phone,
							DOB = v.DOB,
							Gender = v.Gender,
							LastPlayed = v.LastPlayed,
							Jobs = v.Jobs and json.decode(v.Jobs) or {},
							SID = v.SID,
							GangChain = v.GangChain,
							Preview = previewData,
						})
						p:resolve(true)
					end)
				end
			end
			Citizen.Await(promise.all(promises))
			player:SetData('Characters', cData)
			cb(cData)
		end)
	end)

	Callbacks:RegisterServerCallback('Characters:CreateCharacter', function(source, data, cb)
		local player = Fetch:Source(source)
		local pNumber = GeneratePhoneNumber()
		
		-- Citizen.Await(function() -- this is the same error for both anyway
			while IsNumberInUse(pNumber) do
				pNumber = GeneratePhoneNumber()
			end
		-- end)
		
		local doc = {
			User = player:GetData('AccountID'),
			First = data.first,
			Last = data.last,
			Phone = pNumber,
			Gender = tonumber(data.gender),
			Bio = data.bio,
			Origin = json.encode(data.origin),
			DOB = data.dob,
			LastPlayed = -1,
			-- Jobs = {},
			SID = Sequence:Get('Character'),
			Cash = 5000,
			New = true,
			Apartment = 1,
			Licenses = {
				Drivers = { Active = true, Points = 0, Suspended = false },
				Weapons = { Active = false, Suspended = false },
				Hunting = { Active = false, Suspended = false },
				Fishing = { Active = false, Suspended = false },
				Pilot = { Active = false, Suspended = false },
			},
		}

		local extra = Middleware:TriggerEventWithData('Characters:Creating', source, doc)
		for _, v in ipairs(extra) do
			for k2, v2 in pairs(v) do
				if k2 ~= 'ID' then
					if not v2 then
						doc[k2] = nil
					elseif v2 == false then
						doc[k2] = nil
					else
						doc[k2] = v2
					end
				end
			end
		end

		-- Build dynamic INSERT query
		local fields = {}
		local values = {}
		local placeholders = {}
		
		-- Process fields in order to maintain field-value alignment
		for field, value in pairs(doc) do
			table.insert(fields, field)
			table.insert(placeholders, "?")
			
			if type(value) == "table" then
				table.insert(values, json.encode(value))
			else
				table.insert(values, value)
			end
		end
		
		local query = string.format('INSERT INTO characters (%s) VALUES (%s)', table.concat(fields, ', '), table.concat(placeholders, ', '))
		
		MySQL.insert(query, values, function(result)
			if result and type(result) == "number" and result > 0 then
				doc.ID = result
				TriggerEvent('Characters:Server:CharacterCreated', doc)
				Middleware:TriggerEvent('Characters:Created', source, doc)
				cb(doc)
				Logger:Info(
					'Characters',
					string.format(
						'%s [%s] Created a New Character %s %s (%s)',
						player:GetData('Name'),
						player:GetData('AccountID'),
						doc.First,
						doc.Last,
						doc.SID
					),
					{ console = true, file = true, database = true }
				)
			else
				cb(false)
			end
		end)
	end)

	Callbacks:RegisterServerCallback('Characters:DeleteCharacter', function(source, data, cb)
		local player = Fetch:Source(source)
		MySQL.query('SELECT * FROM characters WHERE User = ? AND ID = ? LIMIT 1', { player:GetData('AccountID'), data }, function(results)
			if not results or not results[1] then
				cb(nil)
				return
			end
			local deletingChar = results[1]
			MySQL.update('UPDATE characters SET Deleted = 1 WHERE User = ? AND ID = ?', { player:GetData('AccountID'), data }, function(affectedRows)
				if affectedRows and affectedRows > 0 then
					TriggerEvent('Characters:Server:CharacterDeleted', data)
					cb(true)
					Logger:Warn(
						'Characters',
						string.format(
							'%s [%s] Deleted Character %s %s (%s)',
							player:GetData('Name'),
							player:GetData('AccountID'),
							deletingChar.First,
							deletingChar.Last,
							deletingChar.SID
						),
						{ console = true, file = true, database = true, discord = { embed = true } }
					)
				else
					cb(false)
				end
			end)
		end)
	end)

	Callbacks:RegisterServerCallback('Characters:GetSpawnPoints', function(source, data, cb)
		local player = Fetch:Source(source)
		MySQL.query('SELECT SID, New, Jailed, ICU, Apartment, Jobs FROM characters WHERE User = ? AND ID = ? LIMIT 1', { player:GetData('AccountID'), data }, function(results)
			if not results or not results[1] then
				cb(nil)
				return
			end
			local charData = results[1]
			if type(charData.Jailed) == 'string' then charData.Jailed = json.decode(charData.Jailed) end
			if type(charData.ICU) == 'string' then charData.ICU = json.decode(charData.ICU) end

			if charData.New then
				cb({
					{
						id = 1,
						label = 'Character Creation',
						location = Apartment:GetInteriorLocation(charData.Apartment or 1),
					},
				})
			elseif charData.Jailed and not charData.Jailed.Released then
				cb({ Config.PrisonSpawn })
			elseif charData.ICU and not charData.ICU.Released then
				cb({ Config.ICUSpawn })
			else
				local spawns = Middleware:TriggerEventWithData('Characters:GetSpawnPoints', source, data, charData)
				cb(spawns)
			end
		end)
	end)

	Callbacks:RegisterServerCallback('Characters:GetCharacterData', function(source, data, cb)
		local player = Fetch:Source(source)
		MySQL.query('SELECT * FROM characters WHERE User = ? AND ID = ? LIMIT 1', { player:GetData('AccountID'), data }, function(results)
			if not results or not results[1] then
				cb(nil)
				return
			end
			local cData = results[1]
			cData.Source = source
			cData.ID = results[1].ID
			cData._id = nil
			local store = DataStore:CreateStore(source, 'Character', cData)
			player:SetData('Character', store)
			GlobalState[string.format('SID:%s', source)] = cData.SID
			GlobalState[string.format('Account:%s', source)] = player:GetData('AccountID')
			Middleware:TriggerEvent('Characters:CharacterSelected', source)
			cb(cData)
		end)
	end)

	Callbacks:RegisterServerCallback('Characters:Logout', function(source, data, cb)
		local player = Fetch:Source(source)
		Middleware:TriggerEvent('Characters:Logout', source)
		player:SetData('Character', nil)
		GlobalState[string.format('SID:%s', source)] = nil
		GlobalState[string.format('Account:%s', source)] = nil
		cb('ok')
		TriggerClientEvent('Characters:Client:Logout', source)
		Routing:RoutePlayerToHiddenRoute(source)
	end)

	Callbacks:RegisterServerCallback('Characters:GlobalSpawn', function(source, data, cb)
		Routing:RoutePlayerToGlobalRoute(source)
		cb()
	end)
end

function HandleLastLocation(source)
	local player = Fetch:Source(source)
	if player ~= nil then
		local char = player:GetData('Character')
		if char ~= nil then
			local lastLocation = _tempLastLocation[source]
			if lastLocation and type(lastLocation) == 'vector3' then
				_lastSpawnLocations[char:GetData('ID')] = {
					coords = lastLocation,
					time = os.time(),
				}
			end
		end
	end
	_tempLastLocation[source] = nil
end

function RegisterMiddleware()
	Middleware:Add('Characters:Spawning', function(source)
		TriggerClientEvent('Characters:Client:Spawned', source)
	end, 100000)
	Middleware:Add('Characters:ForceStore', function(source)
		local player = Fetch:Source(source)
		if player ~= nil then
			local char = player:GetData('Character')
			if char ~= nil then
				StoreData(source)
			end
		end
	end, 100000)
	Middleware:Add('Characters:Logout', function(source)
		local player = Fetch:Source(source)
		if player ~= nil then
			local char = player:GetData('Character')
			if char ~= nil then
				StoreData(source)
			end
		end
	end, 10000)
	Middleware:Add('Characters:GetSpawnPoints', function(source, id)
		if id then
			local hasLastLocation = _lastSpawnLocations[id]
			if hasLastLocation and hasLastLocation.time and (os.time() - hasLastLocation.time) <= (60 * 5) then
				return {
					{
						id = 'LastLocation',
						label = 'Last Location',
						location = {
							x = hasLastLocation.coords.x,
							y = hasLastLocation.coords.y,
							z = hasLastLocation.coords.z,
							h = 0.0,
						},
						icon = 'location-dot',
						event = 'Characters:GlobalSpawn',
					},
				}
			end
		end
		return {}
	end, 1)
	Middleware:Add('Characters:GetSpawnPoints', function(source)
		local spawns = {}
		for _, v in ipairs(Spawns) do
			v.event = 'Characters:GlobalSpawn'
			table.insert(spawns, v)
		end
		return spawns
	end, 5)
	Middleware:Add('playerDropped', function(source, message)
		local player = Fetch:Source(source)
		if player ~= nil then
			local char = player:GetData('Character')
			if char ~= nil then
				StoreData(source)
			end
		end
	end, 10000)
	Middleware:Add('Characters:Logout', HandleLastLocation, 6)
	Middleware:Add('playerDropped', HandleLastLocation, 6)
end


function IsNumberInUse(number)

    -- local var = nil
    -- MySQL.query('SELECT * FROM characters WHERE phone = ? LIMIT 1', {number}, function(results)
    --     if not results then
    --         var = true
    --         return
    --     end
    --     var = #results > 0
    -- end)

    -- while var == nil do
    --     Wait(10)
    -- end

	local result = MySQL.query.await('SELECT 1 FROM characters WHERE phone = ? LIMIT 1', { number })
	return result and #result > 0
end

function GeneratePhoneNumber()
	local phone = ''
	for i = 1, 10, 1 do
		local d = math.random(0, 9)
		phone = phone .. d
		if i == 3 or i == 6 then
			phone = phone .. '-'
		end
	end
	return phone
end

RegisterNetEvent('Characters:Server:LastLocation',function(coords) -- Probably Going to make the server explode but ¯\_(ツ)_/¯
	local src = source
	_tempLastLocation[src] = coords
end)