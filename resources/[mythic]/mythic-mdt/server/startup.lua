_warrants = {}
_charges = {}
_tags = {}
_notices = {}

local _ran = false

function Startup()
	if _ran then
		return
	end
	AddDefaultData()
	RegisterTasks()

	-- Update expired warrants
	MySQL.update('UPDATE mdt_warrants SET state = "expired" WHERE expires <= ?', {
		os.time() * 1000
	}, function(success, updated)
		if success then
			Logger:Trace("MDT", "Expired ^2" .. (updated or 0) .. "^7 Old Warrants", { console = true })
		end
	end)

	-- Load active warrants
	MySQL.query('SELECT * FROM mdt_warrants WHERE state = "active"', {}, function(success, results)
		if success and results then
			Logger:Trace("MDT", "Loaded ^2" .. #results .. "^7 Active Warrants", { console = true })
			_warrants = results
		end
	end)

	-- Load charges
	MySQL.query('SELECT * FROM mdt_charges', {}, function(success, results)
		if success and results then
			Logger:Trace("MDT", "Loaded ^2" .. #results .. "^7 Charges", { console = true })
			_charges = results
		end
	end)

	-- Load tags
	MySQL.query('SELECT * FROM mdt_tags', {}, function(success, results)
		if success and results then
			Logger:Trace("MDT", "Loaded ^2" .. #results .. "^7 Tags", { console = true })
			_tags = results
		end
	end)

	-- Load notices
	MySQL.query('SELECT * FROM mdt_notices', {}, function(success, results)
		if success and results then
			Logger:Trace("MDT", "Loaded ^2" .. #results .. "^7 Notices", { console = true })
			_notices = results
		end
	end)

	-- Load flagged vehicles - very simple query
	MySQL.query('SELECT VIN, Flags, RegisteredPlate, Type FROM vehicles', {}, function(success, results)
		if success then
			local flaggedCount = 0
			if results and #results > 0 then
				for k, v in ipairs(results) do
					if v.RegisteredPlate and v.Type == 0 and v.Flags then
						-- Check if Flags contains radarFlag
						local flags = v.Flags
						if type(flags) == "string" then
							flags = json.decode(flags)
						end
						
						if flags and type(flags) == "table" then
							for _, flag in ipairs(flags) do
								if flag and flag.radarFlag then
									Radar:AddFlaggedPlate(v.RegisteredPlate, 'Vehicle Flagged in MDT')
									flaggedCount = flaggedCount + 1
									break
								end
							end
						end
					end
				end
			end
			Logger:Trace("MDT", "Loaded ^2" .. flaggedCount .. "^7 Flagged Vehicles", { console = true })
		else
			Logger:Error("MDT", "Failed to load flagged vehicles", { console = true })
		end
	end)

	_ran = true

	SetHttpHandler(function(req, res)
		if req.path == '/charges' then
			res.send(json.encode(_charges))
		end
	end)
end
