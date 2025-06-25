PHONE.Documents = {
	Create = function(self, source, doc)
		local char = Fetch:Source(source):GetData("Character")
		if char ~= nil and type(doc) == "table" then
            local p = promise.new()

            doc.owner = char:GetData("ID")
            doc.time = os.time()

			MySQL.insert("INSERT INTO character_documents (owner, title, content, time, sharedWith) VALUES (?, ?, ?, ?, ?)", {
				doc.owner,
				doc.title,
				doc.content,
				doc.time,
				json.encode(doc.sharedWith or {}),
			}, function(insertId)
                if insertId then
                    doc.id = insertId
                    p:resolve(doc)
                else
                    p:resolve(false)
                end
			end)

            return Citizen.Await(p)
		end
        return false
	end,
    Edit = function(self, source, id, doc)
		local char = Fetch:Source(source):GetData("Character")
		if char ~= nil and type(doc) == "table" then
            local p = promise.new()

			MySQL.update("UPDATE character_documents SET title = ?, content = ?, time = ? WHERE owner = ? AND id = ?", {
				doc.title,
				doc.content,
				os.time(),
				char:GetData("ID"),
				id,
			}, function(affectedRows)
                if affectedRows > 0 then
                    -- Get updated document
                    MySQL.single("SELECT * FROM character_documents WHERE id = ?", {id}, function(res)
                        p:resolve(true)
                        if res and res.sharedWith then
                            local sharedWith = json.decode(res.sharedWith or '[]')
                            for k, v in ipairs(sharedWith) do
                                if v.ID then
                                    local char = Fetch:ID(v.ID)
                                    if char then
                                        TriggerClientEvent("Phone:Client:UpdateData", char:GetData("Source"), "myDocuments", res.id, res)
                                    end
                                end
                            end
                        end
                    end)
                else
                    p:resolve(false)
                end
			end)

            return Citizen.Await(p)
		end
        return false
	end,
	Delete = function(self, source, id)
        local char = Fetch:Source(source):GetData("Character")
        if char ~= nil then
            local p = promise.new()

            MySQL.single("SELECT * FROM character_documents WHERE id = ?", {id}, function(doc)
                if doc then
                    if doc.owner == char:GetData("ID") then
                        MySQL.update("DELETE FROM character_documents WHERE id = ?", {id}, function(affectedRows)
                            p:resolve(affectedRows > 0)
                            if affectedRows > 0 and doc.sharedWith then
                                local sharedWith = json.decode(doc.sharedWith or '[]')
                                for k, v in ipairs(sharedWith) do
                                    if v.ID then
                                        local char = Fetch:ID(v.ID)
                                        if char then
                                            TriggerClientEvent("Phone:Client:RemoveData", char:GetData("Source"), "myDocuments", doc.id)
                                        end
                                    end
                                end
                            end
                        end)
                    else
                        -- Remove from sharedWith
                        local sharedWith = json.decode(doc.sharedWith or '[]')
                        for i = #sharedWith, 1, -1 do
                            if sharedWith[i].ID == char:GetData("ID") then
                                table.remove(sharedWith, i)
                            end
                        end
                        MySQL.update("UPDATE character_documents SET sharedWith = ? WHERE id = ?", {
                            json.encode(sharedWith),
							id,
						}, function(affectedRows)
                            p:resolve(affectedRows > 0)
                        end)
                    end
                else
                    p:resolve(false)
                end
            end)

            return Citizen.Await(p)
        end
        return false
	end,
}

AddEventHandler("Phone:Server:RegisterMiddleware", function()
	Middleware:Add("Characters:Spawning", function(source)
		local char = Fetch:Source(source):GetData("Character")
		MySQL.query("SELECT * FROM character_documents WHERE owner = ? OR JSON_CONTAINS(sharedWith, ?)", {
			char:GetData("ID"),
			json.encode({ID = char:GetData("ID")}),
		}, function(docs)
			TriggerClientEvent("Phone:Client:SetData", source, "myDocuments", docs or {})
		end)
	end, 2)
	Middleware:Add("Phone:UIReset", function(source)
		local char = Fetch:Source(source):GetData("Character")
		MySQL.query("SELECT * FROM character_documents WHERE owner = ? OR JSON_CONTAINS(sharedWith, ?)", {
			char:GetData("ID"),
			json.encode({ID = char:GetData("ID")}),
		}, function(docs)
			TriggerClientEvent("Phone:Client:SetData", source, "myDocuments", docs or {})
		end)
	end, 2)
end)

