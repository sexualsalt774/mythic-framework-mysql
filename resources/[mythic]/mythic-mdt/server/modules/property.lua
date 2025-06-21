_MDT.Properties = {
	Search = function(self, term)
		local p = promise.new()
		
		-- Convert MongoDB query to MySQL with JSON functions
		local query = [[
			SELECT * FROM properties 
			WHERE type != 'container' 
			AND (unlisted IS NULL OR unlisted = 0)
			AND (
				JSON_EXTRACT(owner, '$.SID') LIKE ? 
				OR CONCAT(JSON_EXTRACT(owner, '$.First'), ' ', JSON_EXTRACT(owner, '$.Last')) LIKE ? 
				OR label LIKE ?
			)
		]]
		
		local searchTerm = '%' .. term .. '%'
		MySQL.query(query, {searchTerm, searchTerm, searchTerm}, function(results)
			if not results then
				p:resolve(false)
				return
			end
			
			-- Decode JSON fields for each result
			for k, v in pairs(results) do
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
			end
			
			p:resolve(results)
		end)
		GlobalState['MDT:Metric:Search'] = GlobalState['MDT:Metric:Search'] + 1
		return Citizen.Await(p)
	end,
	-- View = function(self, VIN)
	-- 	local p = promise.new()
	-- 	MySQL.query('SELECT * FROM vehicles WHERE VIN = ? LIMIT 1', {VIN}, function(results)
	-- 		if not results or #results <= 0 then
	-- 			p:resolve(false)
	-- 			return
	-- 		end
	-- 		local vehicle = results[1]

	-- 		if vehicle.Owner then
	-- 			-- Decode JSON Owner data if it's a string
	-- 			if type(vehicle.Owner) == "string" then
	-- 				vehicle.Owner = json.decode(vehicle.Owner)
	-- 			end
				
	-- 			if vehicle.Owner.Type == 0 then
	-- 				vehicle.Owner.Person = MDT.People:View(vehicle.Owner.Id)
	-- 			elseif vehicle.Owner.Type == 1 then
	-- 				local jobData = Jobs:DoesExist(vehicle.Owner.Id, vehicle.Owner.Workplace)
	-- 				if jobData then
	-- 					if jobData.Workplace then
	-- 						vehicle.Owner.JobName = string.format('%s (%s)', jobData.Name, jobData.Workplace.Name)
	-- 					else
	-- 						vehicle.Owner.JobName = jobData.Name
	-- 					end
	-- 				end
	-- 			end
	-- 		end
	-- 		p:resolve(vehicle)
	-- 	end)
	-- 	return Citizen.Await(p)
	-- end,
}

AddEventHandler("MDT:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("MDT:Search:property", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.Properties:Search(data.term))
		else
			cb(false)
		end
	end)

	-- Callbacks:RegisterServerCallback("MDT:View:vehicle", function(source, data, cb)
	-- 	if CheckMDTPermissions(source, false) then
	-- 		cb(MDT.Vehicles:View(data))
	-- 	else
	-- 		cb(false)
	-- 	end
	-- end)
end)
