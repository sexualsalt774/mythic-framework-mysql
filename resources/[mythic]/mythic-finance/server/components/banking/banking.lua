function GenerateBankAccountNumber()
    local bankAccount = math.random(100001, 999999)
    while IsAccountNumberInUse(bankAccount) do
        bankAccount = math.random(100001, 999999)
    end

    return bankAccount
end

function IsAccountNumberInUse(account)
    local p = promise.new()

    MySQL.query('SELECT COUNT(*) as count FROM bank_accounts WHERE Account = ?', {account}, function(result)
        if result and result[1] and result[1].count > 0 then
            p:resolve(true)
        else
            p:resolve(false)
        end
    end)

    local res = Citizen.Await(p)
    return res
end

function FindBankAccount(query)
    local p = promise.new()

    MySQL.single("SELECT * FROM bank_accounts WHERE Account = ? OR Name = ? OR Owner = ? LIMIT 1", {
        query.Account or query.Name or query.Owner, query.Account or query.Name or query.Owner, query.Account or query.Name or query.Owner
    }, function(result)
        if result then
            p:resolve(result)
        else
            p:resolve(false)
        end
    end)

    local res = Citizen.Await(p)
    return res
end

function FindBankAccounts(query)
    local p = promise.new()

    MySQL.query("SELECT * FROM bank_accounts WHERE Account = ? OR Name = ? OR Owner = ?", {
        query.Account or query.Name or query.Owner, query.Account or query.Name or query.Owner, query.Account or query.Name or query.Owner
    }, function(results)
        if results and #results > 0 then
            p:resolve(results)
        else
            p:resolve(false)
        end
    end)

    local res = Citizen.Await(p)
    return res
end

function CreateBankAccount(document)
    if type(document) ~= 'table' then return false end
    local p = promise.new()

    if not document.Account then
        document.Account = GenerateBankAccountNumber()
    end

    if not document.Name then
        document.Name = document.Account
    end

    if not document.Balance or document.Balance < 0 then
        document.Balance = 0
    end

    MySQL.insert("INSERT INTO bank_accounts (Account, Name, Balance, Type, Owner, JobAccess, JointOwners) VALUES (?, ?, ?, ?, ?, ?, ?)", {
        document.Account, document.Name, document.Balance, document.Type, document.Owner, json.encode(document.JobAccess or {}), json.encode(document.JointOwners or {})
    }, function(insertId)
        if insertId then
            document.id = insertId
            p:resolve(document)
        else
            p:resolve(false)
        end
    end)

    local res = Citizen.Await(p)
    return res
end

function UpdateBankAccount(searchQuery, updateQuery)
    local p = promise.new()

    MySQL.update("UPDATE bank_accounts SET Balance = ?, Name = ?, JobAccess = ?, JointOwners = ? WHERE Account = ?", {
        updateQuery.Balance or updateQuery['$set'].Balance, 
        updateQuery.Name or updateQuery['$set'].Name, 
        json.encode(updateQuery.JobAccess or updateQuery['$set'].JobAccess or {}), 
        json.encode(updateQuery.JointOwners or updateQuery['$set'].JointOwners or {}),
        searchQuery.Account
    }, function(result)
        if result and result.affectedRows > 0 then
            MySQL.single("SELECT * FROM bank_accounts WHERE Account = ?", {searchQuery.Account}, function(updatedResult)
                p:resolve(updatedResult)
            end)
        else
            p:resolve(false)
        end
    end)

    local res = Citizen.Await(p)
    return res
end

function FindBankAccountTransactions(query)
    local p = promise.new()

    MySQL.query("SELECT * FROM bank_accounts_transactions WHERE Account = ? ORDER BY Timestamp DESC LIMIT 80", {
        query.Account
    }, function(results)
        if results and #results > 0 then
            p:resolve(results)
        else
            p:resolve(false)
        end
    end)

    local res = Citizen.Await(p)
    return res
end

function GetDefaultBankAccountPermissions()
    return {
        MANAGE = 'BANK_ACCOUNT_MANAGE', -- Can Manage The Account (IDK What this does yet)
        WITHDRAW = 'BANK_ACCOUNT_WITHDRAW', -- Can Withdraw/Tranfer money
        DEPOSIT = 'BANK_ACCOUNT_DEPOSIT', -- Can Deposit
        TRANSACTIONS = 'BANK_ACCOUNT_TRANSACTIONS', -- Can View Transaction History
        BILL = 'BANK_ACCOUNT_BILL', -- Can Bill Using This Account
        BALANCE = 'BANK_ACCOUNT_BALANCE',
    }
end

function HasBankAccountPermission(source, accountData, permission, stateId)
    if accountData.Type == 'personal' then
        if accountData.Owner == stateId then
            return true
        end
    elseif accountData.Type == 'personal_savings' then
        if accountData.Owner == stateId then
            return true
        elseif accountData.JointOwners and #accountData.JointOwners > 0 then
            for k, v in ipairs(accountData.JointOwners) do
                if v == stateId and permission ~= 'MANAGE' then
                    return true
                end
            end
        end
    elseif accountData.Type == 'organization' then
        if accountData.JobAccess and #accountData.JobAccess > 0 then
            for k, v in ipairs(accountData.JobAccess) do
                if Jobs.Permissions:HasJob(source, v.Job, v.Workplace, false, false, false, v.Permissions[permission]) then
                    return true
                end
            end
        end
    end
    return false
end