AddEventHandler("Phone:Server:RegisterCallbacks", function()
    Callbacks:RegisterServerCallback("Phone:Documents:Create", function(source, data, cb)
		cb(Phone.Documents:Create(source, data))
	end)

    Callbacks:RegisterServerCallback("Phone:Documents:Edit", function(source, data, cb)
		cb(Phone.Documents:Edit(source, data.id, data.data))
	end)

	Callbacks:RegisterServerCallback("Phone:Documents:Delete", function(source, data, cb)
		cb(Phone.Documents:Delete(source, data))
	end)

    Callbacks:RegisterServerCallback("Phone:Documents:Refresh", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
		MySQL.query("SELECT * FROM character_documents WHERE owner = ? OR JSON_CONTAINS(sharedWith, ?)", {
			char:GetData("ID"),
			json.encode({ID = char:GetData("ID")}),
		}, function(docs)
            cb("myDocuments", docs or {})
		end)
	end)

    Callbacks:RegisterServerCallback("Phone:Documents:Share", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")
        if char and data and data.type and data.document then
            local target = nil
            if not data.nearby then
                if not data.target then
                    return cb(false)
                end

                target = Fetch:SID(data.target)
                if target then
                    target = target:GetData("Character")
                end

                if not target then
                    return cb(false)
                end

                if target:GetData("SID") == char:GetData("SID") then
                    return cb(false)
                end
            end

            local shareData = nil

            if data.type == 1 then
                data.document._id = nil
                data.document.sharedBy = {
                    ID = char:GetData("ID"),
                    First = char:GetData("First"),
                    Last = char:GetData("Last"),
                    SID = char:GetData("SID"),
                }
                data.document.shared = true
                data.document.sharedWith = {}

                sharedData = {
                    isCopy = true,
                    document = data.document,
                }
            elseif data.type == 2 or data.type == 3 then
                sharedData = {
                    isCopy = false,
                    document = {
                        _id = data.document._id,
                        title = data.document.title,
                        sharedBy = {
                            ID = char:GetData("ID"),
                            First = char:GetData("First"),
                            Last = char:GetData("Last"),
                            SID = char:GetData("SID"),
                        }
                    },
                    requireSignature = data.type == 3,
                }
            end

            if sharedData then
                if target then
                    TriggerClientEvent("Phone:Client:ReceiveShare", target:GetData("Source"), {
                        type = "documents",
                        data = sharedData,
                    }, os.time() * 1000)

                    return cb(true)
                else
                    local myPed = GetPlayerPed(source)
                    local myCoords = GetEntityCoords(myPed)
                    local myBucket = GetPlayerRoutingBucket(source)
                    for k, v in pairs(Fetch:All()) do
                        local tsrc = v:GetData("Source")
                        local tped = GetPlayerPed(tsrc)
                        local coords = GetEntityCoords(tped)
                        if tsrc ~= source and #(myCoords - coords) <= 5.0 and GetPlayerRoutingBucket(tsrc) == myBucket then
                            TriggerClientEvent("Phone:Client:ReceiveShare", tsrc, {
                                type = "documents",
                                data = sharedData,
                            }, os.time() * 1000)
                        end
                    end

                    return cb(true)
                end
            end
        end

        cb(false)
	end)

    Callbacks:RegisterServerCallback("Phone:Documents:RecieveShare", function(source, data, cb)
        if data then
            if data.isCopy then
                cb(Phone.Documents:Create(source, data.document))
            else
                local char = Fetch:Source(source):GetData("Character")
                if char then
                    MySQL.update("UPDATE character_documents SET sharedWith = JSON_ARRAY_APPEND(sharedWith, '$', ?), sharedBy = ? WHERE id = ? AND owner != ? AND NOT JSON_CONTAINS(sharedWith, ?)", {
                        json.encode({
                            Time = os.time(),
                            ID = char:GetData("ID"),
                            First = char:GetData("First"),
                            Last = char:GetData("Last"),
                            SID = char:GetData("SID"),
                            RequireSignature = data.requireSignature,
                        }),
                        json.encode(data.document.sharedBy),
                        data.document._id,
                        char:GetData("ID"),
                        json.encode({ID = char:GetData("ID")})
                    }, function(result)
                        if result and result.affectedRows > 0 then
                            MySQL.single("SELECT * FROM character_documents WHERE id = ?", {data.document._id}, function(res)
                                cb(res)
                            end)
                        else
                            cb(false)
                        end
                    end)
                else
                    cb(false)
                end
            end
        else
            cb(false)
        end
	end)

    Callbacks:RegisterServerCallback("Phone:Documents:Sign", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        if char then
            MySQL.update("UPDATE character_documents SET signed = JSON_ARRAY_APPEND(signed, '$', ?) WHERE id = ? AND owner != ? AND NOT JSON_CONTAINS(signed, ?)", {
                json.encode({
                    Time = os.time(),
                    ID = char:GetData("ID"),
                    First = char:GetData("First"),
                    Last = char:GetData("Last"),
                    SID = char:GetData("SID"),
                }),
                data,
                char:GetData("ID"),
                json.encode({ID = char:GetData("ID")})
            }, function(result)
                if result and result.affectedRows > 0 then
                    MySQL.single("SELECT * FROM character_documents WHERE id = ?", {data}, function(res)
                        cb(true)

                        if res and res.sharedWith then
                            for k, v in ipairs(res.sharedWith) do
                                if v.ID then
                                    local char = Fetch:ID(v.ID)
                                    if char then
                                        TriggerClientEvent("Phone:Client:UpdateData", char:GetData("Source"), "myDocuments", res.id, res)
                                    end
                                end
                            end

                            local char = Fetch:ID(res.owner)
                            if char then
                                TriggerClientEvent("Phone:Client:UpdateData", char:GetData("Source"), "myDocuments", res.id, res)
                            end
                        end
                    end)
                else
                    cb(false)
                end
            end)
        else
            cb(false)
        end
	end)
end)
