RegisterServerEvent('Characters:Server:Spawning', function()
    Middleware:TriggerEvent('Characters:Spawning', source)
end)

RegisterServerEvent('Ped:LeaveCreator', function()
    local plyr = Fetch:Source(source)
    if plyr ~= nil then
        local char = plyr:GetData('Character')
        if char ~= nil then
            if char:GetData('New') then
                Logger:Info("Characters", "Setting New to false for character: " .. char:GetData("SID"), { console = true })
                char:SetData('New', false)
                -- Force immediate database save
                StoreData(source)
            end
        end
    end
end)