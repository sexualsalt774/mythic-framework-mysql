_expirationThread = false

_loadedScenes = {}
_hasLoadedScenes = false

_spamCheck = {}

AddEventHandler('Scenes:Shared:DependencyUpdate', RetrieveComponents)
function RetrieveComponents()
	Fetch = exports['mythic-base']:FetchComponent('Fetch')
	Utils = exports['mythic-base']:FetchComponent('Utils')
    Execute = exports['mythic-base']:FetchComponent('Execute')
	Middleware = exports['mythic-base']:FetchComponent('Middleware')
	Callbacks = exports['mythic-base']:FetchComponent('Callbacks')
    Chat = exports['mythic-base']:FetchComponent('Chat')
	Logger = exports['mythic-base']:FetchComponent('Logger')
	Generator = exports['mythic-base']:FetchComponent('Generator')
	Phone = exports['mythic-base']:FetchComponent('Phone')
	Jobs = exports['mythic-base']:FetchComponent('Jobs')
	Vehicles = exports['mythic-base']:FetchComponent('Vehicles')
    Inventory = exports['mythic-base']:FetchComponent('Inventory')
    Scenes = exports['mythic-base']:FetchComponent('Scenes')
end

AddEventHandler('Core:Shared:Ready', function()
	exports['mythic-base']:RequestDependencies('Scenes', {
		'Fetch',
		'Utils',
        'Execute',
        'Chat',
		'Middleware',
		'Callbacks',
		'Logger',
		'Generator',
		'Phone',
		'Jobs',
		'Vehicles',
        'Inventory',
        'Scenes',
	}, function(error)
		if #error > 0 then 
            exports['mythic-base']:FetchComponent('Logger'):Critical('Scenes', 'Failed To Load All Dependencies')
			return
		end
		RetrieveComponents()

        LoadScenesFromDB()
        StartExpirationThread()

        Callbacks:RegisterServerCallback('Scenes:Create', function(source, data, cb)
            local player = Fetch:Source(source)
            local timeStamp = GetGameTimer()

            if _spamCheck[source] and (timeStamp < _spamCheck[source]) and not player.Permissions:IsStaff() then
                return cb(false)
            end

            if player and data.scene and data.data then
                local wasCreated = Scenes:Create(data.scene, data.data.staff and player.Permissions:IsStaff())
                if wasCreated then
                    _spamCheck[source] = timeStamp + 3500
                end
                cb(wasCreated)
            end
        end)

        Callbacks:RegisterServerCallback('Scenes:Delete', function(source, sceneId, cb)
            local player = Fetch:Source(source)
            local scene = _loadedScenes[sceneId]
            local timeStamp = GetGameTimer()

            if _spamCheck[source] and (timeStamp < _spamCheck[source]) and not player.Permissions:IsStaff() then
                return cb(false)
            end

            if scene and player then
                if scene.staff and not player.Permissions:IsStaff() then
                    return cb(false, true)
                end

                _spamCheck[source] = timeStamp + 5000

                cb(Scenes:Delete(sceneId))
            else
                cb(false)
            end
        end)

        Callbacks:RegisterServerCallback('Scenes:CanEdit', function(source, sceneId, cb)
            local player = Fetch:Source(source)
            local scene = _loadedScenes[sceneId]
            local timeStamp = GetGameTimer()

            if _spamCheck[source] and (timeStamp < _spamCheck[source]) and not player.Permissions:IsStaff() then
                return cb(false, false)
            end

            if scene and player then
                if scene.staff and not player.Permissions:IsStaff() then
                    return cb(false, player.Permissions:IsStaff())
                end

                _spamCheck[source] = timeStamp + 5000

                cb(true, player.Permissions:IsStaff())
            else
                cb(false, false)
            end
        end)

        Callbacks:RegisterServerCallback('Scenes:Edit', function(source, data, cb)
            local player = Fetch:Source(source)
            local scene = _loadedScenes[data.id]
            local timeStamp = GetGameTimer()

            if _spamCheck[source] and (timeStamp < _spamCheck[source]) and not player.Permissions:IsStaff() then
                return cb(false)
            end

            if scene and player then
                _spamCheck[source] = timeStamp + 5000

                cb(Scenes:Edit(data.id, data.scene, player.Permissions:IsStaff()))
            else
                cb(false)
            end
        end)

        Middleware:Add('Characters:Spawning', function(source)
            TriggerClientEvent('Scenes:Client:RecieveScenes', source, _loadedScenes)
        end, 5)

        Middleware:Add("playerDropped", function(source, message)
            _spamCheck[source] = nil
        end, 5)

        Chat:RegisterCommand('scene', function(source, args, rawCommand)
            TriggerClientEvent('Scenes:Client:Creation', source, args)
        end, {
            help = 'Create a Scene (Look Where You Want to Place)',
        })

        Chat:RegisterStaffCommand('scenestaff', function(source, args, rawCommand)
            TriggerClientEvent('Scenes:Client:Creation', source, args, true)
        end, {
            help = '[Staff] Create a Scene (Look Where You Want to Place)',
        })

        Chat:RegisterCommand('scenedelete', function(source, args, rawCommand)
            TriggerClientEvent('Scenes:Client:Deletion', source)
        end, {
            help = 'Delete a Scene (Look at Scene You Want to Delete)',
        })

        Chat:RegisterCommand('sceneedit', function(source, args, rawCommand)
            TriggerClientEvent('Scenes:Client:StartEdit', source)
        end, {
            help = 'Delete a Scene (Look at Scene You Want to Delete)',
        })
	end)
end)

