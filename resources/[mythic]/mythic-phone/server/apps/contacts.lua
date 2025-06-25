PHONE.Contacts = {
	IsContact = function(self, myId, targetNumber)
		local p = promise.new()
		MySQL.single("SELECT * FROM phone_contacts WHERE `character` = ? AND number = ? LIMIT 1", {
			myId,
			targetNumber,
		}, function(result)
			p:resolve(result)
		end)
		return Citizen.Await(p)
	end,
}

AddEventHandler("Phone:Server:RegisterMiddleware", function()
	Middleware:Add("Characters:Spawning", function(source)
		local char = Fetch:Source(source):GetData("Character")
		MySQL.query("SELECT * FROM phone_contacts WHERE `character` = ?", {
			char:GetData("ID"),
		}, function(contacts)
			TriggerClientEvent("Phone:Client:SetData", source, "contacts", contacts or {})
		end)
	end, 2)
	Middleware:Add("Phone:UIReset", function(source)
		local char = Fetch:Source(source):GetData("Character")
		MySQL.query("SELECT * FROM phone_contacts WHERE `character` = ?", {
			char:GetData("ID"),
		}, function(contacts)
			TriggerClientEvent("Phone:Client:SetData", source, "contacts", contacts or {})
		end)
	end, 2)
end)

AddEventHandler("Phone:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("Phone:Contacts:Create", function(source, data, cb)
		local src = source
		local char = Fetch:Source(src):GetData("Character")
		if char then
			data.character = char:GetData("ID")
			MySQL.insert("INSERT INTO phone_contacts (`character`, name, number, color, avatar, favorite) VALUES (?, ?, ?, ?, ?, ?)", {
				data.character,
				data.name,
				data.number,
				data.color,
				data.avatar,
				data.favorite or false,
			}, function(insertId)
				if insertId then
					cb(insertId)
				else
					cb(nil)
				end
			end)
		else
			cb(nil)
		end
	end)

	Callbacks:RegisterServerCallback("Phone:Contacts:Update", function(source, data, cb)
		if data.id == nil then
			return cb(nil)
		end

		local src = source
		local char = Fetch:Source(src):GetData("Character")
		if char then
			data.character = char:GetData("ID")
			MySQL.update("UPDATE phone_contacts SET name = ?, number = ?, color = ?, avatar = ?, favorite = ? WHERE `character` = ? AND id = ?", {
				data.name,
				data.number,
				data.color,
				data.avatar,
				data.favorite or false,
				char:GetData("ID"),
				data.id,
			}, function(affectedRows)
				if affectedRows > 0 then
					cb(true)
				else
					cb(nil)
				end
			end)
		else
			cb(nil)
		end
	end)

	Callbacks:RegisterServerCallback("Phone:Contacts:Delete", function(source, data, cb)
		local src = source
		local char = Fetch:Source(src):GetData("Character")
		if char and data then
			MySQL.update("DELETE FROM phone_contacts WHERE `character` = ? AND id = ?", {
				char:GetData("ID"),
				data,
			}, function(affectedRows)
				cb(affectedRows > 0)
			end)
		else
			cb(false)
		end
	end)
end)
