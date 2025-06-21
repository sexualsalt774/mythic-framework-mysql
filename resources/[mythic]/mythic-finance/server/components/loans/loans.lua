local _ranStartup = false

function RunLoanStartup()
    if _ranStartup then return end
    _ranStartup = true

    MySQL.query('SELECT COUNT(*) as count FROM loans WHERE Remaining > 0', {}, function(success, results)
        if success and results and #results > 0 then
            Logger:Trace('Loans', 'Loaded ^2' .. results[1].count .. '^7 Active Loans')
        end
    end)
end

AddEventHandler('Finance:Server:Startup', function()
    RunLoanStartup()
    RegisterLoanCallbacks()

    CreateLoanTasks()
end)

function CreateLoanTasks()
    Tasks:Register('loan_payment', 60, function()
    --RegisterCommand('testloans', function()
        local TASK_RUN_TIMESTAMP = os.time()

        -- First, update loans that are due now
        MySQL.update('UPDATE loans SET InterestRate = InterestRate + ?, LastMissedPayment = ?, MissedPayments = MissedPayments + 1, TotalMissedPayments = TotalMissedPayments + 1, NextPayment = NextPayment + ?, Remaining = Remaining + (Total * ? / 100) WHERE NextPayment > 0 AND NextPayment <= ? AND Defaulted = 0 AND Remaining >= 0', {
            _loanConfig.missedPayments.interestIncrease,
            TASK_RUN_TIMESTAMP,
            _loanConfig.paymentInterval,
            _loanConfig.missedPayments.charge,
            TASK_RUN_TIMESTAMP
        }, function(success, results)
            if success then
                -- Get All the Loans that now need to be defaulted and notify/seize
                MySQL.query('SELECT * FROM loans WHERE MissedPayments >= MissablePayments AND Defaulted = 0', {}, function(success, results)
                    if success and #results > 0 then
                        local updatingAssets = {}

                        for k, v in ipairs(results) do
                            table.insert(updatingAssets, v.AssetIdentifier)
                        end

                        MySQL.update('UPDATE loans SET Defaulted = 1 WHERE AssetIdentifier IN (' .. string.rep('?,', #updatingAssets - 1) .. '?)', updatingAssets, function(success, updated)
                            if success then
                                Logger:Info('Loans', '^2' .. #results .. '^7 Loans Have Just Been Defaulted')
                                for k, v in ipairs(results) do
                                    if v.SID then
                                        DecreaseCharacterCreditScore(v.SID, _creditScoreConfig.removal.defaultedLoan)
                                        local onlineChar = Fetch:SID(v.SID)
                                        if onlineChar then
                                            SendDefaultedLoanNotification(onlineChar:GetData('Source'), v)
                                        end
                                    end

                                    if v.AssetIdentifier then
                                        if v.Type == 'vehicle' then
                                            Vehicles.Owned:Seize(v.AssetIdentifier, true)
                                        elseif v.Type == 'property' then
                                            -- TODO: PROPERTY TEMP SEIZURE
                                        end
                                    end
                                end
                            end
                        end)
                    end
                end)

                -- Notify if someone just missed a payment.
                MySQL.query('SELECT * FROM loans WHERE MissedPayments < MissablePayments AND Defaulted = 0 AND LastMissedPayment = ?', {TASK_RUN_TIMESTAMP}, function(success, results)
                    if success and #results > 0 then
                        Logger:Info('Loans', '^2' .. #results .. '^7 Loan Payments Were Just Missed')
                        for k, v in ipairs(results) do
                            if v.SID then
                                DecreaseCharacterCreditScore(v.SID, _creditScoreConfig.removal.missedLoanPayment)

                                local onlineChar = Fetch:SID(v.SID)
                                if onlineChar then
                                    SendMissedLoanNotification(onlineChar:GetData('Source'), v)
                                end
                            end
                        end
                    end
                end)
            end
        end)
    end)

    Tasks:Register('loan_reminder', 120, function()
        local TASK_RUN_TIMESTAMP = os.time()
        -- Get All Loans That are Due Soon
        MySQL.query('SELECT * FROM loans WHERE Remaining > 0 AND Defaulted = 0 AND (NextPayment > 0 AND NextPayment <= ? OR MissedPayments > 0)', {TASK_RUN_TIMESTAMP + (60 * 60 * 6)}, function(success, results)
            print("this might hitch the server (loan_reminder task)")
            if success and #results > 0 then
                for k, v in ipairs(results) do
                    if v.SID then
                        local onlineChar = Fetch:SID(v.SID)
                        if onlineChar then
                            Phone.Notification:Add(onlineChar:GetData("Source"), "Loan Payment Due", "You have a loan payment that is due very soon.", os.time() * 1000, 7500, "loans", {})
                        end

                        Wait(100)
                    end
                end
            end
        end)
    end)
end

function SendMissedLoanNotification(source, loanData)
    Phone.Notification:Add(source, "Loan Payment Missed", "You just missed a loan payment on one of your loans.", os.time() * 1000, 7500, "loans", {})
end

function SendDefaultedLoanNotification(source, loanData)
    Phone.Notification:Add(source, "Loan Defaulted", "One of your loans just got defaulted and the assets are going to be seized.", os.time() * 1000, 7500, "loans", {})
end

local typeNames = {
    vehicle = 'Vehicle Loan',
    property = 'Property Loan',
}

function GetLoanTypeName(type)
    return typeNames[type]
end