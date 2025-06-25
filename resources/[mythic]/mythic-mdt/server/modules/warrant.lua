_MDT.Warrants = {
	Search = function(self, term)
		local p = promise.new()
		MySQL.query("SELECT * FROM mdt_warrants ORDER BY created DESC", {}, function(results)
			if not results then
				p:resolve(false)
				return
			end

			p:resolve(results)
		end)

		return Citizen.Await(p)
	end,
	View = function(self, id)
		local p = promise.new()
		MySQL.single("SELECT * FROM mdt_warrants WHERE id = ?", {id}, function(result)
			if not result then
				p:resolve(false)
				return
			end
			p:resolve(result)
		end)
		return Citizen.Await(p)
	end,
	Create = function(self, data)
		local p = promise.new()
		MySQL.insert("INSERT INTO mdt_warrants (ID, title, description, suspect, author, state, created, expires) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", {
			data.ID, data.title, data.description, json.encode(data.suspect), json.encode(data.author), data.state, data.created, data.expires
		}, function(insertId)
			if not insertId then
				p:resolve(false)
				return
			end
			data.id = insertId
			table.insert(_warrants, data)
			for user, _ in pairs(_onDutyUsers) do
				TriggerClientEvent("MDT:Client:AddData", user, "warrants", data)
			end
			for user, _ in pairs(_onDutyLawyers) do
				TriggerClientEvent("MDT:Client:AddData", user, "warrants", data)
			end
			p:resolve(true)
		end)
		GlobalState["MDT:Metric:Warrants"] = GlobalState["MDT:Metric:Warrants"] + 1
		return Citizen.Await(p)
	end,
	Update = function(self, id, state, updater)
		local p = promise.new()
		MySQL.update("UPDATE mdt_warrants SET state = ? WHERE id = ?", {state, id}, function(affectedRows)
			if affectedRows == 0 then
				p:resolve(false)
				return
			end

			-- Add to history
			MySQL.update("UPDATE mdt_warrants SET history = JSON_ARRAY_APPEND(history, '$', ?) WHERE id = ?", {
				json.encode(updater), id
			}, function(historyResult)
				for k, v in ipairs(_warrants) do
					if v.id == id then
						v.state = state

						for user, _ in pairs(_onDutyUsers) do
							TriggerClientEvent("MDT:Client:UpdateData", user, "warrants", id, v)
						end

						for user, _ in pairs(_onDutyLawyers) do
							TriggerClientEvent("MDT:Client:UpdateData", user, "warrants", id, v)
						end
					end
				end

				p:resolve(true)
			end)
		end)

		return Citizen.Await(p)
	end,
	Delete = function(self, id)
		local p = promise.new()
		MySQL.update("DELETE FROM mdt_warrants WHERE id = ?", {id}, function(affectedRows)
			if affectedRows == 0 then
				p:resolve(false)
				return
			end

			for k, v in ipairs(_warrants) do
				if v.id == id then
					table.remove(_warrants, k)
					break
				end
			end

			for user, _ in pairs(_onDutyUsers) do
				TriggerClientEvent("MDT:Client:RemoveData", user, "warrants", id)
			end
			for user, _ in pairs(_onDutyLawyers) do
				TriggerClientEvent("MDT:Client:RemoveData", user, "warrants", id)
			end

			p:resolve(true)
		end)
		return Citizen.Await(p)
	end,
}

AddEventHandler("MDT:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("MDT:Search:warrant", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")
		cb(MDT.Warrants:Search(data.term))
	end)

	Callbacks:RegisterServerCallback("MDT:View:warrant", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.Warrants:View(data))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Create:warrant", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")

		if char and CheckMDTPermissions(source, false) then
			data.doc.author = {
				SID = char:GetData("SID"),
				First = char:GetData("First"),
				Last = char:GetData("Last"),
				Callsign = char:GetData("Callsign"),
			}
			data.doc.ID = Sequence:Get("Warrant")
			cb(MDT.Warrants:Create(data.doc))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Update:warrant", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")

		if char and CheckMDTPermissions(source, false) then
			local updater = {
				SID = char:GetData("SID"),
				First = char:GetData("First"),
				Last = char:GetData("Last"),
				Callsign = char:GetData("Callsign"),
				Action = string.format("Updated Warrant State To: %s", data.state),
				Date = os.time() * 1000,
			}
			if CheckMDTPermissions(source, false) then
				cb(MDT.Warrants:Update(data.id, data.state, updater))
			else
				cb(false)
			end
		else
			cb(false)
		end
	end)

	-- Callbacks:RegisterServerCallback("MDT:Delete:warrant", function(source, data, cb)
	-- 	local char = Fetch:Source(source):GetData("Character")

	-- 	if CheckMDTPermissions(source, false) then
	-- 		cb(MDT.Warrants:Delete(data.id))
	-- 	else
	-- 		cb(false)
	-- 	end
	-- end)
end)
