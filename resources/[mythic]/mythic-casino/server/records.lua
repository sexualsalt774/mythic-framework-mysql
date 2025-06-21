function UpdateCharacterCasinoStats(source, statType, isWin, amount)
    local plyr = Fetch:Source(source)
    if plyr then
        local char = plyr:GetData("Character")
        if char then
            local p = promise.new()

            -- Get current stats first
            MySQL.query('SELECT * FROM casino_statistics WHERE SID = ?', {char:GetData("SID")}, function(success, results)
                if success then
                    local currentStats = results[1] or {}
                    local stats = currentStats.stats or {}
                    
                    -- Update the specific stat type
                    if not stats[statType] then
                        stats[statType] = {}
                    end
                    table.insert(stats[statType], {
                        Win = isWin,
                        Amount = amount,
                    })

                    -- Update totals
                    local totalAmountWon = (currentStats.TotalAmountWon or 0)
                    local totalAmountLost = (currentStats.TotalAmountLost or 0)
                    local amountWon = currentStats.AmountWon or {}
                    local amountLost = currentStats.AmountLost or {}

                    if isWin then
                        totalAmountWon = totalAmountWon + amount
                        amountWon[statType] = (amountWon[statType] or 0) + amount
                    else
                        totalAmountLost = totalAmountLost + amount
                        amountLost[statType] = (amountLost[statType] or 0) + amount
                    end

                    -- Insert or update
                    MySQL.insert('INSERT INTO casino_statistics (SID, stats, TotalAmountWon, TotalAmountLost, AmountWon, AmountLost) VALUES (?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE stats = ?, TotalAmountWon = ?, TotalAmountLost = ?, AmountWon = ?, AmountLost = ?', {
                        char:GetData("SID"),
                        json.encode(stats),
                        totalAmountWon,
                        totalAmountLost,
                        json.encode(amountWon),
                        json.encode(amountLost),
                        json.encode(stats),
                        totalAmountWon,
                        totalAmountLost,
                        json.encode(amountWon),
                        json.encode(amountLost)
                    }, function(insertSuccess, result)
                        if insertSuccess then
                            p:resolve(true)
                        else
                            Logger:Error("Casino", "Failed to update casino statistics", { console = true })
                            p:resolve(false)
                        end
                    end)
                else
                    Logger:Error("Casino", "Failed to get casino statistics", { console = true })
                    p:resolve(false)
                end
            end)

            local res = Citizen.Await(p)
            return res
        end
    end
    return false
end

function SaveCasinoBigWin(source, machine, prize, data)
    local plyr = Fetch:Source(source)
    if plyr then
        local char = plyr:GetData("Character")
        if char then
            local p = promise.new()

            MySQL.insert('INSERT INTO casino_bigwins (Type, Time, Winner, Prize, MetaData) VALUES (?, ?, ?, ?, ?)', {
                machine,
                os.time(),
                json.encode({
                    SID = char:GetData("SID"),
                    First = char:GetData("First"),
                    Last = char:GetData("Last"),
                    ID = char:GetData("ID"),
                }),
                prize,
                json.encode(data or {})
            }, function(success, result)
                if success then
                    p:resolve(true)
                else
                    Logger:Error("Casino", "Failed to save casino big win", { console = true })
                    p:resolve(false)
                end
            end)

            local res = Citizen.Await(p)
            return res
        end
    end
    return false
end