InteractablePeds = {}
InteractableGlobalPeds = {}
InteractableModels = {}

TARGETING.AddPed = function(self, entityId, icon, menuArray, proximity)
    if not entityId then return end
    if not proximity then proximity = 3 end
    if type(menuArray) ~= 'table' then menuArray = {} end

    InteractablePeds[entityId] = {
        type = 'ped',
        ped = entityId,
        icon = icon,
        menu = menuArray,
        proximity = proximity,
    }
end

TARGETING.RemovePed = function(self, entityId)
    InteractablePeds[entityId] = nil
end

TARGETING.AddGlobalPed = function(self, menuArray)
    if type(menuArray) ~= 'table' then return end
    
    if not Utils then Utils = exports['mythic-base']:FetchComponent('Utils') end -- Temp Safety for nil Utils
    
    if Utils:GetTableLength(InteractableGlobalPeds) > 0 then
        for _, option in ipairs(menuArray) do
            table.insert(InteractableGlobalPeds.menu, option)
        end
    else
        InteractableGlobalPeds = {
            type = 'ped',
            icon = "user",
            menu = menuArray,
            proximity = 3.0,
        }
    end
    return Utils:GetTableLength(InteractableGlobalPeds.menu) -- Returns index so you can remove it
end

TARGETING.RemoveGlobalPed = function(self, menuIndex)
    if Utils:GetTableLength(InteractableGlobalPeds) > 0 then
        InteractableGlobalPeds.menu[menuIndex] = nil
    end
end


TARGETING.AddPedModel = function(self, modelId, icon, menuArray, proximity)
    if not modelId then return end
    if not proximity then proximity = 3 end
    if type(menuArray) ~= 'table' then menuArray = {} end

    InteractableModels[modelId] = {
        type = 'ped',
        ped = modelId,
        icon = icon,
        menu = menuArray,
        proximity = proximity,
    }
end

TARGETING.RemovePedModel = function(self, modelId)
    InteractableModels[modelId] = nil
end

function IsPedInteractable(entity)
    if InteractablePeds[entity] then -- Do entities first because they are higher priority
        return InteractablePeds[entity]
    end

    local model = GetEntityModel(entity)
    if InteractableModels[model] then
        return InteractableModels[model]
    end

    if InteractableGlobalPeds and not IsPedAPlayer(entity) then -- Fallback to global ped rules (if defined and not a player)
        return {
            type = InteractableGlobalPeds.type or "ped",
            proximity = InteractableGlobalPeds.proximity or 3.0,
            icon = InteractableGlobalPeds.icon or "user",
            menu = InteractableGlobalPeds.menu
        }
    end
    return false
end
