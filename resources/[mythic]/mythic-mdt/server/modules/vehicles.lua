_MDT.Vehicles = {
	Search = function(self, term)
		local p = promise.new()
		MySQL.query('SELECT * FROM vehicles WHERE (JSON_EXTRACT(Owner, "$.Type") = 0 AND CAST(JSON_EXTRACT(Owner, "$.Id") AS CHAR) LIKE ?) OR VIN LIKE ? OR RegisteredPlate LIKE ? OR CONCAT(Make, " ", Model) LIKE ? LIMIT 24', {
			'%' .. term .. '%',
			'%' .. term .. '%',
			'%' .. term .. '%',
			'%' .. term .. '%'
		}, function(success, results)
			if not success then
				Logger:Error("MDT", "Failed to search vehicles", { console = true })
				p:resolve(false)
				return
			end
			p:resolve(results)
		end)
		GlobalState['MDT:Metric:Search'] = GlobalState['MDT:Metric:Search'] + 1
		return Citizen.Await(p)
	end,
	View = function(self, VIN)
		local p = promise.new()
		MySQL.query('SELECT * FROM vehicles WHERE VIN = ? LIMIT 1', {VIN}, function(success, results)
			if not success or #results <= 0 then
				p:resolve(false)
				return
			end
			local vehicle = results[1]

			if vehicle.Owner then
				-- Decode JSON Owner data if it's a string
				if type(vehicle.Owner) == "string" then
					vehicle.Owner = json.decode(vehicle.Owner)
				end
				
				if vehicle.Owner.Type == 0 then
					vehicle.Owner.Person = MDT.People:View(vehicle.Owner.Id)
				elseif vehicle.Owner.Type == 1 or vehicle.Owner.Type == 2 then
					local jobData = Jobs:DoesExist(vehicle.Owner.Id, vehicle.Owner.Workplace)
					if jobData then
						if jobData.Workplace then
							vehicle.Owner.JobName = string.format('%s (%s)', jobData.Name, jobData.Workplace.Name)
						else
							vehicle.Owner.JobName = jobData.Name
						end
					end
				end

				if vehicle.Owner.Type == 2 then
					vehicle.Owner.JobName = vehicle.Owner.JobName .. " (Dealership Buyback)"
				end
			end
			p:resolve(vehicle)
		end)
		return Citizen.Await(p)
	end,
	Flags = {
		Add = function(self, VIN, data, plate)
			local p = promise.new()
			
			-- Get current flags and add new one
			MySQL.query('SELECT Flags FROM vehicles WHERE VIN = ? LIMIT 1', {VIN}, function(success, results)
				if success and #results > 0 then
					local currentFlags = results[1].Flags or {}
					if type(currentFlags) == "string" then
						currentFlags = json.decode(currentFlags) or {}
					end
					
					table.insert(currentFlags, data)
					
					MySQL.update('UPDATE vehicles SET Flags = ? WHERE VIN = ?', {
						json.encode(currentFlags),
						VIN
					}, function(updateSuccess, result)
						if updateSuccess and data.radarFlag and plate then
							Radar:AddFlaggedPlate(plate, 'Vehicle Flagged in MDT')
						end
						p:resolve(updateSuccess)
					end)
				else
					Logger:Error("MDT", "Failed to get vehicle flags", { console = true })
					p:resolve(false)
				end
			end)
			return Citizen.Await(p)
		end,
		Remove = function(self, VIN, flag)
			local p = promise.new()
			
			-- Get current flags and remove the specified one
			MySQL.query('SELECT Flags FROM vehicles WHERE VIN = ? LIMIT 1', {VIN}, function(success, results)
				if success and #results > 0 then
					local currentFlags = results[1].Flags or {}
					if type(currentFlags) == "string" then
						currentFlags = json.decode(currentFlags) or {}
					end
					
					-- Remove flags with matching Type
					local newFlags = {}
					for k, v in ipairs(currentFlags) do
						if v.Type ~= flag then
							table.insert(newFlags, v)
						end
					end
					
					MySQL.update('UPDATE vehicles SET Flags = ? WHERE VIN = ?', {
						json.encode(newFlags),
						VIN
					}, function(updateSuccess, result)
						p:resolve(updateSuccess)
					end)
				else
					Logger:Error("MDT", "Failed to get vehicle flags for removal", { console = true })
					p:resolve(false)
				end
			end)
			return Citizen.Await(p)
		end,
	},
	UpdateStrikes = function(self, VIN, strikes)
		local p = promise.new()
		MySQL.update('UPDATE vehicles SET Strikes = ? WHERE VIN = ?', {
			json.encode(strikes),
			VIN
		}, function(success, result)
			p:resolve(success)
		end)
		return Citizen.Await(p)
	end,
	GetStrikes = function(self, VIN)
		local p = promise.new()
		MySQL.query('SELECT VIN, Strikes, RegisteredPlate FROM vehicles WHERE VIN = ? LIMIT 1', {VIN}, function(success, results)
			if success then
				local veh = results[1]
				local strikes = 0
				if veh and veh.Strikes then
					local strikesData = veh.Strikes
					if type(strikesData) == "string" then
						strikesData = json.decode(strikesData) or {}
					end
					if #strikesData > 0 then
						strikes = #strikesData
					end
				end

				p:resolve(strikes)
			else
				Logger:Error("MDT", "Failed to get vehicle strikes", { console = true })
				p:resolve(0)
			end
		end)

		return Citizen.Await(p)
	end
}

AddEventHandler("MDT:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("MDT:Search:vehicle", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.Vehicles:Search(data.term))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:View:vehicle", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.Vehicles:View(data))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Create:vehicle-flag", function(source, data, cb)
		if CheckMDTPermissions(source, false, 'police') then
			cb(MDT.Vehicles.Flags:Add(data.parent, data.doc, data.plate))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Delete:vehicle-flag", function(source, data, cb)
		if CheckMDTPermissions(source, false, 'police') then
			cb(MDT.Vehicles.Flags:Remove(data.parent, data.id))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Update:vehicle-strikes", function(source, data, cb)
		if CheckMDTPermissions(source, false, 'police') then
			cb(MDT.Vehicles:UpdateStrikes(data.VIN, data.strikes))
		else
			cb(false)
		end
	end)
end)
