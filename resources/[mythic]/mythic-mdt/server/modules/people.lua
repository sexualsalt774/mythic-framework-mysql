local requiredCharacterData = {
	SID = 1,
	User = 1,
	First = 1,
	Last = 1,
	Gender = 1,
	Origin = 1,
	Jobs = 1,
	DOB = 1,
	Callsign = 1,
	Phone = 1,
	Licenses = 1,
	Qualifications = 1,
	Flags = 1,
	Mugshot = 1,
	MDTSystemAdmin = 1,
	MDTHistory = 1,
	Attorney = 1,
	LastClockOn = 1,
	TimeClockedOn = 1,
}

_MDT.People = {
	Search = {
		People = function(self, term)
			local p = promise.new()
			MySQL.query('SELECT * FROM characters WHERE (Deleted = false OR Deleted IS NULL) AND (First LIKE ? OR Last LIKE ? OR SID LIKE ?) LIMIT 12', { '%'..term..'%', '%'..term..'%', '%'..term..'%' }, function(results)
				p:resolve(results or false)
			end)
			GlobalState["MDT:Metric:Search"] = GlobalState["MDT:Metric:Search"] + 1
			return Citizen.Await(p)
		end,
		Government = function(self)
			local p = promise.new()
			MySQL.query('SELECT * FROM characters WHERE Jobs LIKE ? AND Jobs IS NOT NULL', { '%"Id":%'.._governmentJobs[1]..'%' }, function(results)
				p:resolve(results or false)
			end)
			return Citizen.Await(p)
		end,
		NotGovernment = function(self)
			local p = promise.new()
			MySQL.query('SELECT * FROM characters WHERE Jobs NOT LIKE ? AND Jobs IS NOT NULL', { '%"Id":%'.._governmentJobs[1]..'%' }, function(results)
				p:resolve(results or false)
			end)
			return Citizen.Await(p)
		end,
		Job = function(self, job, term)
			local p = promise.new()
			local where = 'JSON_CONTAINS(Jobs, ?, "$[*].Id")'
			local params = { job }
			if term then
				where = where .. ' AND (First LIKE ? OR Last LIKE ? OR SID LIKE ?)'
				table.insert(params, '%'..term..'%')
				table.insert(params, '%'..term..'%')
				table.insert(params, '%'..term..'%')
			end
			MySQL.query('SELECT * FROM characters WHERE ' .. where, params, function(results)
				p:resolve(results or false)
			end)
			return Citizen.Await(p)
		end,
		NotJob = function(self, job)
			local p = promise.new()
			MySQL.query('SELECT * FROM characters WHERE NOT JSON_CONTAINS(Jobs, ?, "$[*].Id")', { job }, function(results)
				p:resolve(results or false)
			end)
			return Citizen.Await(p)
		end,
	},
	View = function(self, id, requireAllData)
		local SID = tonumber(id)
		local p = promise.new()
		MySQL.query('SELECT * FROM characters WHERE SID = ? LIMIT 1', { SID }, function(character)
			if not character or #character == 0 then
				p:resolve(false)
				return
			end
			if requireAllData then
				MySQL.query('SELECT * FROM character_convictions WHERE SID = ? LIMIT 1', { SID }, function(convictions)
					MySQL.query('SELECT * FROM vehicles WHERE JSON_EXTRACT(Owner, "$.Type") = 0 AND JSON_EXTRACT(Owner, "$.Id") = ?', { SID }, function(vehicles)
						local char = character[1]
						local ownedBusinesses = {}
						if char.Jobs then
							if type(char.Jobs) == 'string' then char.Jobs = json.decode(char.Jobs) end
							for k, v in ipairs(char.Jobs) do
								local jobData = Jobs:Get(v.Id)
								if jobData and jobData.Owner and jobData.Owner == char.SID then
									table.insert(ownedBusinesses, v.Id)
								end
							end
						end
						p:resolve({
							data = char,
							convictions = convictions and convictions[1] or {},
							vehicles = vehicles,
							ownedBusinesses = ownedBusinesses,
						})
					end)
				end)
			else
				p:resolve(character[1])
			end
		end)
		return Citizen.Await(p)
	end,
	Update = function(self, requester, id, key, value)
		local p = promise.new()
		local logVal = value
		if type(value) == "table" then
			logVal = json.encode(value)
		end

		local mdtHistoryEntry
		if requester == -1 then
			mdtHistoryEntry = json.encode({
				Time = (os.time() * 1000),
				Char = -1,
				Log = string.format("System Updated Profile, Set %s To %s", key, logVal),
			})
		else
			mdtHistoryEntry = json.encode({
				Time = (os.time() * 1000),
				Char = requester:GetData("SID"),
				Log = string.format("%s Updated Profile, Set %s To %s", requester:GetData("First") .. " " .. requester:GetData("Last"), key, logVal),
			})
		end
		
		local sql = string.format('UPDATE characters SET `%s` = ?, MDTHistory = JSON_ARRAY_APPEND(COALESCE(MDTHistory, JSON_ARRAY()), "$", ?) WHERE SID = ?', key)
		local params = { (type(value) == 'table' and json.encode(value) or value), mdtHistoryEntry, id }

		MySQL.update(sql, params, function(affectedRows)
			if affectedRows and affectedRows > 0 then
				local target = Fetch:SID(id)
				if target then
					target:GetData("Character"):SetData(key, value)
				end
				p:resolve(true)
			else
				p:resolve(false)
			end
		end)
		return Citizen.Await(p)
	end,
}

AddEventHandler("MDT:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("MDT:Search:people", function(source, data, cb)
		cb(MDT.People.Search:People(data.term))
	end)

	Callbacks:RegisterServerCallback("MDT:Search:government", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.People.Search:Government(data.term))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Search:not-government", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.People.Search:NotGovernment(data.term))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Search:job", function(source, data, cb)
		if CheckMDTPermissions(source, false) or CheckBusinessPermissions(source) then
			cb(MDT.People.Search:Job(data.job, data.term))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Search:not-job", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.People.Search:NotJob(data.job, data.term))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:View:person", function(source, data, cb)
		cb(MDT.People:View(data, true))
	end)

	Callbacks:RegisterServerCallback("MDT:Update:person", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")
		if char and CheckMDTPermissions(source, false) and data.SID then
			cb(MDT.People:Update(char, data.SID, data.Key, data.Data))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:CheckCallsign", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			MySQL.query('SELECT * FROM characters WHERE Callsign = ?', { data }, function(results)
				cb(results and #results == 0)
			end)
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:CheckParole", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			MySQL.query('SELECT * FROM characters WHERE SID = ? AND Parole IS NOT NULL', { data }, function(results)
				if results and results[1] and results[1].Parole ~= nil then
					cb(results[1].Parole)
				else
					cb(false)
				end
			end)
		else
			cb(false)
		end
	end)
end)
