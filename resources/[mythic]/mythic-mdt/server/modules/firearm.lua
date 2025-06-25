_MDT.Firearm = {
	Search = function(self, term)
		local p = promise.new()
		-- MongoDB query with $regexMatch and $and/$or is not directly portable to SQL, so we simplify to LIKE for names and serial
		MySQL.prepare('SELECT * FROM firearms WHERE (CONCAT(Owner->>\'$.First\', " ", Owner->>\'$.Last\') LIKE ? OR Owner->>\'$.SID\' LIKE ? OR Serial LIKE ?) AND Scratched = 0', { '%'..term..'%', '%'..term..'%', '%'..term..'%' }, function(results)
			if not results then
				p:resolve(false)
				return
			end
			p:resolve(results)
		end)
		GlobalState["MDT:Metric:Search"] = GlobalState["MDT:Metric:Search"] + 1
		return Citizen.Await(p)
	end,
	View = function(self, id)
		local p = promise.new()
		MySQL.prepare('SELECT * FROM firearms WHERE id = ? LIMIT 1', { id }, function(results)
			if not results then
				p:resolve(false)
				return
			end
			p:resolve(results[1])
		end)
		return Citizen.Await(p)
	end,
	Flags = {
		Add = function(self, id, data)
			local p = promise.new()
			local flagJson = json.encode(data)
			local sql = [[
				UPDATE firearms
				SET Flags = 
					CASE
						WHEN Flags IS NULL THEN JSON_ARRAY(?)
						ELSE JSON_ARRAY_APPEND(Flags, '$', CAST(? AS JSON))
					END
				WHERE id = ?
			]]
			MySQL.prepare(sql, {flagJson, flagJson, id}, function(affectedRows)
				p:resolve(affectedRows and affectedRows > 0)
			end)
			return Citizen.Await(p)
		end,
		Remove = function(self, id, flagType)
			local p = promise.new()
			local sql = [[
				UPDATE firearms
				SET Flags = (
					SELECT
						IFNULL(
							JSON_ARRAYAGG(f.value),
							JSON_ARRAY()
						)
					FROM
						JSON_TABLE(Flags, '$[*]' COLUMNS (value JSON PATH '$', type VARCHAR(255) PATH '$.Type')) AS f
					WHERE
						f.type IS NULL OR f.type != ?
				)
				WHERE id = ?
			]]
			MySQL.prepare(sql, {flagType, id}, function(affectedRows)
				p:resolve(affectedRows and affectedRows > 0)
			end)
			return Citizen.Await(p)
		end,
	},
}

AddEventHandler("MDT:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("MDT:Search:firearm", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.Firearm:Search(data.term))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:View:firearm", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.Firearm:View(data))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Create:firearm-flag", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.Firearm.Flags:Add(data.parentId, data.doc))
		else
			cb(false)
		end
	end)

	Callbacks:RegisterServerCallback("MDT:Delete:firearm-flag", function(source, data, cb)
		if CheckMDTPermissions(source, false) then
			cb(MDT.Firearm.Flags:Remove(data.parentId, data.id))
		else
			cb(false)
		end
	end)
end)
