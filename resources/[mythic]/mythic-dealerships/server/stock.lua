DEALERSHIPS.Stock = {
    FetchAll = function(self)
        local p = promise.new()
        MySQL.query('SELECT * FROM dealer_stock', {}, function(results)
            if results then
                p:resolve(results)
            else
                p:resolve(false)
            end
        end)
        return Citizen.Await(p)
    end,
    FetchDealer = function(self, dealerId)
        local p = promise.new()
        MySQL.query('SELECT * FROM dealer_stock WHERE dealership = ?', {dealerId}, function(results)
            if results then
                p:resolve(results)
            else
                p:resolve(false)
            end
        end)
        return Citizen.Await(p)
    end,
    FetchDealerVehicle = function(self, dealerId, vehModel)
        local p = promise.new()
        MySQL.query('SELECT * FROM dealer_stock WHERE dealership = ? AND vehicle = ? LIMIT 1', {dealerId, vehModel}, function(results)
            if results and #results > 0 then
                p:resolve(results[1])
            else
                p:resolve(false)
            end
        end)
        return Citizen.Await(p)
    end,
    HasVehicle = function(self, dealerId, vehModel)
        local vehicle = Dealerships.Stock:FetchDealerVehicle(dealerId, vehModel)
        if vehicle and vehicle.quantity > 0 then
            return vehicle.quantity
        else
            return false
        end
    end,
    Add = function(self, dealerId, vehModel, modelType, quantity, vehData)
        vehData = ValidateVehicleData(vehData)
        if _dealerships[dealerId] and vehModel and vehData and quantity > 0 then
            local isStocked = Dealerships.Stock:FetchDealerVehicle(dealerId, vehModel)
            local p = promise.new()
            if isStocked then -- The vehicle is already stocked
                MySQL.update('UPDATE dealer_stock SET quantity = quantity + ?, data = ?, lastStocked = ? WHERE dealership = ? AND vehicle = ?', {
                    quantity, json.encode(vehData), os.time(), dealerId, vehModel
                }, function(affectedRows)
                    if affectedRows and affectedRows > 0 then
                        p:resolve({
                            success = true,
                            existed = true,
                        })
                    else
                        p:resolve(false)
                    end
                end)
            else
                MySQL.insert('INSERT INTO dealer_stock (dealership, vehicle, modelType, data, quantity, lastStocked) VALUES (?, ?, ?, ?, ?, ?)', {
                    dealerId, vehModel, modelType, json.encode(vehData), quantity, os.time()
                }, function(insertId)
                    if insertId then
                        p:resolve({
                            success = true,
                            existed = false,
                        })
                    else
                        p:resolve(false)
                    end
                end)
            end
            return Citizen.Await(p)
        end
        return false
    end,
    Increase = function(self, dealerId, vehModel, amount)
        if _dealerships[dealerId] and vehModel and amount > 0 then
            local isStocked = Dealerships.Stock:FetchDealerVehicle(dealerId, vehModel)
            if isStocked then -- The vehicle is already stocked
                local p = promise.new()
                MySQL.update('UPDATE dealer_stock SET quantity = quantity + ?, lastStocked = ? WHERE dealership = ? AND vehicle = ?', {
                    amount, os.time(), dealerId, vehModel
                }, function(affectedRows)
                    if affectedRows and affectedRows > 0 then
                        p:resolve({ success = true })
                    else
                        p:resolve(false)
                    end
                end)
                return Citizen.Await(p)
            else
                return false
            end
        end
        return false
    end,
    Update = function(self, dealerId, vehModel, setting)
        if _dealerships[dealerId] and vehModel and type(setting) == "table" then
            local isStocked = Dealerships.Stock:FetchDealerVehicle(dealerId, vehModel)
            if isStocked then -- The vehicle is already stocked
                local p = promise.new()
                
                -- Build dynamic UPDATE query
                local setClause = {}
                local values = {}
                for key, value in pairs(setting) do
                    if type(value) == "table" then
                        table.insert(setClause, key .. " = ?")
                        table.insert(values, json.encode(value))
                    else
                        table.insert(setClause, key .. " = ?")
                        table.insert(values, value)
            end
        end
                table.insert(values, dealerId)
                table.insert(values, vehModel)
                
                local query = 'UPDATE dealer_stock SET ' .. table.concat(setClause, ', ') .. ' WHERE dealership = ? AND vehicle = ?'
                
                MySQL.update(query, values, function(affectedRows)
                    if affectedRows and affectedRows > 0 then
                        p:resolve({ success = true })
                    else
                        p:resolve(false)
                    end
                end)
                return Citizen.Await(p)
            else
                return false
            end
        end
        return false
    end,
    Ensure = function(self, dealerId, vehModel, quantity, vehData)
        if _dealerships[dealerId] and vehModel then
            local isStocked = Dealerships.Stock:FetchDealerVehicle(dealerId, vehModel)
            if isStocked then
                local missingQuantity = quantity - isStocked.quantity
                if missingQuantity >= 1 then
                    return Dealerships.Stock:Add(dealerId, vehModel, missingQuantity, vehData)
                end
            else
                return Dealerships.Stock:Add(dealerId, vehModel, quantity, vehData)
            end
        end
        return false
    end,
    Remove = function(self, dealerId, vehModel, quantity)
        if _dealerships[dealerId] and vehModel and quantity > 0 then
            local isStocked = Dealerships.Stock:FetchDealerVehicle(dealerId, vehModel)

            if isStocked and isStocked.quantity > 0 then
                local newQuantity = isStocked.quantity - quantity
                if newQuantity >= 0 then
                    local p = promise.new()
                    MySQL.update('UPDATE dealer_stock SET quantity = ?, lastPurchase = ? WHERE dealership = ? AND vehicle = ?', {
                        newQuantity, os.time(), dealerId, vehModel
                    }, function(affectedRows)
                        if affectedRows and affectedRows > 0 then
                            p:resolve(newQuantity)
                        else
                            p:resolve(false)
                        end
                    end)
                    return Citizen.Await(p)
                end
            end
        end
        return false
    end,
}

local requiredAttributes = {
    make = 'string',
    model = 'string',
    class = 'string',
    category = 'string',
    price = 'number'
}

function ValidateVehicleData(data)
    if type(data) ~= 'table' then
        return false
    end
    for k, v in pairs(requiredAttributes) do
        if data[k] == nil or type(data[k]) ~= v then
            return false
        end
    end

    return data
end
