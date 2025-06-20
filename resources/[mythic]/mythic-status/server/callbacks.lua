function RegisterCallbacks()
    Callbacks:RegisterServerCallback('Status:Get', function(source, data, cb)
        local player = Fetch:Source(source)
        local char = player:GetData('Character')
        if char ~= nil then
            local status = char:GetData('Status')
            if type(status) == 'string' then
                local ok, decoded = pcall(json.decode, status)
                if ok and type(decoded) == 'table' then
                    status = decoded
                else
                    status = {}
                end
            elseif type(status) ~= 'table' then
                status = {}
            end
            if status[data.name] ~= nil then
                cb(status[data.name])
            else
                status[data.name] = data.max
                char:SetData('Status', status)
                cb(data.max)
            end
        else
            cb(data.max)
        end
    end)
end