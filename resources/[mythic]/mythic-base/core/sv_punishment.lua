COMPONENTS.Punishment = {
	_required = { "CheckBan", "Kick", "Unban", "Ban" },
	_name = "base",
	CheckBan = function(self, key, value)
		local retVal = -1 -- Fuck You Lua

		local p = promise.new()
		
		MySQL.query('SELECT * FROM bans WHERE ?? = ? AND active = 1', {key, value}, function(results)
			-- if not results then
			-- 	COMPONENTS.Logger:Error(
			-- 		"Database",
			-- 		"[^8Error^7] Error in CheckBan query: " .. tostring(results),
			-- 		{ console = true, file = true, database = true }
			-- 	)
			-- 	p:resolve(nil)
			-- 	return
			-- end

			if results and #results > 0 then
				for k, v in ipairs(results) do
					if v.expires < os.time() and v.expires ~= -1 then
						MySQL.update('UPDATE bans SET active = 0 WHERE id = ?', {v.id})
					else
						p:resolve(v)
						return
					end
				end
				p:resolve(nil)
			else
				p:resolve(nil)
			end
		end)

		return Citizen.Await(p)
	end,
	Kick = function(self, source, reason, issuer)
		local tPlayer = COMPONENTS.Fetch:Source(source)

		if not tPlayer then
			return {
				success = false,
			}
		end

		if issuer ~= "Pwnzor" then
			if source == issuer then
				return {
					success = false,
					message = "Cannot Ban Yourself!",
				}
			end

			local iPlayer = COMPONENTS.Fetch:Source(issuer)

			if not iPlayer then
				return {
					success = false,
				}
			end

			if iPlayer.Permissions:GetLevel() <= tPlayer.Permissions:GetLevel() then
				return {
					success = false,
					message = "Insufficient Permissions",
				}
			end

			COMPONENTS.Punishment.Actions:Kick(source, reason, iPlayer:GetData("Name"))

			COMPONENTS.Logger:Info(
				"Punishment",
				string.format(
					"%s [%s] Kicked By %s [%s] For %s",
					tPlayer:GetData("Name"),
					tPlayer:GetData("AccountID"),
					iPlayer:GetData("Name"),
					iPlayer:GetData("AccountID"),
					reason
				),
				{ console = true, file = true, database = true, discord = { embed = true, type = "inform" } },
				{
					account = tPlayer:GetData("AccountID"),
					identifier = tPlayer:GetData("Identifier"),
					reason = reason,
					issuer = string.format("%s [%s]", iPlayer:GetData("Name"), iPlayer:GetData("AccountID")),
				}
			)

			return {
				success = true,
				Name = tPlayer:GetData("Name"),
				AccountID = tPlayer:GetData("AccountID"),
				reason = reason,
			}
		else
			COMPONENTS.Punishment.Actions:Kick(source, reason, issuer)

			COMPONENTS.Logger:Info(
				"Punishment",
				string.format(
					"%s [%s] Kicked By %s For %s",
					tPlayer:GetData("Name"),
					tPlayer:GetData("AccountID"),
					issuer,
					reason
				),
				{
					console = true,
					file = true,
					database = true,
					discord = { embed = true, type = "inform", webhook = GetConvar("discord_pwnzor_webhook", "") },
				},
				{
					account = tPlayer:GetData("AccountID"),
					identifier = tPlayer:GetData("Identifier"),
					reason = reason,
					issuer = issuer,
				}
			)

			return {
				success = true,
				Name = tPlayer:GetData("Name"),
				AccountID = tPlayer:GetData("AccountID"),
				reason = reason,
			}
		end
	end,
}

