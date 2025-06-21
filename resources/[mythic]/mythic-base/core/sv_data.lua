local _data = {}
local _inserting = {}

-- Untested will break because theres so many missing default tables

COMPONENTS.Default = {
    _required = { 'Add' },
    _name = { 'base' },
    _protected = true,
    Add = function(self, collection, date, data)
        CreateThread(function()
            -- Prevents doing this operation multiple times because earlier
            -- Calls haven't finished yet
            while _inserting[collection] ~= nil do Wait(10) end

            for k, v in ipairs(data) do
                v.default = true
            end

            _inserting[collection] = true
            
            -- Check if we need to update defaults
            MySQL.query('SELECT date FROM defaults WHERE collection = ?', {collection}, function(results)
                if not results then 
                    COMPONENTS.Logger:Error('Data', ('Failed To Retrieve Details For %s Default Data'):format(collection)) 
                    _inserting[collection] = nil 
                    return 
                end

                local shouldUpdate = #results == 0 or results[1].date < date
                
                if shouldUpdate then
                    -- Delete existing default data from the collection
                    MySQL.query('DELETE FROM ' .. collection .. ' WHERE `default` = 1', {}, function(deleteSuccess)
                        if not deleteSuccess then 
                            COMPONENTS.Logger:Error('Data', ('Failed To Remove Existing Default Data For %s'):format(collection)) 
                            _inserting[collection] = nil 
                            return 
                        end

                        -- Insert new default data
                        if #data > 0 then
                            local queries = {}
                            for _, doc in ipairs(data) do
                                -- Convert document to SQL insert
                                local columns = {}
                                local values = {}
                                local placeholders = {}
                                
                                for col, val in pairs(doc) do
                                    -- Escape reserved keywords with backticks
                                    local escapedCol = col
                                    if col == 'default' or col == 'key' or col == 'order' or col == 'group' or col == 'index' or col == 'table' then
                                        escapedCol = '`' .. col .. '`'
                                    end
                                    
                                    table.insert(columns, escapedCol)
                                    
                                    -- Handle different data types properly
                                    if type(val) == 'table' then
                                        -- Convert all table values to JSON for MySQL
                                        table.insert(values, json.encode(val))
                                    elseif type(val) == 'boolean' then
                                        table.insert(values, val and 1 or 0)
                                    else
                                        table.insert(values, val)
                                    end
                                    
                                    table.insert(placeholders, '?')
                                end
                                
                                table.insert(queries, {
                                    query = 'INSERT INTO ' .. collection .. ' (' .. table.concat(columns, ', ') .. ') VALUES (' .. table.concat(placeholders, ', ') .. ')',
                                    values = values
                                })
                            end
                            
                            MySQL.transaction(queries, function(insertSuccess)
                                if not insertSuccess then 
                                    COMPONENTS.Logger:Error('Data', ('Failed Adding Default Data For %s'):format(collection)) 
                                    _inserting[collection] = nil 
                                    return 
                                end

                                -- Update or insert default record
                                MySQL.insert('INSERT INTO defaults (collection, date) VALUES (?, ?) ON DUPLICATE KEY UPDATE date = VALUES(date)', {
                                    collection, date
                                }, function(updateSuccess)
                                    _inserting[collection] = nil
                                    if not updateSuccess then 
                                        COMPONENTS.Logger:Error('Data', ('Failed Updating Details For %s Default Data'):format(collection)) 
                                    end
                                end)
                            end)
                        else
                            _inserting[collection] = nil
                        end
                    end)
                else
                    _inserting[collection] = nil
                end
            end)
        end)
    end,
    
    AddAuth = function(self, collection, date, data)
        CreateThread(function()
            -- Prevents doing this operation multiple times because earlier
            -- Calls haven't finished yet
            while _inserting[collection] ~= nil do Wait(10) end

            for k, v in ipairs(data) do
                v.default = true
            end

            _inserting[collection] = true
            
            -- Check if we need to update defaults
            MySQL.query('SELECT date FROM defaults WHERE collection = ?', {collection}, function(results)
                if not results then 
                    COMPONENTS.Logger:Error('Data', ('Failed To Retrieve Details For %s Default Data'):format(collection)) 
                    _inserting[collection] = nil 
                    return 
                end

                local shouldUpdate = #results == 0 or results[1].date < date
                
                if shouldUpdate then
                    -- Delete existing default data from the collection
                    MySQL.query('DELETE FROM ' .. collection .. ' WHERE `default` = 1', {}, function(deleteSuccess)
                        if not deleteSuccess then 
                            COMPONENTS.Logger:Error('Data', ('Failed To Remove Existing Default Data For %s'):format(collection)) 
                            _inserting[collection] = nil 
                            return 
                        end

                        -- Insert new default data
                        if #data > 0 then
                            local queries = {}
                            for _, doc in ipairs(data) do
                                -- Convert document to SQL insert
                                local columns = {}
                                local values = {}
                                local placeholders = {}
                                
                                for col, val in pairs(doc) do
                                    -- Escape reserved keywords with backticks
                                    local escapedCol = col
                                    if col == 'default' or col == 'key' or col == 'order' or col == 'group' or col == 'index' or col == 'table' then
                                        escapedCol = '`' .. col .. '`'
                                    end
                                    
                                    table.insert(columns, escapedCol)
                                    
                                    -- Handle different data types properly
                                    if type(val) == 'table' then
                                        -- Convert all table values to JSON for MySQL
                                        table.insert(values, json.encode(val))
                                    elseif type(val) == 'boolean' then
                                        table.insert(values, val and 1 or 0)
                                    else
                                        table.insert(values, val)
                                    end
                                    
                                    table.insert(placeholders, '?')
                                end
                                
                                table.insert(queries, {
                                    query = 'INSERT INTO ' .. collection .. ' (' .. table.concat(columns, ', ') .. ') VALUES (' .. table.concat(placeholders, ', ') .. ')',
                                    values = values
                                })
                            end
                            
                            MySQL.transaction(queries, function(insertSuccess)
                                if not insertSuccess then 
                                    COMPONENTS.Logger:Error('Data', ('Failed Adding Default Data For %s'):format(collection)) 
                                    _inserting[collection] = nil 
                                    return 
                                end

                                -- Update or insert default record
                                MySQL.insert('INSERT INTO defaults (collection, date) VALUES (?, ?) ON DUPLICATE KEY UPDATE date = VALUES(date)', {
                                    collection, date
                                }, function(updateSuccess)
                                    _inserting[collection] = nil
                                    if not updateSuccess then 
                                        COMPONENTS.Logger:Error('Data', ('Failed Updating Details For %s Default Data'):format(collection)) 
                                    end
                                end)
                            end)
                        else
                            _inserting[collection] = nil
                        end
                    end)
                else
                    _inserting[collection] = nil
                end
            end)
        end)
    end
}