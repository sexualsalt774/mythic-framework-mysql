LAPTOP.BizWiz = LAPTOP.BizWiz or {}
LAPTOP.BizWiz.Receipts = {
	Search = function(self, jobId, term)
        if not term then term = '' end
		local p = promise.new()

        local aggregation = {}

        table.insert(aggregation, {
            ['$match'] = {
                ['$or'] = {
                    {
                        customerName = { ['$regex'] = term, ['$options'] = 'i' }
                    },
					{
                        ["$expr"] = {
                            ["$regexMatch"] = {
                                input = {
									["$concat"] = { 
										"$author.First", 
										" ", 
										"$author.Last", 
										" ", 
										{ ['$toString'] = "$author.SID" }
									}
                                },
                                regex = term,
                                options = "i",
                            },
                        },
                    },
                },
				job = jobId,
            },
        })

		MySQL.query("SELECT * FROM business_receipts WHERE job = ? AND (title LIKE ? OR JSON_EXTRACT(author, '$.First') LIKE ? OR JSON_EXTRACT(author, '$.Last') LIKE ? OR JSON_EXTRACT(author, '$.SID') LIKE ?) ORDER BY created DESC", {
			jobId, '%' .. term .. '%', '%' .. term .. '%', '%' .. term .. '%', '%' .. term .. '%'
		}, function(results)
			if not results then
				p:resolve(false)
				return
			end
			p:resolve(results)
		end)
		return Citizen.Await(p)
	end,
	View = function(self, jobId, id)
		local p = promise.new()
        MySQL.single("SELECT * FROM business_receipts WHERE job = ? AND id = ?", {jobId, id}, function(result)
			if not result then
				p:resolve(false)
				return
			end
			p:resolve(result)
		end)
		return Citizen.Await(p)
	end,
	Create = function(self, jobId, data)
		if not _bizWizConfig[jobId] then
			return false
		end

		local p = promise.new()
        data.job = jobId
		MySQL.insert("INSERT INTO business_receipts (title, content, job, author, created) VALUES (?, ?, ?, ?, ?)", {
			data.title, data.content, data.job, json.encode(data.author), data.created
		}, function(insertId)
			if not insertId then
				p:resolve(false)
				return
			end
			p:resolve({
				id = insertId,
			})
		end)

		return Citizen.Await(p)
	end,
	Update = function(self, jobId, id, char, report)
		local p = promise.new()
		MySQL.update("UPDATE business_receipts SET title = ?, content = ? WHERE id = ? AND job = ?", {
			report.title, report.content, id, jobId
		}, function(affectedRows)
			if affectedRows and affectedRows > 0 then
				-- Add to history
				MySQL.update("UPDATE business_receipts SET history = JSON_ARRAY_APPEND(history, '$', ?) WHERE id = ?", {
					json.encode({
						Time = (os.time() * 1000),
						Char = char:GetData("SID"),
						Log = string.format(
								"%s Updated Report",
								char:GetData("First") .. " " .. char:GetData("Last")
						),
					}),
					id
				}, function(historyResult)
					p:resolve(true)
				end)
			else
				p:resolve(false)
			end
		end)
		return Citizen.Await(p)
	end,
    Delete = function(self, jobId, id)
        local p = promise.new()

        MySQL.update("DELETE FROM business_receipts WHERE id = ? AND job = ?", {id, jobId}, function(affectedRows)
			p:resolve(affectedRows and affectedRows > 0)
		end)
		return Citizen.Await(p)
    end,
	DeleteAll = function(self, jobId)
		if not jobId then return false; end

		local p = promise.new()

        MySQL.update("DELETE FROM business_receipts WHERE job = ?", {jobId}, function(affectedRows)
			p:resolve(affectedRows and affectedRows > 0)
		end)
		return Citizen.Await(p)
	end,
}

AddEventHandler("Laptop:Server:RegisterCallbacks", function()
    Callbacks:RegisterServerCallback("Laptop:BizWiz:Receipt:Search", function(source, data, cb)
        local job = CheckBusinessPermissions(source)
		if job then
			cb(Laptop.BizWiz.Receipts:Search(job, data.term))
		else
			cb(false)
		end
    end)

    Callbacks:RegisterServerCallback("Laptop:BizWiz:Receipt:Create", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        local job = CheckBusinessPermissions(source, 'LAPTOP_CREATE_RECEIPT')
		if job then
			data.doc.author = {
				SID = char:GetData("SID"),
				First = char:GetData("First"),
				Last = char:GetData("Last"),
			}
			cb(Laptop.BizWiz.Receipts:Create(job, data.doc))
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("Laptop:BizWiz:Receipt:Update", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        local job = CheckBusinessPermissions(source, 'LAPTOP_MANAGE_RECEIPT')
		if char and job then
            data.Report.lastUpdated = {
                Time = (os.time() * 1000),
                SID = char:GetData("SID"),
                First = char:GetData("First"),
                Last = char:GetData("Last"),
            }
			cb(Laptop.BizWiz.Receipts:Update(job, data.id, char, data.Report))
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("Laptop:BizWiz:Receipt:Delete", function(source, data, cb)
        local job = CheckBusinessPermissions(source, 'LAPTOP_MANAGE_RECEIPT')
		if job then
			cb(Laptop.BizWiz.Receipts:Delete(job, data.id))
        else
            cb(false)
        end
    end)

	Callbacks:RegisterServerCallback("Laptop:BizWiz:Receipt:DeleteAll", function(source, data, cb)
        local job = CheckBusinessPermissions(source, 'LAPTOP_CLEAR_RECEIPT')
		if job then
			cb(Laptop.BizWiz.Receipts:DeleteAll(job))
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("Laptop:BizWiz:Receipt:View", function(source, data, cb)
        local job = CheckBusinessPermissions(source)
		if job then
			cb(Laptop.BizWiz.Receipts:View(job, data))
        else
			cb(false)
		end
    end)
end)
