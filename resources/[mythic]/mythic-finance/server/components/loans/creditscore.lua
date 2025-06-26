function GetCharacterCreditScore(stateId)
    local p = promise.new()
    MySQL.query('SELECT Score FROM loans_credit_scores WHERE SID = ? LIMIT 1', {stateId}, function(results)
        if results and #results > 0 then
            p:resolve(results[1].Score)
        else
            p:resolve(_creditScoreConfig.default)
        end
    end)

    local res = Citizen.Await(p)
    return res
end

function SetCharacterCreditScore(stateId, score)
    local p = promise.new()

    if score > _creditScoreConfig.max then
        score = _creditScoreConfig.max
    end

    if score < _creditScoreConfig.min then
        score = _creditScoreConfig.min
    end

    MySQL.insert('INSERT INTO loans_credit_scores (SID, Score) VALUES (?, ?) ON DUPLICATE KEY UPDATE Score = VALUES(Score)', {stateId, score}, function(affectedRows)
        if affectedRows and affectedRows > 0 then
            MySQL.query('SELECT Score FROM loans_credit_scores WHERE SID = ? LIMIT 1', {stateId}, function(results2)
                if results2 and #results2 > 0 then
                    p:resolve(results2[1].Score)
                else
                    p:resolve(score)
                end
            end)
        else
            p:resolve(false)
        end
    end)

    local res = Citizen.Await(p)
    return res
end

function IncreaseCharacterCreditScore(stateId, amount)
    local creditScore = GetCharacterCreditScore(stateId)
    return SetCharacterCreditScore(stateId, math.min(_creditScoreConfig.max, creditScore + amount))
end

function DecreaseCharacterCreditScore(stateId, amount)
    local creditScore = GetCharacterCreditScore(stateId)
    return SetCharacterCreditScore(stateId, math.max(_creditScoreConfig.min, creditScore - amount))
end

AddEventHandler('Job:Server:DutyAdd', function(dutyData, source, stateId)
    if dutyData?.Id and stateId then
        local isBoosted = _creditScoreConfig.boostingJobs[dutyData.Id]
        if isBoosted then
            local creditScore = GetCharacterCreditScore(stateId)
            -- Don't give item them if their credit is or they have more than that credit
            if creditScore >= 150 and creditScore < isBoosted then
                SetCharacterCreditScore(stateId, isBoosted)
            end
        end
    end
end)