COMPONENTS.Punishment.Unban = {
	BanID = function(self, id, issuer)
		if COMPONENTS.Punishment:CheckBan("id", id) then
			local iPlayer = COMPONENTS.Fetch:Source(issuer)

			MySQL.query('SELECT * FROM bans WHERE id = ? AND active = 1', {id}, function(results)
				if results and #results > 0 then
					if COMPONENTS.Punishment.Actions:Unban(results, iPlayer) then
						COMPONENTS.Chat.Send.Server:Single(
							iPlayer:GetData("Source"),
							string.format("%s Has Been Revoked", id)
						)
					end
				end
			end)
		end
	end,
	AccountID = function(self, aId, issuer)
		if COMPONENTS.Punishment:CheckBan("account", aId) then
			local tPlayer = COMPONENTS.Fetch:PlayerData("AccountID", aId)
			local dbf = false

			if tPlayer == nil then
				tPlayer = COMPONENTS.Fetch:Website("account", aId)
				dbf = true
			end

			local iPlayer = COMPONENTS.Fetch:Source(issuer)

			MySQL.query('SELECT * FROM bans WHERE account = ? AND active = 1', {aId}, function(results)
				if results and #results > 0 then
					if COMPONENTS.Punishment.Actions:Unban(results, iPlayer) then
						COMPONENTS.Chat.Send.Server:Single(
							iPlayer:GetData("Source"),
							string.format(
								"%s (Account: %s) Has Been Unbanned",
								tPlayer:GetData("Name"),
								tPlayer:GetData("AccountID")
							)
						)
					end
				end
			end)

			if dbf then
				tPlayer:DeleteStore()
			end
		else
			COMPONENTS.Chat.Send.Server:Single(
				iPlayer:GetData("Source"),
				string.format("%s (Account: %s) Is Not Banned", tPlayer:GetData("Name"), tPlayer:GetData("AccountID"))
			)
		end
	end,
	Identifier = function(self, identifier, issuer)
		if COMPONENTS.Punishment:CheckBan("identifier", identifier) then
			local tPlayer = COMPONENTS.Fetch:PlayerData("Identifier", identifier)
			local dbf = false
			if tPlayer == nil then
				tPlayer = COMPONENTS.Fetch:Website("identifier", identifier)
				dbf = true
			end
			local iPlayer = COMPONENTS.Fetch:Source(issuer)

			MySQL.query('SELECT * FROM bans WHERE identifier = ? AND active = 1', {identifier}, function(results)
				if results and #results > 0 then
					if COMPONENTS.Punishment.Actions:Unban(results, iPlayer) then
						COMPONENTS.Chat.Send.Server:Single(
							iPlayer:GetData("Source"),
							string.format(
								"%s (Identifier: %s) Has Been Unbanned",
								tPlayer:GetData("Name"),
								tPlayer:GetData("Identifier")
							)
						)
					end
				end
			end)

			if dbf then
				tPlayer:DeleteStore()
			end
		else
			COMPONENTS.Chat.Send.Server:Single(
				iPlayer:GetData("Source"),
				string.format(
					"%s (Identifier: %s) Is Not Banned",
					tPlayer:GetData("Name"),
					tPlayer:GetData("Identifier")
				)
			)
		end
	end,
}

