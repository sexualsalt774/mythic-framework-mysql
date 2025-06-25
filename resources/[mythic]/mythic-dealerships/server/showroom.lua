local showroomsLoaded = false

DEALERSHIPS.Showroom = {
    Load = function(self)
        local p = promise.new()
        MySQL.query('SELECT * FROM dealer_showrooms', {}, function(results)
            local showRoomData = {}
            if results and #results > 0 then
                for k, v in ipairs(results) do
                    if _dealerships[v.dealership] then
                        -- Decode JSON showroom data if it exists
                        if v.showroom and type(v.showroom) == "string" then
                            local decoded = json.decode(v.showroom)
                            if decoded then
                                showRoomData[v.dealership] = decoded
                            else
                                showRoomData[v.dealership] = {}
                            end
                        else
                            showRoomData[v.dealership] = v.showroom or {}
                        end
                    end
                end

                GlobalState.DealershipShowrooms = showRoomData
                showroomsLoaded = true
            end
            p:resolve(results)
        end)
        return Citizen.Await(p)
    end,

    Update = function(self, dealershipId, showroom)
        if _dealerships[dealershipId] then
            if type(showroom) ~= 'table' then 
                showroom = {} 
            end
            
            local p = promise.new()
            MySQL.insert('INSERT INTO dealer_showrooms (dealership, showroom) VALUES (?, ?) ON DUPLICATE KEY UPDATE showroom = ?', {
                dealershipId,
                json.encode(showroom),
                json.encode(showroom)
            }, function(insertId)
                if insertId then
                    local currentData = GlobalState.DealershipShowrooms
                    currentData[dealershipId] = showroom
                    GlobalState.DealershipShowrooms = currentData
                    TriggerClientEvent('Dealerships:Client:ShowroomUpdate', -1, dealershipId)
                    p:resolve(showroom)
                else
                    Logger:Error("Dealerships", "Failed to update dealer showroom", { console = true })
                    p:resolve(false)
                end
            end)
            return Citizen.Await(p)
        end
        return false
    end,
    
    UpdatePos = function(self, dealershipId, position, vehicleData)
        if _dealerships[dealershipId] and (#_dealerships[dealershipId].showroom >= position) then
            position = tostring(position)
            local showroomData = GlobalState.DealershipShowrooms[dealershipId] or {}
            showroomData[position] = type(vehicleData) == 'table' and vehicleData or nil

            return Dealerships.Showroom:Update(dealershipId, showroomData)
        end
        return false
    end,
}