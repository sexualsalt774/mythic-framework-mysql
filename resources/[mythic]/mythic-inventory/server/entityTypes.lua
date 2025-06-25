AddEventHandler('Proxy:Shared:RegisterReady', function()
    exports['mythic-base']:RegisterComponent('EntityTypes', ENTITYTYPES)
end)

-- This code seems completely unused now? did mythic used to do this in the db? probably


ENTITYTYPES = {
    Get = function(self, cb)
        MySQL.query("SELECT * FROM entitytypes", {}, function(results)
            if results then
                cb(results)
            else
                cb({})
            end
        end)
    end,
    GetID = function(self, id, cb)
        cb(LoadedEntitys[id])
    end
}