COMPONENTS.Punishment.Ban = {
	Source = function(self, source, expires, reason, issuer)
		local tPlayer = COMPONENTS.Fetch:Source(source)
		local iPlayer

		if not tPlayer then
			return {
				success = false,
			}
		end

		if issuer ~= "Pwnzor" then
			if source == issuer then
				return {
					success = false,
					message = "Cannot Ban Yourself!",
				}
			end

			iPlayer = COMPONENTS.Fetch:Source(issuer)
			if not iPlayer then
				return {
					success = false,
				}
			end

			if iPlayer.Permissions:GetLevel() < tPlayer.Permissions:GetLevel() then
				return {
					success = false,
					message = "Insufficient Permissions",
				}
			end

			issuer = string.format("%s [%s]", iPlayer:GetData("Name"), iPlayer:GetData("AccountID"))
		end

		local expStr = "Never"
		if expires ~= -1 then
			expires = (os.time() + ((60 * 60 * 24) * expires))
			expStr = os.date("%Y-%m-%d at %I:%M:%S %p", expires)
		end

		local banStr = string.format("%s Was Permanently Banned By %s for %s", tPlayer:GetData("Name"), issuer, reason)

		if expires ~= -1 then
			banStr = string.format(
				"%s Was Banned By %s Until %s for %s",
				tPlayer:GetData("Name"),
				issuer,
				expStr,
				reason
			)
		end

		if iPlayer ~= nil then
			COMPONENTS.Punishment.Actions:Ban(
				tPlayer:GetData("Source"),
				tPlayer:GetData("AccountID"),
				tPlayer:GetData("Identifier"),
				tPlayer:GetData("Name"),
				tPlayer:GetData("Tokens"),
				reason,
				expires,
				expStr,
				issuer,
				iPlayer:GetData("AccountID"),
				false
			)

			return {
				success = true,
				Name = tPlayer:GetData("Name"),
				AccountID = tPlayer:GetData("AccountID"),
				expires = expires,
				reason = reason,
				banStr = banStr,
			}
		else
			COMPONENTS.Punishment.Actions:Ban(
				tPlayer:GetData("Source"),
				tPlayer:GetData("AccountID"),
				tPlayer:GetData("Identifier"),
				tPlayer:GetData("Name"),
				tPlayer:GetData("Tokens"),
				reason,
				expires,
				expStr,
				issuer,
				-1,
				true
			)

			return {
				success = true,
				Name = tPlayer:GetData("Name"),
				AccountID = tPlayer:GetData("AccountID"),
				expires = expires,
				reason = reason,
				banStr = banStr,
			}
		end

		COMPONENTS.Logger:Info(
			"Punishment",
			banStr,
			{ console = true, file = true, database = true, discord = { embed = true, type = "info" } },
			{
				player = tPlayer:GetData("Name"),
				identifier = tPlayer:GetData("Identifier"),
				reason = reason,
				issuer = issuer,
				expires = expStr,
			}
		)
	end,
	AccountID = function(self, aId, expires, reason, issuer)
		local iPlayer = COMPONENTS.Fetch:Source(issuer)
		if not iPlayer then
			return {
				success = false,
			}
		end

		if iPlayer:GetData("AccountID") == tonumber(aid) then
			return {
				success = false,
				message = "Cannot Ban Yourself!",
			}
		end

		local tPlayer = COMPONENTS.Fetch:PlayerData("AccountID", tonumber(aId))

		issuer = string.format("%s [%s]", iPlayer:GetData("Name"), iPlayer:GetData("AccountID"))

		local dbf = false
		if tPlayer == nil then
			tPlayer = COMPONENTS.Fetch:Website("account", tonumber(aId))
			dbf = true
		end

		local bannedPlayer = tonumber(aId)

		local expStr = "Never"
		if expires ~= -1 then
			expires = (os.time() + ((60 * 60 * 24) * expires))
			expStr = os.date("%Y-%m-%d at %I:%M:%S %p", expires)
		end

		local banStr = string.format(
			"%s (Account: %s) Was Permanently Banned By %s. Reason: %s",
			tPlayer and tPlayer:GetData("Name") or "Unknown",
			tPlayer and tPlayer:GetData("AccountID") or bannedPlayer,
			issuer,
			reason
		)

		if expires ~= -1 then
			banStr = string.format(
				"%s (Account: %s) Was Banned By %s Until %s. Reason: %s",
				(tPlayer and tPlayer:GetData("Name") or "Unknown"),
				(tPlayer and tPlayer:GetData("AccountID") or bannedPlayer),
				issuer,
				expStr,
				reason
			)
		end

		if tPlayer == nil then
			if
				COMPONENTS.Punishment.Actions:Ban(
					nil,
					tonumber(aId),
					nil,
					bannedPlayer,
					{},
					reason,
					expires,
					expStr,
					issuer,
					iPlayer:GetData("AccountID"),
					false
				)
			then
				COMPONENTS.Logger:Info(
					"Punishment",
					banStr,
					{ console = true, file = true, database = true, discord = { embed = true, type = "info" } },
					{
						player = bannedPlayer,
						account = tonumber(aId),
						reason = reason,
						issuer = issuer,
						expires = expStr,
					}
				)

				return {
					success = true,
					AccountID = tonumber(aId),
					reason = reason,
					expires = expires,
					banStr = banStr,
				}
			end
		else
			local tPerms = 0

			if tPlayer:GetData("Source") ~= nil then
				for k, v in ipairs(tPlayer:GetData("Groups")) do
					if COMPONENTS.Config.Groups[tostring(v)].Permission then
						if COMPONENTS.Config.Groups[tostring(v)].Permission.Level > tPerms then
							tPerms = COMPONENTS.Config.Groups[tostring(v)].Permission.Level
						end
					end
				end
			else
				-- Offline so Cannot Get Groups - Just allow devs for now
				tPerms = 99
			end

			if iPlayer.Permissions:GetLevel() <= tPerms then
				return {
					success = false,
					message = "Insufficient Permissions",
				}
			end

			if
				COMPONENTS.Punishment.Actions:Ban(
					tPlayer:GetData("Source"),
					tPlayer:GetData("AccountID"),
					tPlayer:GetData("Identifier"),
					tPlayer:GetData("Name"),
					tPlayer:GetData("Tokens"),
					reason,
					expires,
					expStr,
					issuer,
					iPlayer:GetData("AccountID"),
					false
				)
			then
				COMPONENTS.Logger:Info(
					"Punishment",
					banStr,
					{ console = true, file = true, database = true, discord = { embed = true, type = "info" } },
					{
						player = bannedPlayer,
						account = tPlayer:GetData("AccountID"),
						identifier = tPlayer:GetData("Identifier"),
						reason = reason,
						issuer = issuer,
						expires = expStr,
					}
				)

				local retData = {
					success = true,
					Name = tPlayer:GetData("Name"),
					AccountID = tPlayer:GetData("AccountID"),
					expires = expires,
					reason = reason,
					banStr = banStr,
				}

				CreateThread(function()
					if dbf and tPlayer then
						tPlayer:DeleteStore()
					end
				end)

				return retData
			end
		end
	end,
	Identifier = function(self, identifier, expires, reason, issuer)
		local iPlayer = COMPONENTS.Fetch:Source(issuer)
		if not iPlayer then
			return {
				success = false,
			}
		end

		if iPlayer:GetData("Identifier") == identifier then
			return {
				success = false,
				message = "Cannot Ban Yourself!",
			}
		end

		local tPlayer = COMPONENTS.Fetch:PlayerData("Identifier", identifier)

		issuer = string.format("%s [%s]", iPlayer:GetData("Name"), iPlayer:GetData("AccountID"))

		local dbf = false
		if tPlayer == nil then
			tPlayer = COMPONENTS.Fetch:Website("identifier", identifier)
			dbf = true
		end

		local expStr = "Never"
		if expires ~= -1 then
			expires = (os.time() + ((60 * 60 * 24) * expires))
			expStr = os.date("%Y-%m-%d at %I:%M:%S %p", expires)
		end

		local banStr = string.format(
			"%s (Identifier: %s) Was Permanently Banned By %s. Reason: %s",
			tPlayer and tPlayer:GetData("Name") or "Unknown",
			tPlayer and tPlayer:GetData("Identifier") or identifier,
			issuer,
			reason
		)
		if expires ~= -1 then
			banStr = string.format(
				"%s (Identifier: %s) Was Banned By %s Until %s. Reason: %s",
				tPlayer and tPlayer:GetData("Name") or "Unknown",
				tPlayer and tPlayer:GetData("Identifier") or identifier,
				issuer,
				expStr,
				reason
			)
		end

		if tPlayer == nil then
			if
				COMPONENTS.Punishment.Actions:Ban(
					nil,
					nil,
					identifier,
					bannedPlayer,
					{},
					reason,
					expires,
					expStr,
					issuer,
					iPlayer:GetData("ID"),
					false
				)
			then
				COMPONENTS.Logger:Info(
					"Punishment",
					banStr,
					{ console = true, file = true, database = true, discord = { embed = true, type = "info" } },
					{
						player = identifier,
						identifier = identifier,
						reason = reason,
						issuer = issuer,
						expires = expStr,
					}
				)

				if dbf and tPlayer then
					tPlayer:DeleteStore()
				end

				return {
					success = true,
					Identifier = identifier,
					reason = reason,
					expires = expires,
					banStr = banStr,
				}
			end
		else
			local tPerms = 0

			if tPlayer:GetData("Source") ~= nil then
				for k, v in ipairs(tPlayer:GetData("Groups")) do
					if COMPONENTS.Config.Groups[tostring(v)].Permission then
						if COMPONENTS.Config.Groups[tostring(v)].Permission.Level > tPerms then
							tPerms = COMPONENTS.Config.Groups[tostring(v)].Permission.Level
						end
					end
				end
			else
				for k, v in ipairs(tPlayer:GetData("Groups")) do
					if COMPONENTS.Config.Groups[tostring(v)].Permission then
						if COMPONENTS.Config.Groups[tostring(v)].Permission.Level > tPerms then
							tPerms = COMPONENTS.Config.Groups[tostring(v)].Permission.Level
						end
					end
				end
			end

			if iPlayer.Permissions:GetLevel() <= tPerms then
				return {
					success = false,
					message = "Insufficient Permissions",
				}
			end

			if
				COMPONENTS.Punishment.Actions:Ban(
					tPlayer:GetData("Source"),
					tPlayer:GetData("AccountID"),
					tPlayer:GetData("Identifier"),
					tPlayer:GetData("Name"),
					tPlayer:GetData("Tokens"),
					reason,
					expires,
					expStr,
					issuer,
					false
				)
			then
				COMPONENTS.Logger:Info(
					"Punishment",
					banStr,
					{ console = true, file = true, database = true, discord = { embed = true, type = "info" } },
					{
						player = tPlayer:GetData("Name"),
						account = tPlayer:GetData("AccountID"),
						identifier = tPlayer:GetData("Identifier"),
						reason = reason,
						issuer = issuer,
						expires = expStr,
					}
				)

				local retData = {
					success = true,
					Name = tPlayer:GetData("Name"),
					AccountID = tPlayer:GetData("AccountID"),
					Identifier = tPlayer:GetData("Identifier"),
					expires = expires,
					reason = reason,
					banStr = banStr,
				}

				if dbf and tPlayer then
					tPlayer:DeleteStore()
				end

				return retData
			end
		end

		if dbf then
			tPlayer:DeleteStore()
		end
	end,
}

