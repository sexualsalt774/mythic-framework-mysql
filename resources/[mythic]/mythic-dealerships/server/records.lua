-- Dealership Sale Records

DEALERSHIPS.Records = {
    Get = function(self, dealership)
        if _dealerships[dealership] then
            local p = promise.new()
            MySQL.query('SELECT * FROM dealer_records WHERE dealership = ? ORDER BY time DESC LIMIT 100', {dealership}, function(results)
                if results then
                    p:resolve(results or {})
                else
                    Logger:Error("Dealerships", "Failed to get dealer records", { console = true })
                    p:resolve(false)
                end
            end)
            return Citizen.Await(p)
        end
        return false
    end,
    GetPage = function(self, category, term, dealership, page, perPage)
        if _dealerships[dealership] then
            local p = promise.new()

            local offset = 0
            if page > 1 then
                offset = perPage * (page - 1)
            end

            -- Build WHERE clause for search
            local whereClause = "dealership = ?"
            local params = {dealership}
            
            if #term > 0 then
                whereClause = whereClause .. " AND (JSON_EXTRACT(seller, '$.First') LIKE ? OR JSON_EXTRACT(seller, '$.Last') LIKE ? OR JSON_EXTRACT(buyer, '$.First') LIKE ? OR JSON_EXTRACT(buyer, '$.Last') LIKE ? OR JSON_EXTRACT(vehicle, '$.data.make') LIKE ? OR JSON_EXTRACT(vehicle, '$.data.model') LIKE ?)"
                local searchTerm = "%" .. term .. "%"
                for i = 1, 6 do
                    table.insert(params, searchTerm)
                end
            end

            if category ~= "all" then
                whereClause = whereClause .. " AND JSON_EXTRACT(vehicle, '$.data.category') = ?"
                table.insert(params, category)
            end

            local query = string.format('SELECT * FROM dealer_records WHERE %s ORDER BY time DESC LIMIT %d OFFSET %d', whereClause, perPage + 1, offset)
            
            MySQL.query(query, params, function(results)
                if results then
                    local more = false
                    if #results > perPage then
                        more = true
                        table.remove(results)
                    end

                    p:resolve({
                        data = results,
                        more = more,
                    })
                else
                    Logger:Error("Dealerships", "Failed to get dealer records page", { console = true })
                    p:resolve(false)
                end
            end)
            return Citizen.Await(p)
        end
        return false
    end,
    Create = function(self, dealership, document)
        if type(document) == 'table' then
            document.dealership = dealership
            local p = promise.new()
            MySQL.insert('INSERT INTO dealer_records (dealership, time, type, vehicle, profitPercent, salePrice, dealerProfits, commission, seller, buyer, newQuantity, loan) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                document.dealership,
                document.time,
                document.type,
                json.encode(document.vehicle or {}),
                document.profitPercent,
                document.salePrice,
                document.dealerProfits,
                document.commission,
                json.encode(document.seller or {}),
                json.encode(document.buyer or {}),
                document.newQuantity,
                json.encode(document.loan or {})
            }, function(result)
                if results then
                    p:resolve(true)
                else
                    Logger:Error("Dealerships", "Failed to create dealer record", { console = true })
                    p:resolve(false)
                end
            end)
            return Citizen.Await(p)
        end
        return false
    end,
    CreateBuyBack = function(self, dealership, document)
        if type(document) == 'table' then
            document.dealership = dealership
            local p = promise.new()
            MySQL.insert('INSERT INTO dealer_records_buybacks (dealership, time, type, vehicle, profitPercent, salePrice, dealerProfits, commission, seller, buyer, newQuantity, loan) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                document.dealership,
                document.time,
                document.type,
                json.encode(document.vehicle or {}),
                document.profitPercent,
                document.salePrice,
                document.dealerProfits,
                document.commission,
                json.encode(document.seller or {}),
                json.encode(document.buyer or {}),
                document.newQuantity,
                json.encode(document.loan or {})
            }, function(result)
                if results then
                    p:resolve(true)
                else
                    Logger:Error("Dealerships", "Failed to create dealer buyback record", { console = true })
                    p:resolve(false)
                end
            end)
            return Citizen.Await(p)
        end
        return false
    end,
}