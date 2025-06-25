PHONE.Messages = {
	Read = function(self, owner, number)
		MySQL.update("UPDATE phone_messages SET unread = 0 WHERE owner = ? AND number = ?", {
			owner,
			number,
		})
	end,
	Delete = function(self, owner, number)
		MySQL.update("UPDATE phone_messages SET deleted = 1 WHERE owner = ? AND number = ?", {
			owner,
			number,
		})
	end,
}

AddEventHandler("Phone:Server:RegisterMiddleware", function()
	Middleware:Add("Characters:Spawning", function(source)
		local char = Fetch:Source(source):GetData("Character")
		MySQL.query("SELECT * FROM phone_messages WHERE owner = ? AND (deleted IS NULL OR deleted = 0)", {
			char:GetData("Phone"),
		}, function(messages)
			TriggerClientEvent("Phone:Client:SetData", source, "messages", messages or {})
		end)
	end, 2)
	Middleware:Add("Phone:UIReset", function(source)
		local char = Fetch:Source(source):GetData("Character")
		MySQL.query("SELECT * FROM phone_messages WHERE owner = ? AND (deleted IS NULL OR deleted = 0)", {
			char:GetData("Phone"),
		}, function(messages)
			TriggerClientEvent("Phone:Client:SetData", source, "messages", messages or {})
		end)
	end, 2)
end)

AddEventHandler("Phone:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("Phone:Messages:SendMessage", function(source, data, cb)
		local src = source
		local char = Fetch:Source(src):GetData("Character")
		local data2 = {
			owner = data.number,
			number = data.owner,
			message = data.message,
			time = data.time + 1,
			-- I Wanna Die Omegalul
			method = 0,
			unread = true,
		}
		
		-- Insert first message
		MySQL.insert("INSERT INTO phone_messages (owner, number, message, time, method, unread) VALUES (?, ?, ?, ?, ?, ?)", {
			data.owner,
			data.number,
			data.message,
			data.time,
			data.method or 0,
			data.unread or false,
		}, function(insertId1)
			if insertId1 then
				-- Insert second message
				MySQL.insert("INSERT INTO phone_messages (owner, number, message, time, method, unread) VALUES (?, ?, ?, ?, ?, ?)", {
					data2.owner,
					data2.number,
					data2.message,
					data2.time,
					data2.method,
					data2.unread,
				}, function(insertId2)
					local target = Fetch:CharacterData("Phone", data.number)
					if target ~= nil then
						data2.contact = Phone.Contacts:IsContact(char:GetData("ID"), data2.number)
						TriggerClientEvent("Phone:Client:Messages:Notify", target:GetData("Source"), data2, false)
					end
					cb(insertId1)
				end)
			else
				cb(nil)
			end
		end)
	end)

	Callbacks:RegisterServerCallback("Phone:Messages:ReadConvo", function(source, data, cb)
		local src = source
		local char = Fetch:Source(src):GetData("Character")
		Phone.Messages:Read(char:GetData("Phone"), data)
	end)

	Callbacks:RegisterServerCallback("Phone:Messages:DeleteConvo", function(source, data, cb)
		local src = source
		local char = Fetch:Source(src):GetData("Character")
		Phone.Messages:Delete(char:GetData("Phone"), data.number)
	end)
end)