COMPONENTS.Punishment.Actions = {
	Kick = function(self, tSource, reason, issuer)
		DropPlayer(tSource, string.format("Kicked From The Server By %s\nReason: %s", issuer, reason))
	end,
	Ban = function(self, tSource, tAccount, tIdentifier, tName, tTokens, reason, expires, expStr, issuer, issuerId, mask)
		local p = promise.new()

		-- First check if a ban already exists for this account or identifier
		local whereConditions = {}
		local params = {}
		
		if tAccount then
			table.insert(whereConditions, "account = ?")
			table.insert(params, tAccount)
		end
		
		if tIdentifier then
			table.insert(whereConditions, "identifier = ?")
			table.insert(params, tIdentifier)
		end
		
		if #whereConditions == 0 then
			p:resolve(false)
			return Citizen.Await(p)
		end
		
		local whereClause = table.concat(whereConditions, " OR ")
		
		MySQL.query('SELECT * FROM bans WHERE (' .. whereClause .. ') AND active = 1', params, function(success, existingBans)
			if not success then
				COMPONENTS.Logger:Error(
					"Database",
					"[^8Error^7] Error in Ban query: " .. tostring(existingBans),
					{ console = true, file = true, database = true, discord = { embed = true, type = "error" } }
				)
				p:resolve(false)
				return
			end
			
			local tokensJson = json.encode(tTokens or {})
			local banData = {
				account = tAccount,
				identifier = tIdentifier,
				expires = expires,
				reason = reason,
				issuer = issuer,
				active = 1,
				started = os.time(),
				tokens = tokensJson
			}
			
			if existingBans and #existingBans > 0 then
				-- Update existing ban
				local banId = existingBans[1].id
				MySQL.update('UPDATE bans SET account = ?, identifier = ?, expires = ?, reason = ?, issuer = ?, active = 1, started = ?, tokens = ? WHERE id = ?', 
					{tAccount, tIdentifier, expires, reason, issuer, os.time(), tokensJson, banId}, function(updateSuccess)
					if updateSuccess then
						banData.id = banId
						p:resolve(true)
						
						-- Web API call
						local data = COMPONENTS.WebAPI:Request("POST", "admin/ban", {
							account = tAccount,
							identifier = tIdentifier,
							duration = expires,
							issuer = issuerId,
						}, {})
						if data.code ~= 200 then
							COMPONENTS.Logger:Info(
								"Punishment",
								("Failed To Ban Account %s On Website"):format(tAccount),
								{ console = true, discord = { embed = true, type = "error" } }
							)
						end

						if mask then
							reason = "💙 From Pwnzor 🙂"
						end

						if tSource ~= nil then
							if expires ~= -1 then
								DropPlayer(
									tSource,
									string.format(
										"You're Banned, Appeal At https://mythicrp.com/\n\nReason: %s\nExpires: %s\nID: %s",
										reason,
										expStr,
										banId
									)
								)
							else
								DropPlayer(
									tSource,
									string.format(
										"You're Permanently Banned, Appeal At https://mythicrp.com/\n\nReason: %s\nID: %s",
										reason,
										banId
									)
								)
							end
						end
					else
						p:resolve(false)
					end
				end)
			else
				-- Insert new ban
				MySQL.insert('INSERT INTO bans (account, identifier, expires, reason, issuer, active, started, tokens) VALUES (?, ?, ?, ?, ?, 1, ?, ?)', 
					{tAccount, tIdentifier, expires, reason, issuer, os.time(), tokensJson}, function(insertSuccess, insertId)
					if insertSuccess then
						banData.id = insertId
						p:resolve(true)
						
						-- Web API call
						local data = COMPONENTS.WebAPI:Request("POST", "admin/ban", {
							account = tAccount,
							identifier = tIdentifier,
							duration = expires,
							issuer = issuerId,
						}, {})
						if data.code ~= 200 then
							COMPONENTS.Logger:Info(
								"Punishment",
								("Failed To Ban Account %s On Website"):format(tAccount),
								{ console = true, discord = { embed = true, type = "error" } }
							)
						end

						if mask then
							reason = "💙 From Pwnzor 🙂"
						end

						if tSource ~= nil then
							if expires ~= -1 then
								DropPlayer(
									tSource,
									string.format(
										"You're Banned, Appeal At https://mythicrp.com/\n\nReason: %s\nExpires: %s\nID: %s",
										reason,
										expStr,
										insertId
									)
								)
							else
								DropPlayer(
									tSource,
									string.format(
										"You're Permanently Banned, Appeal At https://mythicrp.com/\n\nReason: %s\nID: %s",
										reason,
										insertId
									)
								)
							end
						end
					else
						p:resolve(false)
					end
				end)
			end
		end)

		return Citizen.Await(p)
	end,
	Unban = function(self, ids, issuer)
		local _ids = {}
		for k, v in ipairs(ids) do
			MySQL.update('UPDATE bans SET active = 0, unbanned = ? WHERE id = ? AND active = 1', 
				{json.encode({issuer = issuer:GetData("Name"), date = os.time()}), v.id})

			local data = COMPONENTS.WebAPI:Request("DELETE", "admin/ban", {
				type = v.account ~= nil and "account" or "identifier",
				account = v.account,
				identifier = v.identifier,
				issuer = issuer:GetData("AccountID"),
			}, {})
			if data.code ~= 200 then
				success = false
				COMPONENTS.Logger:Info(
					"Punishment",
					("Failed To Revoke Site Ban For Account: %s & Identifier: %s"):format(v.account, v.identifier),
					{ console = true, discord = { embed = true, type = "error" } }
				)
			end

			table.insert(_ids, v.id)
		end

		COMPONENTS.Logger:Info(
			"Punishment",
			string.format("%s Bans Revoked By %s [%s]", #ids, issuer:GetData("Name"), issuer:GetData("AccountID")),
			{ console = true, file = true, database = true, discord = { embed = true, type = "info" } },
			{
				issuer = string.format("%s [%s]", issuer:GetData("Name"), issuer:GetData("AccountID")),
			},
			_ids
		)
	end,
}
