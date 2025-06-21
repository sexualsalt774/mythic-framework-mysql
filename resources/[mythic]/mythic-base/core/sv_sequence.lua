local _cachedSeq = {}
-- That was edited and never finished with the testing

COMPONENTS.Sequence = {
    Get = function(self, key)
        if _cachedSeq[key] ~= nil then
            _cachedSeq[key].value += 1
            _cachedSeq[key].dirty = true
            return _cachedSeq[key].value
        else
            _cachedSeq[key] = {
                value = 1,
                dirty = true,
            }
            return 1
        end
    end,

    Save = function(self)
        local queries = {}
        for k, v in pairs(_cachedSeq) do
            if v.dirty then
                table.insert(queries, {
                    query = "INSERT INTO sequence (`key`, current) VALUES(?, ?) ON DUPLICATE KEY UPDATE current = VALUES(current)",
                    values = {
                        k,
                        v.value,
                    },
                })

                v.dirty = false
            end
        end

        MySQL.transaction(queries)
    end,
}

AddEventHandler("Core:Server:StartupReady", function()
    MySQL.query("SELECT `key`, current FROM sequence", {}, function(results)
        if results then
            for _, row in ipairs(results) do
                _cachedSeq[row.key] = {
                    value = row.current,
                    dirty = false,
                }
            end
            COMPONENTS.Logger:Trace("Sequence", string.format("Loaded %d sequences from database", #results))
        end
    end)
end)

AddEventHandler("Core:Shared:Ready", function()
    COMPONENTS.Tasks:Register("sequence_save", 1, function()
        COMPONENTS.Sequence:Save()
    end)
end)

AddEventHandler("Core:Server:ForceSave", function()
    COMPONENTS.Sequence:Save()
end)