_SCENES = {
    Create = function(self, scene, isStaff)
        if scene and scene.coords then
            scene.coords = {
                x = scene.coords.x,
                y = scene.coords.y,
                z = scene.coords.z
            }

            if not scene.length and not isStaff then
                return false
            end

            if scene.length then
                if scene.length > 24 then
                    scene.length = 24
                elseif scene.length < 1 then
                    scene.length = 1
                end

                scene.expires = os.time() + (3600 * scene.length)
                scene.staff = false
            else
                scene.expires = false
                scene.staff = true
            end

            if type(scene.distance) ~= 'number' or scene.distance > 10.0 or scene.distance < 1.0 then
                scene.distance = 7.5
            end

            local p = promise.new()
            MySQL.insert('INSERT INTO scenes (x, y, z, route, text, font, size, outline, text_color_r, text_color_g, text_color_b, background_type, background_opacity, background_color_r, background_color_g, background_color_b, background_h, background_w, background_x, background_y, background_rotation, length, distance, expires, staff) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                scene.coords.x, scene.coords.y, scene.coords.z,
                scene.route or 1,
                scene.text and scene.text.text or '',
                scene.text and scene.text.font or 1,
                scene.text and scene.text.size or 0.35,
                scene.text and (scene.text.outline and 1 or 0),
                scene.text and scene.text.color and scene.text.color.r or 255,
                scene.text and scene.text.color and scene.text.color.g or 255,
                scene.text and scene.text.color and scene.text.color.b or 255,
                scene.background and scene.background.type or 0,
                scene.background and scene.background.opacity or 255,
                scene.background and scene.background.color and scene.background.color.r or 255,
                scene.background and scene.background.color and scene.background.color.g or 255,
                scene.background and scene.background.color and scene.background.color.b or 255,
                scene.background and scene.background.h or 0.02,
                scene.background and scene.background.w or 0.0,
                scene.background and scene.background.x or 0.0,
                scene.background and scene.background.y or 0.0,
                scene.background and scene.background.rotation or 0.0,
                scene.length or 6,
                scene.distance or 7.5,
                scene.expires or nil,
                scene.staff and 1 or 0
            }, function(id)
                if id then
                    scene._id = id
                    p:resolve(scene)
                    _loadedScenes[scene._id] = scene
                    TriggerClientEvent('Scenes:Client:AddScene', -1, scene._id, scene)
                else
                    p:resolve(false)
                end
            end)
            return Citizen.Await(p)
        end
    end,
    Edit = function(self, id, newData, isStaff)
        if newData and newData.coords then
            newData.coords = {
                x = newData.coords.x,
                y = newData.coords.y,
                z = newData.coords.z
            }

            if not newData.length and not isStaff then
                return false
            end

            if newData.length then
                if newData.length > 24 then
                    newData.length = 24
                elseif newData.length < 1 then
                    newData.length = 1
                end

                newData.expires = os.time() + (3600 * newData.length)
                newData.staff = false
            else
                newData.expires = false
                newData.staff = true
            end

            if type(newData.distance) ~= 'number' or newData.distance > 10.0 or newData.distance < 1.0 then
                newData.distance = 7.5
            end

            local p = promise.new()
            MySQL.update('UPDATE scenes SET x = ?, y = ?, z = ?, route = ?, text = ?, font = ?, size = ?, outline = ?, text_color_r = ?, text_color_g = ?, text_color_b = ?, background_type = ?, background_opacity = ?, background_color_r = ?, background_color_g = ?, background_color_b = ?, background_h = ?, background_w = ?, background_x = ?, background_y = ?, background_rotation = ?, length = ?, distance = ?, expires = ?, staff = ? WHERE id = ?', {
                newData.coords.x, newData.coords.y, newData.coords.z,
                newData.route or 1,
                newData.text and newData.text.text or '',
                newData.text and newData.text.font or 1,
                newData.text and newData.text.size or 0.35,
                newData.text and (newData.text.outline and 1 or 0),
                newData.text and newData.text.color and newData.text.color.r or 255,
                newData.text and newData.text.color and newData.text.color.g or 255,
                newData.text and newData.text.color and newData.text.color.b or 255,
                newData.background and newData.background.type or 0,
                newData.background and newData.background.opacity or 255,
                newData.background and newData.background.color and newData.background.color.r or 255,
                newData.background and newData.background.color and newData.background.color.g or 255,
                newData.background and newData.background.color and newData.background.color.b or 255,
                newData.background and newData.background.h or 0.02,
                newData.background and newData.background.w or 0.0,
                newData.background and newData.background.x or 0.0,
                newData.background and newData.background.y or 0.0,
                newData.background and newData.background.rotation or 0.0,
                newData.length or 6,
                newData.distance or 7.5,
                newData.expires or nil,
                newData.staff and 1 or 0,
                id
            }, function(affectedRows)
                if affectedRows and affectedRows > 0 then
                    newData._id = id
                    p:resolve(newData)
                    _loadedScenes[id] = newData
                    TriggerClientEvent('Scenes:Client:AddScene', -1, newData._id, newData)
                else
                    p:resolve(false)
                end
            end)
            return Citizen.Await(p)
        end
    end,
    Delete = function(self, id)
        local p = promise.new()
        MySQL.update('DELETE FROM scenes WHERE id = ?', {id}, function(affectedRows)
            if affectedRows and affectedRows > 0 then
                p:resolve(true)
                if _loadedScenes[id] then
                    _loadedScenes[id] = nil
                    TriggerClientEvent('Scenes:Client:RemoveScene', -1, id)
                end
            else
                p:resolve(false)
            end
        end)
        return Citizen.Await(p)
    end,
}

