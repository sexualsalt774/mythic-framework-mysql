_MDT.Reports = {
	Search = function(self, term, type, tagsFilter)
        if not term then term = '' end
		local p = promise.new()

        local aggregation = {
            {
                ['$addFields'] = {
                    ['suspects.suspect'] = {
                        ["$map"] = {
                            ["input"] = "$suspects.suspect",
                            ["as"] = "u",
                            ["in"] = {
                                ["$mergeObjects"] = {
                                    "$$u",
                                    {
                                        FullName = { ["$concat"] = { "$$u.First", " ", "$$u.Last" } }
                                    }
                                }
                            }
                        }
                    }
                }
            },
        }

        local filterMatchQuery = {}
        if tagsFilter and #tagsFilter > 0 then
            filterMatchQuery.tags = { ['$in'] = tagsFilter }
        end

        if type then
            filterMatchQuery.type = type
        end

        if filterMatchQuery.type or filterMatchQuery.tags then
            table.insert(aggregation, {
                ['$match'] = filterMatchQuery,
            })
        end

        table.insert(aggregation, {
            ['$match'] = {
                ['$or'] = {
                    {
                        ['suspects.suspect.FullName'] = { ['$regex'] = term, ['$options'] = 'i' }
                    },
                    {
                        title = { ['$regex'] = term, ['$options'] = 'i' }
                    },
                    {
                        ["$expr"] = {
                            ["$regexMatch"] = {
                                input = {
                                    ["$toString"] = "$ID",
                                },
                                regex = term,
                                options = "i",
                            },
                        },
                    },
                },
            },
        })

        table.insert(aggregation, {
            ["$sort"] = {
                time = -1,
            }
        })

        if #term <= 0 then
            table.insert(aggregation, {
                ["$limit"] = 24
            })
        end

        table.insert(aggregation, {
            ["$unwind"] = {
                path = '$suspects.suspect',
                preserveNullAndEmptyArrays = true,
            }
        })

		MySQL.query("SELECT * FROM mdt_reports WHERE JSON_CONTAINS(suspects, JSON_OBJECT('suspect', JSON_OBJECT('First', ?, 'Last', ?)), '$') OR JSON_CONTAINS(suspects, JSON_OBJECT('suspect', JSON_OBJECT('SID', ?)), '$') ORDER BY time DESC", {
			term, term, term
		}, function(results)
			if not results then
				p:resolve(false)
				return
			end
			GlobalState['MDT:Metric:Search'] = GlobalState['MDT:Metric:Search'] + 1
			p:resolve(results)
		end)
		return Citizen.Await(p)
	end,
    SearchEvidence = function(self, term)
        if not term then term = '' end
		local p = promise.new()

		MySQL.query("SELECT * FROM mdt_reports WHERE JSON_SEARCH(evidence, 'one', ?, null, '$[*].value') IS NOT NULL ORDER BY time DESC", {
			term
		}, function(results)
			if not results then
				p:resolve(false)
				return
			end
			GlobalState['MDT:Metric:Search'] = GlobalState['MDT:Metric:Search'] + 1
			p:resolve(results)
		end)
		return Citizen.Await(p)
	end,
	Mine = function(self, char)
		local p = promise.new()
        MySQL.query("SELECT * FROM mdt_reports WHERE primaries = ? OR JSON_EXTRACT(author, '$.SID') = ? ORDER BY time DESC", {
			char:GetData("Callsign"), char:GetData("SID")
		}, function(results)
			if not results then
				p:resolve(false)
				return
			end
			p:resolve(results)
		end)
		GlobalState['MDT:Metric:Search'] = GlobalState['MDT:Metric:Search'] + 1
		return Citizen.Await(p)
	end,
	View = function(self, id)
		local p = promise.new()
        MySQL.single("SELECT * FROM mdt_reports WHERE id = ?", {id}, function(result)
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
        data.ID = Sequence:Get('Report')
		MySQL.insert("INSERT INTO mdt_reports (ID, title, content, author, suspects, evidence, time) VALUES (?, ?, ?, ?, ?, ?, ?)", {
			data.ID, data.title, data.content, json.encode(data.author), json.encode(data.suspects), json.encode(data.evidence), data.time
		}, function(insertId)
			if not insertId then
				p:resolve(false)
				return
			end
			p:resolve({
				id = insertId,
				ID = data.ID,
			})
		end)
		GlobalState['MDT:Metric:Reports'] = GlobalState['MDT:Metric:Reports'] + 1
		return Citizen.Await(p)
	end,
	Update = function(self, id, char, report)
		local p = promise.new()
		MySQL.update("UPDATE mdt_reports SET title = ?, content = ?, suspects = ?, evidence = ? WHERE id = ?", {
			report.title, report.content, json.encode(report.suspects), json.encode(report.evidence), id
		}, function(affectedRows)
			if affectedRows > 0 then
				-- Add to history
				MySQL.update("UPDATE mdt_reports SET history = JSON_ARRAY_APPEND(history, '$', ?) WHERE id = ?", {
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
    Delete = function(self, id)
        local p = promise.new()

        MySQL.update("DELETE FROM mdt_reports WHERE id = ?", {id}, function(result)
			p:resolve(result and result.affectedRows > 0)
		end)
		return Citizen.Await(p)
    end,
}

AddEventHandler("MDT:Server:RegisterCallbacks", function()
    Callbacks:RegisterServerCallback("MDT:Search:report", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
		if CheckMDTPermissions(source, false) or char:GetData("Attorney") then
			cb(MDT.Reports:Search(data.term, data.reportType, data.tags))
		else
			cb(false)
		end
    end)

    Callbacks:RegisterServerCallback("MDT:Search:report-evidence", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.Reports:SearchEvidence(data.term))
		else
			cb(false)
		end
    end)

    Callbacks:RegisterServerCallback("MDT:Search:myReport", function(source, data, cb)
        -- local char = Fetch:Source(source):GetData("Character")
		-- if char:GetData('Job').Id == 'police' then
		-- 	cb(MDT.Reports:Mine(char))
		-- else
		-- 	cb(false)
		-- end
    end)

    Callbacks:RegisterServerCallback("MDT:Create:report", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
		if CheckMDTPermissions(source, false) then
			data.doc.author = {
				SID = char:GetData("SID"),
				First = char:GetData("First"),
				Last = char:GetData("Last"),
				Callsign = char:GetData("Callsign"),
			}
			cb(MDT.Reports:Create(data.doc))
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("MDT:Update:report", function(source, data, cb)
        local char = Fetch:Source(source):GetData('Character')
		if char and CheckMDTPermissions(source, false) then
            data.Report.lastUpdated = {
                Time = (os.time() * 1000),
                SID = char:GetData("SID"),
                First = char:GetData("First"),
                Last = char:GetData("Last"),
                Callsign = char:GetData("Callsign"),
            }
			cb(MDT.Reports:Update(data.ID, char, data.Report))
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("MDT:Delete:report", function(source, data, cb)
		if CheckMDTPermissions(source, true) then
			cb(MDT.Reports:Delete(data.id))
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("MDT:View:report", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
		if CheckMDTPermissions(source, false) or char:GetData("Attorney") then
			cb(MDT.Reports:View(data))
        else
			cb(false)
		end
    end)
end)
