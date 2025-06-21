local _ran = false

_properties = {}
_insideProperties = {}

function doPropertyThings(property)
	property.id = property.id
	property.locked = property.locked or true

	if property.location then
		for k, v in pairs(property.location) do
			if v then
				for k2, v2 in pairs(v) do
					property.location[k][k2] = property.location[k][k2] + 0.0
				end
			end
		end
	end

	return property
end

function Startup()
	if _ran then
		return
	end

	MySQL.query('SELECT * FROM properties', {}, function(results)
		if not results then
			return
		end
		Logger:Trace("Properties", "Loaded ^2" .. #results .. "^7 Properties", { console = true })

		for k, v in ipairs(results) do
			-- Decode JSON fields
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
			
			local p = doPropertyThings(v)

			_properties[v.id] = p
		end
	end)

	_ran = true
end

RegisterNetEvent("Properties:RefreshProperties", function()
    MySQL.query('SELECT * FROM properties', {}, function(results)
        if not results then
            return
        end
        Logger:Warn("Properties", "Loaded ^2" .. #results .. "^7 Properties", { console = true })

        for k, v in ipairs(results) do
            -- Decode JSON fields
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
            
            local p = doPropertyThings(v)
            _properties[v.id] = p
        end
        TriggerLatentClientEvent("Properties:Client:Load", -1, 800000, _properties)

    end)
end)
