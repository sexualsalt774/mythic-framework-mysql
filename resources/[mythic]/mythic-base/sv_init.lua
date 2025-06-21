AddEventHandler("Core:Shared:Ready", function()
	COMPONENTS.Default:AddAuth('roles', 1662066295, {
        {
			Abv = "Whitelisted",
			Name = "Whitelisted",
			Queue = {
				Priority = 0,
			},
			Permission = {
				Level = 0,
				Group = "",
			},
        },
        {
			Abv = "Staff",
			Name = "Staff",
			Queue = {
				Priority = 0,
			},
			Permission = {
				Level = 50,
				Group = "staff",
			},
        },
        {
			Abv = "Admin",
			Name = "Admin",
			Queue = {
				Priority = 0,
			},
			Permission = {
				Level = 75,
				Group = "admin",
			},
        },
        {
			Abv = "Owner",
			Name = "Owner",
			Queue = {
				Priority = 0,
			},
			Permission = {
				Level = 100,
				Group = "admin",
			},
        },
    })

	MySQL.query('SELECT * FROM roles', {}, function(results)
		if not results or #results <= 0 then
			COMPONENTS.Logger:Critical("Core", "Failed to Load User Groups", {
				console = true,
				file = true,
			})

			return
		end

		COMPONENTS.Config.Groups = {}

		for k, v in ipairs(results) do
			-- Parse JSON fields if they're stored as strings
			if type(v.Queue) == "string" then
				v.Queue = json.decode(v.Queue)
			end
			if type(v.Permission) == "string" then
				v.Permission = json.decode(v.Permission)
			end
			
			COMPONENTS.Config.Groups[v.Abv] = v
		end

		COMPONENTS.Logger:Info("Core", string.format("Loaded %s User Groups", #results), {
			console = true,
		})
	end)
end)
