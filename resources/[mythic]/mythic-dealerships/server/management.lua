_managementData = {}

DEALERSHIPS.Management = {
    LoadData = function(self)
        local p = promise.new()
        MySQL.query('SELECT * FROM dealer_data', {}, function(results)
            if results then
                local fuckface = {}
                if #results > 0 then
                    for k, v in ipairs(results) do
                        if v.dealership then
                            -- Decode JSON data if it exists
                            if v.data and type(v.data) == "string" then
                                local decoded = json.decode(v.data)
                                if decoded then
                                    v = decoded
                                    v.dealership = results[k].dealership -- Preserve dealership ID
                                end
                            end
                            fuckface[v.dealership] = v
                        end
                    end
                end

                for k, v in pairs(_dealerships) do
                    if fuckface[k] then
                        _managementData[k] = fuckface[k]
                    else
                        _managementData[k] = _defaultDealershipSalesData
                    end
                end
                p:resolve(true)
            else
                Logger:Error("Dealerships", "Failed to load dealer data", { console = true })
                p:resolve(false)
            end
        end)
        return Citizen.Await(p)
    end,
    SetData = function(self, dealerId, key, val)
        local data = _managementData[dealerId]
        if data then
            local dealerData = table.copy(data)
            dealerData.dealership = nil
            dealerData._id = nil
            dealerData[key] = val

            local p = promise.new()
            
            -- Convert dealerData to JSON for storage
            local jsonData = json.encode(dealerData)
            
            MySQL.insert('INSERT INTO dealer_data (dealership, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = ?', {
                dealerId,
                jsonData,
                jsonData
            }, function(affectedRows)
                if affectedRows and affectedRows > 0 then
                    _managementData[dealerId] = dealerData
                    p:resolve(_managementData[dealerId])
                else
                    Logger:Error("Dealerships", "Failed to update dealer data", { console = true })
                    p:resolve(false)
                end
            end)
            return Citizen.Await(p)
        end
        return false
    end,
    SetMultipleData = function(self, dealerId, updatingData)
        local data = _managementData[dealerId]
        if data then
            local dealerData = table.copy(data)
            dealerData.dealership = nil
            dealerData._id = nil

            for k, v in pairs(updatingData) do
                dealerData[k] = v
            end

            local p = promise.new()
            
            -- Convert dealerData to JSON for storage
            local jsonData = json.encode(dealerData)
            
            MySQL.insert('INSERT INTO dealer_data (dealership, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = ?', {
                dealerId,
                jsonData,
                jsonData
            }, function(affectedRows)
                if affectedRows and affectedRows > 0 then
                    _managementData[dealerId] = dealerData
                    p:resolve(_managementData[dealerId])
                else
                    Logger:Error("Dealerships", "Failed to update dealer data", { console = true })
                    p:resolve(false)
                end
            end)
            return Citizen.Await(p)
        end
        return false
    end,
    GetAllData = function(self, dealerId)
        return _managementData[dealerId]
    end,
    GetData = function(self, dealerId, key)
        local data = _managementData[dealerId]
        if data then
            return data[key]
        end
        return false
    end,
}