AddEventHandler('Proxy:Shared:RegisterReady', function()
    exports['mythic-base']:RegisterComponent('Scenes', _SCENES)
end)

function DeleteExpiredScenes(deleteRouted)
    local p = promise.new()
    local query = ''
    local params = {}
    if deleteRouted then
        query = 'DELETE FROM scenes WHERE (staff = 0 AND expires <= ?) OR (route <> 0)'
        table.insert(params, os.time())
    else
        query = 'DELETE FROM scenes WHERE staff = 0 AND expires <= ?'
        table.insert(params, os.time())
    end
    MySQL.update(query, params, function(affectedRows)
        if affectedRows then
            p:resolve(affectedRows)
        else
            p:resolve(false)
        end
    end)
    return Citizen.Await(p)
end

function LoadScenesFromDB()
    if not _hasLoadedScenes then
        _hasLoadedScenes = true
        DeleteExpiredScenes(true)
        MySQL.query('SELECT * FROM scenes', {}, function(results)
            if results and #results > 0 then
                for k, v in ipairs(results) do
                    -- reconstruct nested tables
                    v.coords = { x = v.x, y = v.y, z = v.z }
                    v.text = {
                        text = v.text,
                        font = v.font,
                        size = v.size,
                        outline = v.outline == 1,
                        color = { r = v.text_color_r, g = v.text_color_g, b = v.text_color_b }
                    }
                    v.background = {
                        type = v.background_type,
                        opacity = v.background_opacity,
                        color = { r = v.background_color_r, g = v.background_color_g, b = v.background_color_b },
                        h = v.background_h,
                        w = v.background_w,
                        x = v.background_x,
                        y = v.background_y,
                        rotation = v.background_rotation
                    }
                    v._id = v.id
                    _loadedScenes[v._id] = v
                end
            end
        end)
    end
end

function StartExpirationThread()
    if not _expirationThread then
        _expirationThread = true
        CreateThread(function()
            while true do
                Wait(60 * 1000 * 30)
                if _hasLoadedScenes then
                    local deleteScenes = {}
                    local timeStamp = os.time()
                    for k, v in pairs(_loadedScenes) do
                        if v.expires and v.expires ~= 0 and timeStamp >= v.expires then
                            if Scenes:Delete(v._id) then
                                table.insert(deleteScenes, v._id)
                            end
                        end
                    end
                    TriggerClientEvent('Scenes:Client:RemoveScenes', -1, deleteScenes)
                end
            end
        end)
    end
end