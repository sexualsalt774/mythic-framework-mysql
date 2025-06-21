local _selling = {}
local _pendingLoanAccept = {}

local govCut = 5
local commissionCut = 5
local companyCut = 10

AddEventHandler("Phone:Server:RegisterCallbacks", function()
	Callbacks:RegisterServerCallback("Phone:Dyn8:Search", function(source, data, cb)
		local char = Fetch:Source(source):GetData("Character")
		if char then
			local whereClause = "label LIKE ?"
			local params = {"%" .. data .. "%"}

			if Player(source).state.onDuty == 'realestate' then
				-- Real estate agents can see all properties
			else
				-- Regular users can only see unsold properties
				whereClause = whereClause .. " AND sold = 0"
			end

			MySQL.query('SELECT * FROM properties WHERE ' .. whereClause .. ' LIMIT 80', params, function(results)
				if not results then
					cb(false)
					return
				end
				
				-- Decode JSON fields for each result
				for k, v in pairs(results) do
					if v.location then
						v.location = json.decode(v.location)
					end
					if v.upgrades then
						v.upgrades = json.decode(v.upgrades)
					end
					if v.data then
						v.data = json.decode(v.data)
					end
					if v.keys then
						v.keys = json.decode(v.keys)
					end
					if v.owner then
						v.owner = json.decode(v.owner)
					end
				end
				
				cb(results)
			end)
		else
			cb(false)
		end
	end)
end)



