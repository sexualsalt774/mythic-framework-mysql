_boostingContractCount = {}
_boostingQueue = {}
_boostingIds = 0

_boosting = {}

_boostingEvent = false

-- TriggerClientEvent("EmergencyAlerts:Client:TrackerBlip", -1, "police", "boosting-1", "[Police]: S+ Boost (Elgin Ave)", vector3(110, 0, 0), 523, 6, 1.0, true)

AddEventHandler("Laptop:Server:RegisterMiddleware", function()
    Middleware:Add("Characters:Spawning", function(source)
		local char = Fetch:Source(source):GetData("Character")
        if char and char:GetData("BoostingContracts") then
            local contracts = char:GetData("BoostingContracts")

            for k, v in ipairs(contracts) do
                if v.expires < os.time() then
                    table.remove(contracts, k)
                end
            end

            char:SetData("BoostingContracts", contracts)
        end
	end, 5)

    Middleware:Add("playerDropped", function(source, message)
		HandleCharacterLogout(source)
	end, 5)
	Middleware:Add("Characters:Logout", function(source)
		HandleCharacterLogout(source)
	end, 5)
end)

function HandleCharacterLogout(source)
    for k, v in ipairs(_boostingQueue) do
        if v.source == source then
            table.remove(_boostingQueue, k)
            return
        end
    end
end

AddEventHandler("Laptop:Server:RegisterCallbacks", function()
    Callbacks:RegisterServerCallback("Laptop:LSUnderground:Boosting:Admin:CreateContract", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        if char and data?.vehicle and data?.make and data?.model and data?.trackers and data?.price then
            local perm = char:GetData("LaptopPermissions")

            if perm["lsunderground"] and perm["lsunderground"]["admin"] then
                local level = nil
                local cost = tonumber(data.price) or 0

                for k, v in ipairs(_boostingRepToClass) do
                    if v == data.class then
                        level = k
                    end
                end

                if level >= 1 and BOOSTING_VEHICLE_CONFIG[data.class] and cost > 0 then
                    local category = BOOSTING_VEHICLE_CONFIG[data.class]
                    local length = math.random(category.length.min, category.length.max) * 60 * 60
                    local tracker = tonumber(data.trackers) or 0
        
                    cb(Laptop.LSUnderground.Boosting:GiveContract(source, {
                        vehicle = data.vehicle,
                        label = string.format("%s %s", data.make, data.model),
                        make = data.make,
                        model = data.model,
                        class = data.class,
                        classLevel = level,
                        tracker = tracker,
                        rewarded = true,
                    }, {
                        standard = {
                            price = cost,
                            coin = "VRM",
                        }
                    }, length, {
                        skipRep = data.skipRep,
                        payoutOverride = tonumber(data.payoutOverride),
                    }))
                else
                    cb(false)
                end
            else
                cb(false)
            end
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("Laptop:LSUnderground:Boosting:Admin:GetBans", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        if char then
            local perm = char:GetData("LaptopPermissions")

            if perm["lsunderground"] and perm["lsunderground"]["admin"] then
                Database.Game:find({
                    collection = "characters",
                    query = {
                        LSUNDGBan = {
                            ["$exists"] = true,
                        }
                    },
                    options = {
                        projection = {
                            SID = 1,
                            First = 1,
                            Last = 1,
                            Alias = 1,
                            LSUNDGBan = 1,
                        }
                    }

                }, function(success, results)
                    if success and results then
                        local cunts = {}
                        for k, v in ipairs(results) do
                            v.RacingAlias = v.Alias?.redline

                            table.insert(cunts, v)
                        end

                        cb(cunts)
                    else
                        cb(false)
                    end
                end)
            else
                cb(false)
            end
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("Laptop:LSUnderground:Boosting:Admin:Ban", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        if char and data?.SID then
            local perm = char:GetData("LaptopPermissions")

            if perm["lsunderground"] and perm["lsunderground"]["admin"] then
                Database.Game:updateOne({
                    collection = "characters",
                    query = {
                        SID = data.SID,
                    },
                    update = {
                        ["$push"] = {
                            LSUNDGBan = "Boosting",
                        }
                    }
                }, function(success, result)
                    if success and result > 0 then
                        local target = Fetch:SID(data.SID)
                        if target then
                            local targetChar = target:GetData("Character")
                            if targetChar then
                                targetChar:SetData("LSUNDGBan", {
                                    "Boosting",
                                })
                            end
                        end
                        cb(true)
                    else
                        cb(false)
                    end
                end)
            else
                cb(false)
            end
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("Laptop:LSUnderground:Boosting:Admin:Unban", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        if char and data?.SID then
            local perm = char:GetData("LaptopPermissions")

            if perm["lsunderground"] and perm["lsunderground"]["admin"] then
                Database.Game:updateOne({
                    collection = "characters",
                    query = {
                        SID = data.SID,
                    },
                    update = {
                        ["$unset"] = {
                            LSUNDGBan = true,
                        }
                    }
                }, function(success, result)
                    if success and result > 0 then
                        local target = Fetch:SID(data.SID)
                        if target then
                            local targetChar = target:GetData("Character")
                            if targetChar then
                                targetChar:SetData("LSUNDGBan", nil)
                            end
                        end

                        cb(true)
                    else
                        cb(false)
                    end
                end)
            else
                cb(false)
            end
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("Laptop:LSUnderground:Boosting:EnterQueue", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        local team, leader = Laptop.Teams:GetByMemberSource(source)

        if _boostingEvent then
            cb({ message = "Cannot Join Queue Right Now..." })
            return
        end

        if char and team and team.ID and not char:GetData("LSUNDGBan") then
            local perm = char:GetData("LaptopPermissions")
            local alias = char:GetData("Alias").redline

            if alias and #team.Members >= 2 or (perm["lsunderground"] and perm["lsunderground"]["admin"]) then
                local data = {
                    joined = os.time(),
                    source = source,
                    SID = char:GetData("SID"),
                    team = team.ID,
                    admin = perm["lsunderground"] and perm["lsunderground"]["admin"],
                }

                table.insert(_boostingQueue, data)
                TriggerClientEvent("Laptop:Client:SetData", source, "boostingQueue", data)
                cb({
                    success = true
                })
                return
            end
        end
        cb(false)
    end)

    Callbacks:RegisterServerCallback("Laptop:LSUnderground:Boosting:ExitQueue", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        if char then
            for k, v in ipairs(_boostingQueue) do
                if v.source == source then
                    table.remove(_boostingQueue, k)
                    TriggerClientEvent("Laptop:Client:SetData", source, "boostingQueue", nil)
                    cb(true)
                    return
                end
            end
        end
        cb(false)
    end)

    Callbacks:RegisterServerCallback("Laptop:LSUnderground:Boosting:DeclineContract", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        if char then
            local boostingContracts = char:GetData("BoostingContracts") or {}
            local updated = false

            for k, v in ipairs(boostingContracts) do
                if v.id == data.id then
                    table.remove(boostingContracts, k)

                    updated = true
                    break
                end
            end

            if updated then
                char:SetData("BoostingContracts", boostingContracts)
                cb(true)
            else
                cb(false)
            end
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("Laptop:LSUnderground:Boosting:TransferContract", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        if char and data?.alias then
            local boostingContracts = char:GetData("BoostingContracts") or {}
            local updated = false

            for k, v in ipairs(boostingContracts) do
                if v.id == data.id then
                    local found = nil
                    for _, p in pairs(Fetch:All()) do
                        local c = p:GetData("Character")
                        if c ~= nil then
                            local alias = c:GetData("Alias")
                            if alias?.redline == data.alias then
                                found = c
                                break
                            end
                        end
                    end

                    if found then
                        local targetContracts = found:GetData("BoostingContracts") or {}

                        v.owner = {
                            Alias = found:GetData("Alias").redline,
                            SID = found:GetData("SID"),
                        }

                        table.insert(targetContracts, v)

                        found:SetData("BoostingContracts", targetContracts)
                        Laptop.Notification:Add(
                            found:GetData("Source"),
                            "Contract Transferred to You",
                            string.format("A New %s Class Contract Was Just Transferred to You. Buy In: %s $%s", v.vehicle.class, v.prices.standard.price, v.prices.standard.coin),
                            os.time() * 1000,
                            10000,
                            "lsunderground",
                            {
                                view = "",
                            }
                        )

                        table.remove(boostingContracts, k)
                        updated = true
                    end

                    break
                end
            end

            if updated then
                char:SetData("BoostingContracts", boostingContracts)
                cb(true)
            else
                cb(false)
            end
        else
            cb(false)
        end
    end)

    Callbacks:RegisterServerCallback("Laptop:LSUnderground:Boosting:AcceptContract", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        if char then
            local boostingContracts = char:GetData("BoostingContracts") or {}
            local perm = char:GetData("LaptopPermissions")
            local team, isLeader = Laptop.Teams:GetByMemberSource(source)
            local level = Reputation:GetLevel(source, "Boosting")
            if level < 1 then
                level = 1
            end

            for k, v in ipairs(boostingContracts) do
                if v.id == data.id and (v.expires > os.time()) and (level >= v.vehicle.classLevel or v.vehicle.rewarded) then
                    if team?.ID and (#team.Members >= 2 or (perm["lsunderground"] and perm["lsunderground"]["admin"])) then

                        if Crypto:Has(source, v.prices.standard.coin, v.prices.standard.price) then
                            local req = Laptop.Teams.Requests:Add(
                                team.ID,
                                true,
                                "Laptop:Server:LSUnderground:Boosting:ActionRequest",
                                "Boosting Contract",
                                string.format("%s (%s) - %s %s", v.vehicle.label, v.vehicle.class, char:GetData("First"), char:GetData("Last")),
                                {
                                    contract = data.id,
                                    requester = source,
                                },
                                60 * 2 -- 2 Minutes
                            )
    
                            Laptop.Notification:Add(team.ID, "New Request for a Boosting Contract", string.format("%s %s Requested a Boosting Contract (%s)", char:GetData("First"), char:GetData("Last"), v.vehicle.class), os.time() * 1000, 15000, "lsunderground", {
                                accept = "Laptop:Client:Teams:RequestNotifAccept",
                                cancel = "Laptop:Client:Teams:RequestNotifDeny",
                            }, {
                                request = req,
                            })

                            return cb({ success = true })
                        else
                            return cb({ message = "Not Enough Crypto!" })
                        end
                    else
                        return cb({ message = "Not Enough Team Members!" })
                    end

                    break
                end
            end
        end

        cb(false)
    end)

    Callbacks:RegisterServerCallback("Laptop:LSUnderground:Boosting:Exterior", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        if char then
            local team = Laptop.Teams:GetByMemberSource(source)

            if team?.ID and _boosting[team.ID] and _boosting[team.ID].state == 0 then
                _boosting[team.ID].state = 1

                local makeDifficult = (GlobalState["Duty:police"] or 0) < BOOSTING_POLICE_DIFFICULT
                local classData = BOOSTING_VEHICLE_CONFIG[_boosting[team.ID].vehicleData?.class]


                local numPeds = math.random(classData?.peds?.min or 1, classData?.peds?.max or 4)
                if classData?.peds?.difficult and makeDifficult then
                    numPeds += classData?.peds?.difficult
                end

                Laptop.Teams.Members:SendEvent(team.ID, "Laptop:Client:LSUnderground:Boosting:UpdateState", 1)
                return cb(numPeds, makeDifficult)
            end
        end

        cb(false)
    end)

    Callbacks:RegisterServerCallback("Laptop:LSUnderground:Boosting:Ignition", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        if char then
            local team = Laptop.Teams:GetByMemberSource(source)

            if team?.ID and _boosting[team.ID] and _boosting[team.ID].state == 1 then

                if _boosting[team.ID].trackerTotal and _boosting[team.ID].trackerTotal > 0 then
                    _boosting[team.ID].state = 2

                    Laptop.Teams.Members:SendEvent(team.ID, "Laptop:Client:LSUnderground:Boosting:UpdateState", 2)
                    Laptop.Teams.Members:NotificationAddWithId(
                        team.ID,
                        "BOOSTING_CONTRACT",
                        "Current Contract",
                        string.format("Disable tracking devices inside the vehicle. %s/%s", _boosting[team.ID].trackerCount, _boosting[team.ID].trackerTotal),
                        os.time() * 1000,
                        -1,
                        "lsunderground",
                        {},
                        {}
                    )

                    CreateThread(function()
                        local team = team.ID
                        local location = data.location

                        while _boosting[team] and _boosting[team].state == 2 do
                            if DoesEntityExist(_boosting[team].vehicle) then
                                local coords = GetEntityCoords(_boosting[team].vehicle)
                                TriggerClientEvent("EmergencyAlerts:Client:TrackerBlip", -1, "police", string.format("boosting-%s", team), string.format("[Police]: Class %s Boost (From %s)", _boosting[team].vehicleData.class, location), coords, 523, 6, 1.0, true, 155)
                            end

                            Wait(7000 + (_boosting[team].trackerDelay * 1000))
                        end
                    end)
                else
                    _boosting[team.ID].state = 3

                    Laptop.Teams.Members:NotificationAddWithId(
                        team.ID,
                        "BOOSTING_CONTRACT",
                        "Current Contract",
                        "Leave the car at the drop off location, making sure the cops aren't following.",
                        os.time() * 1000,
                        -1,
                        "lsunderground",
                        {},
                        {}
                    )
                    Laptop.Teams.Members:SendEvent(team.ID, "Laptop:Client:LSUnderground:Boosting:UpdateState", 3)
                end
            end
        end

        cb()
    end)

    Callbacks:RegisterServerCallback("Laptop:LSUnderground:Boosting:DropOff", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        if char then
            local team = Laptop.Teams:GetByMemberSource(source)

            if team?.ID and _boosting[team.ID] and _boosting[team.ID].state == 3 then
                _boosting[team.ID].state = 4

                Laptop.Teams.Members:NotificationAddWithId(
                    team.ID,
                    "BOOSTING_CONTRACT",
                    "Current Contract",
                    "Leave the drop off location.",
                    os.time() * 1000,
                    -1,
                    "lsunderground",
                    {},
                    {}
                )
                Laptop.Teams.Members:SendEvent(team.ID, "Laptop:Client:LSUnderground:Boosting:UpdateState", 4)
            end
        end

        cb()
    end)

    Callbacks:RegisterServerCallback("Laptop:LSUnderground:Boosting:LeftArea", function(source, data, cb)
        local char = Fetch:Source(source):GetData("Character")
        if char then
            local team = Laptop.Teams:GetByMemberSource(source)

            if team?.ID and _boosting[team.ID] and _boosting[team.ID].state == 4 then
                local stillInZone = false
                for k, v in ipairs(_boosting[team.ID].members) do
                    local ped = GetPlayerPed(v.Source)

                    if #(GetEntityCoords(ped) - _boosting[team.ID].dropOff) <= 30.0 then
                        stillInZone = true
                        break
                    end
                end

                if not stillInZone then
                    if #(GetEntityCoords(_boosting[team.ID].vehicle) - _boosting[team.ID].dropOff) <= 30.0 then
                        Laptop.LSUnderground.Boosting:Complete(team?.ID)
                    else
                        Laptop.Teams.Members:Notification(
                            team.ID,
                            "Current Contract",
                            "Make sure that the vehicle stays in the drop off zone...",
                            os.time() * 1000,
                            15000,
                            "lsunderground",
                            {},
                            {}
                        )
                    end
                end
            end
        end

        cb()
    end)

    Inventory.Items:RegisterUse("boosting_tracking_disabler", "Boosting", function(source, slot, itemData)
        local team = Laptop.Teams:GetByMemberSource(source)
        local ped = GetPlayerPed(source)
        local inVeh = GetVehiclePedIsIn(ped, false)

        if team?.ID and _boosting[team.ID]
            and inVeh and GetPedInVehicleSeat(inVeh, 0) == ped
            and Entity(inVeh).state.boostVehicle == team.ID
            and _boosting[team.ID].state == 2
            and (not _boosting[team.ID].trackerCooldown or GetGameTimer() >= _boosting[team.ID].trackerCooldown)
        then
            Citizen.SetTimeout(500, function()
                Callbacks:ClientCallback(source, "Laptop:LSUnderground:Boosting:TrackerHacker", {}, function(using, success)
                    if using and _boosting[team?.ID] then

                        _boosting[team.ID].trackerCooldown = GetGameTimer() + 25000

                        if success then
                            local newValue = slot.CreateDate - (60 * 60 * 12)
    
                            if (os.time() - itemData.durability >= newValue) then
                                Inventory.Items:RemoveId(slot.Owner, slot.invType, slot)
                            else
                                Inventory:SetItemCreateDate(slot.id, newValue)
                            end

                            _boosting[team.ID].trackerCount = _boosting[team.ID].trackerCount + 1

                            if _boosting[team.ID].trackerCount >= _boosting[team.ID].trackerTotal then
                                -- Done
                                _boosting[team.ID].state = 3

                                Laptop.Teams.Members:NotificationAddWithId(
                                    team.ID,
                                    "BOOSTING_CONTRACT",
                                    "Current Contract",
                                    "Leave the car at the drop off location, making sure the cops aren't following.",
                                    os.time() * 1000,
                                    -1,
                                    "lsunderground",
                                    {},
                                    {}
                                )

                                Laptop.Teams.Members:SendEvent(team.ID, "Laptop:Client:LSUnderground:Boosting:UpdateState", 3)
                            else
                                local addingDelay = math.random(3, 6)
                                _boosting[team.ID].trackerDelay = _boosting[team.ID].trackerDelay + addingDelay

                                Laptop.Teams.Members:SendEvent(team.ID, "Laptop:Client:LSUnderground:Boosting:UpdateState", 2, {
                                    trackerDelay = _boosting[team.ID].trackerDelay,
                                    trackerCount = _boosting[team.ID].trackerCount
                                })

                                Laptop.Teams.Members:NotificationAddWithId(
                                    team.ID,
                                    "BOOSTING_CONTRACT",
                                    "Current Contract",
                                    string.format("Disable tracking devices inside the vehicle. %s/%s", _boosting[team.ID].trackerCount, _boosting[team.ID].trackerTotal),
                                    os.time() * 1000,
                                    -1,
                                    "lsunderground",
                                    {},
                                    {}
                                )

                                TriggerClientEvent(
                                    "Laptop:Client:LSUnderground:Boosting:TrackerNotificationUpdate", 
                                    source,
                                    string.format(
                                        "%s/%s Tracking Devices Disabled - Tracker Now Delayed By %s Seconds", 
                                        _boosting[team.ID].trackerCount, 
                                        _boosting[team.ID].trackerTotal,
                                        _boosting[team.ID].trackerDelay
                                    )
                                )
                            end
                        else
                            local addingDelay = math.random(3, 6)

                            _boosting[team.ID].trackerDelay = _boosting[team.ID].trackerDelay - addingDelay
                            if _boosting[team.ID].trackerDelay < 0 then
                                _boosting[team.ID].trackerDelay = 0
                            end

                            _boosting[team.ID].trackerCount = _boosting[team.ID].trackerCount - math.random(1, 2)
                            if _boosting[team.ID].trackerCount < 0 then
                                _boosting[team.ID].trackerCount = 0
                            end

                            Laptop.Teams.Members:SendEvent(team.ID, "Laptop:Client:LSUnderground:Boosting:UpdateState", 2, {
                                trackerDelay = _boosting[team.ID].trackerDelay,
                                trackerCount = _boosting[team.ID].trackerCount
                            })

                            Laptop.Teams.Members:NotificationAddWithId(
                                team.ID,
                                "BOOSTING_CONTRACT",
                                "Current Contract",
                                string.format("Disable tracking devices inside the vehicle. %s/%s", _boosting[team.ID].trackerCount, _boosting[team.ID].trackerTotal),
                                os.time() * 1000,
                                -1,
                                "lsunderground",
                                {},
                                {}
                            )

                            TriggerClientEvent(
                                "Laptop:Client:LSUnderground:Boosting:TrackerNotificationUpdate", 
                                source,
                                string.format(
                                    "%s/%s Tracking Devices Disabled - Tracker Now Delayed By %s Seconds", 
                                    _boosting[team.ID].trackerCount, 
                                    _boosting[team.ID].trackerTotal,
                                    _boosting[team.ID].trackerDelay
                                )
                            )
                        end
                    end
                end)
            end)
        else
            Execute:Client(source, "Notification", "Error", "Can't Use Right Now...")
        end
	end)

    SetupBoostingQueue()
end)

AddEventHandler("Laptop:Server:LSUnderground:Boosting:ActionRequest", function(source, data, action)
    if action == "accept" and data?.requester and data?.contract then
        local owner = Fetch:Source(data.requester)
        if not owner then return; end

        owner = owner:GetData("Character")
        if not owner then return; end

        local team, isLeader = Laptop.Teams:GetByMemberSource(data.requester)

        if not team then return; end

        local contracts = owner:GetData("BoostingContracts") or {}
        local perm = owner:GetData("LaptopPermissions")
        local updated = false

        for k, v in ipairs(contracts) do
            if v.id == data.contract then

                if team?.ID and team.State == 0 and (#team.Members >= 2 or (perm["lsunderground"] and perm["lsunderground"]["admin"])) then

                    local fail = false
                    for k, v in ipairs(team.Members) do
                        local plyr = Fetch:Source(v.Source)
                        if plyr then
                            local char = plyr:GetData("Character")
                            if char then
                                local alias = char:GetData("Alias")
                                local hasVpn = hasValue(char:GetData("States") or {}, "PHONE_VPN")
                                local isLSU = hasValue(char:GetData("States") or {}, "ACCESS_LSUNDERGROUND")
                                local hasDongle = hasValue(char:GetData("States") or {}, "RACE_DONGLE")

                                local isPolice = Player(char:GetData("Source")).state.onDuty == "police"

                                if not alias?.redline or not hasVpn or not isLSU or not hasDongle or isPolice then
                                    fail = true
                                    break 
                                end
                            else
                                fail = true
                                break
                            end
                        else
                            fail = true
                            break
                        end
                    end

                    if not fail then
                        if Crypto.Exchange:Remove(v.prices.standard.coin, owner:GetData("CryptoWallet"), v.prices.standard.price) then
                            table.remove(contracts, k)
                            updated = true
    
                            Laptop.LSUnderground.Boosting:Start(team.ID, v)
                        else
                            for _, m in ipairs(team.Members) do
                                Laptop.Notification:Add(m.Source, "Failed to Start Boosting Contract", string.format("%s %s doesn't have enough crypto to start the contract.", owner:GetData("First"), owner:GetData("Last")), os.time() * 1000, 10000, "lsunderground", {}, {})
                            end
                        end
                    else
                        Laptop.Teams.Members:Notification(
                            team.ID,
                            "Unable to Start Contract",
                            "Some of your team members don't meet the entry requirements",
                            os.time() * 1000,
                            15000,
                            "lsunderground",
                            {},
                            {}
                        )
                    end
                end

                break
            end
        end

        if updated then
            owner:SetData("BoostingContracts", contracts)
        end
    elseif data?.requester and data?.contract then
        TriggerClientEvent("Laptop:Client:RemoveData", data.requester, "disabledBoostingContracts", data.contract)
    end
end)

LAPTOP.LSUnderground = LAPTOP.LSUnderground or {}
LAPTOP.LSUnderground.Boosting = {
    RewardContract = function(self, source)
        local char = Fetch:Source(source):GetData("Character")
        if char then
            local level = Reputation:GetLevel(source, "Boosting")
            if level < 1 then
                level = 1
            end

            local boostingClass = Utils:WeightedRandom(_boostingRepToClassChances[level])

            if not BOOSTING_VEHICLE_CONFIG[boostingClass] then
                return false
            end

            local category = BOOSTING_VEHICLE_CONFIG[boostingClass]
            local isRare = false
            local length = math.random(category.length.min, category.length.max) * 60 * 60
            local veh, cost

            local tracker = false

            if category.tracker then
                local chance = math.random(100)
                if chance >= (100 - category.tracker.chance) then
                    tracker = math.random(category.tracker.min, category.tracker.max)
                end
            end

            if category.rareVehicles and #category.rareVehicles > 0 and math.random(22, 39) == 33 then
                local random = math.random(#category.rareVehicles)
                
                veh = category.rareVehicles[random]
                cost = math.random(veh.priceBase - 2, veh.priceBase + 2)
                isRare = true

                if category.trackerRare then
                    local chance = math.random(100)
                    if chance >= (100 - category.trackerRare.chance) then
                        tracker = math.random(category.trackerRare.min, category.trackerRare.max)
                    end
                end
            else
                local random = math.random(#category.vehicles)

                veh = category.vehicles[random]
                cost = math.random(veh.priceBase - 2, veh.priceBase + 2)
            end

            return Laptop.LSUnderground.Boosting:GiveContract(source, {
                vehicle = veh.vehicle,
                label = string.format("%s %s", veh.make, veh.model),
                make = veh.make,
                model = veh.model,
                class = boostingClass,
                classLevel = level,
                rare = isRare,
                tracker = tracker
            }, {
                standard = {
                    price = cost,
                    coin = "VRM",
                }
            }, length)
        end
        return false
    end,
    GiveContract = function(self, source, vehicle, prices, timeLength, settings)
        local char = Fetch:Source(source):GetData("Character")

        if not timeLength then
            timeLength = 60 * 60 * 5
        end

        if char then
            local alias = char:GetData("Alias").redline
            local contracts = char:GetData("BoostingContracts") or {}

            _boostingIds += 1

            local boostContract = {
                id = _boostingIds,
                owner = {
                    SID = char:GetData("SID"),
                    Alias = alias,
                },
                vehicle = vehicle,
                prices = prices,
                expires = os.time() + timeLength,
                settings = settings or {}
            }

            table.insert(contracts, boostContract)
            char:SetData("BoostingContracts", contracts)

            if not _boostingContractCount[char:GetData("SID")] then
                _boostingContractCount[char:GetData("SID")] = 1
            else
                _boostingContractCount[char:GetData("SID")] += 1
            end

            Logger:Info("Boosting", string.format("%s [%s %s (%s)] Rewarded Class %s Contract (%s)%s", alias, char:GetData("First"), char:GetData("Last"), char:GetData("SID"), vehicle.class, vehicle.label, vehicle.rewarded and " (Manually Created)" or ""))

            Laptop.Notification:Add(
                source,
                "New Contract Available",
                string.format("A New %s Class Contract Now Available For %s $%s", vehicle.class, prices.standard.price, prices.standard.coin),
                os.time() * 1000,
                10000,
                "lsunderground",
                {
                    view = "",
                }
            )

            return true
        end
        return false
    end,

    Start = function(self, teamId, contract)
        local team = Laptop.Teams:Get(teamId)
        if team and contract and contract?.vehicle?.vehicle then
            local dropOffLocation = _boostingDropoffs[math.random(#_boostingDropoffs)]

            if _boostingEvent then
                dropOffLocation = _boostingEventDropoff
            end
            
            local possibleLocations = {}
            for k, v in ipairs(_boostingLocations) do
                if #(dropOffLocation - v.coords.xyz) >= 1000.0 and ((not v.rich) or (v.rich and contract.vehicle.classLevel >= 4)) and not IsPickupCloseToOtherActiveBoost(v.coords.xyz) then
                    table.insert(possibleLocations, v)
                end
            end

            local pickUpLocation = possibleLocations[math.random(#possibleLocations)]

            local earningRep = 50 * contract.vehicle.classLevel
            local takenRep = math.floor(earningRep * 0.8)

            for k, v in ipairs(team.Members) do
                Reputation.Modify:Remove(v.Source, "Boosting", takenRep)

                if v.SID == contract.owner?.SID then
                    local cPlyr = Fetch:Source(v.Source)
                    if cPlyr then
                        local cChar = cPlyr:GetData("Character")
                        if cChar then
                            Logger:Info("Boosting", string.format("%s [%s %s (%s)] Started Class %s Contract (%s)", cChar:GetData("Alias")?.redline, cChar:GetData("First"), cChar:GetData("Last"), cChar:GetData("SID"), contract.vehicle.class, contract.vehicle.label))
                        end
                    end
                end
            end

            local base = contract.prices.standard.price
            local payout = math.random(math.ceil(base * 0.8), math.ceil(base * 1.1))

            local payoutOverride = contract.settings?.payoutOverride
            if payoutOverride and payoutOverride > 0 then
                payout = payoutOverride
            end

            --[[
                Boosting States
                0 - yet to find vehicle
                1 - is breaking into vehicle (peds)
                2 - has to disabled tracking (not always a thing)
                3 - yet to drop off
                4 - LEAVE THE AREA
            ]]

            _boosting[team.ID] = {
                team = team.ID,
                state = 0,
                vehicle = nil,
                contractOwner = contract.owner,
                vehicleData = contract.vehicle,
                members = team.Members,
                dropOff = dropOffLocation,
                pickUp = pickUpLocation.coords.xyz,
                pedSpawns = pickUpLocation.peds,
                peds = 4,
                settings = contract.settings,
                earningRep = earningRep,
                takenRep = takenRep,
                coin = contract.prices.standard.coin,
                price = contract.prices.standard.price,
                payout = payout,

                trackerDelay = 0,
                trackerTotal = contract.vehicle.tracker,
                trackerCount = 0,
            }

            Laptop.Teams:SetState(team.ID, "boosting", string.format("On %s Boosting Contract", contract.vehicle.class))

            Vehicles:SpawnTemp(source, GetHashKey(contract.vehicle.vehicle), pickUpLocation.coords.xyz, pickUpLocation.coords.w, function(spawnedVehicle, VIN, plate)
                if spawnedVehicle then
                    local vehState = Entity(spawnedVehicle).state
                    vehState.boostVehicle = team.ID

                    vehState.Locked = true
                    SetVehicleDoorsLocked(spawnedVehicle, 2)

                    -- forces them to hack A+
                    if contract.vehicle.classLevel >= 5 then
                        vehState.boostForceHack = true
                    end

                    _boosting[team.ID].vehicle = spawnedVehicle
                    _boosting[team.ID].vehicleNet = NetworkGetNetworkIdFromEntity(spawnedVehicle)

                    Vehicles:StopDespawn(spawnedVehicle)

                    Laptop.Teams.Members:SendEvent(team.ID, "Laptop:Client:LSUnderground:Boosting:Start", _boosting[team.ID])

                    Laptop.Teams.Members:NotificationAddWithId(
                        team.ID,
                        "BOOSTING_CONTRACT",
                        "Current Contract",
                        "Find and Steal the Vehicle",
                        os.time() * 1000,
                        -1,
                        "lsunderground",
                        {},
                        {}
                    )
                else
                    Logger:Error("Boosting", string.format("Failed to Spawn Vehicle For Boost. Contract Owner SID: %s. Buy In: %s $%s", contract.owner.SID, contract.prices.standard.price, contract.prices.standard.coin))
                end
            end, {
                Make = contract.vehicle.make,
                Model = contract.vehicle.model,
                Value = 500000,
                Class = contract.vehicle.class,
            })
        end
    end,
    Cancel = function(self, teamId, teamDeleted)
        if _boosting[teamId] then
            if not teamDeleted then
                Laptop.Teams:ResetState(teamId)
                Laptop.Teams.Members:NotificationRemoveById(teamId, "BOOSTING_CONTRACT")
                Laptop.Teams.Members:Notification(
                    teamId,
                    "Contract Cancelled",
                    "Your team failed to complete the boost, you have received a penalty.",
                    os.time() * 1000,
                    15000,
                    "lsunderground",
                    {},
                    {}
                )
                Laptop.Teams.Members:SendEvent(teamId, "Laptop:Client:LSUnderground:Boosting:End", true)
            end

            TriggerClientEvent("EmergencyAlerts:Client:TrackerBlip", -1, "police", string.format("boosting-%s", teamId))
            _boosting[teamId] = nil
        end
    end,
    Complete = function(self, teamId)
        if _boosting[teamId] then
            local veh = _boosting[teamId].vehicle

            _boosting[teamId].state = 5

            if DoesEntityExist(veh) then
                local vehState = Entity(veh).state
                vehState.boostVehicle = true
                vehState.Locked = true
                SetVehicleDoorsLocked(veh, 2)
                vehState.keepLocked = true

                local vStalls = vehState.stalls or 0

                -- Crypto
                local earnedCrypto = _boosting[teamId].payout
                local cPerStall = earnedCrypto * 0.2
                earnedCrypto -= (cPerStall * vStalls)

                if earnedCrypto < 0 then
                    earnedCrypto = 0
                end
    
                -- Rep
                local earnedRep = _boosting[teamId].earningRep
                local rPerStall = earnedRep * 0.15
                earnedRep -= (rPerStall * vStalls)
                if earnedRep < 10 then
                    earnedRep = 10
                end

                if _boosting[teamId].settings?.skipRep then
                    earnedRep = 0
                end

                for k, v in ipairs(_boosting[teamId].members) do
                    Reputation.Modify:Add(v.Source, "Boosting", math.floor(_boosting[teamId].takenRep + earnedRep))

                    if v.SID == _boosting[teamId].contractOwner?.SID then
                        local cPlyr = Fetch:Source(v.Source)
                        if cPlyr then
                            local cChar = cPlyr:GetData("Character")
                            if cChar then
                                Crypto.Exchange:Add(
                                    _boosting[teamId].coin,
                                    cChar:GetData("CryptoWallet"),
                                    math.floor(_boosting[teamId].price + earnedCrypto)
                                )

                                Logger:Info("Boosting", string.format("%s [%s %s (%s)] Completed Class %s Contract (%s)%s. Rep Gained: %s Crypto Gained: %s", cChar:GetData("Alias")?.redline, cChar:GetData("First"), cChar:GetData("Last"), cChar:GetData("SID"), _boosting[teamId].vehicleData.class, _boosting[teamId].vehicleData.label, _boosting[teamId].vehicleData.rewarded and " (Manually Created)" or "", earnedRep, earnedCrypto))
                            end
                        end
                    end
                end

                Citizen.SetTimeout(Config.DeleteVehicleDelay * 60 * 1000, function()
                    Vehicles:Delete(veh, function(success) end)
                end)
            end

            Laptop.Teams:ResetState(teamId)
            Laptop.Teams.Members:NotificationRemoveById(teamId, "BOOSTING_CONTRACT")
            Laptop.Teams.Members:SendEvent(teamId, "Laptop:Client:LSUnderground:Boosting:End")
            TriggerClientEvent("EmergencyAlerts:Client:TrackerBlip", -1, "police", string.format("boosting-%s", teamId))
            _boosting[teamId] = nil
        end
    end,
}

function RemovedFromQueueNotification(source)
    Laptop.Notification:Add(
        source,
        "No Longer in Queue",
        "You were removed from the boosting queue since you are no longer eligible.",
        os.time() * 1000,
        10000,
        "lsunderground",
        {
            view = "",
        }
    )
end

AddEventHandler("Laptop:Server:Teams:MemberRemoved", function(teamId, member)
    local team = Laptop.Teams:Get(teamId)
    if team and team.Members and #team.Members < 2 then -- No longer enough people, kick 'em out of the queue
        for k, v in ipairs(_boostingQueue) do
            if v.team == teamId and (not v.admin or v.source == member.Source) then
                TriggerClientEvent("Laptop:Client:SetData", v.source, "boostingQueue", nil)
                RemovedFromQueueNotification(v.source)

                table.remove(_boostingQueue, k)
            end
        end

        if _boosting[teamId] then
            Laptop.LSUnderground.Boosting:Cancel(teamId)
        end
    end
end)

AddEventHandler("Laptop:Server:Teams:Deleted", function(teamId)
    for k, v in ipairs(_boostingQueue) do
        if v.team == teamId then
            TriggerClientEvent("Laptop:Client:SetData", v.source, "boostingQueue", nil)
            RemovedFromQueueNotification(v.source)

            table.remove(_boostingQueue, k)
        end
    end

    if _boosting[teamId] then
        Laptop.LSUnderground.Boosting:Cancel(teamId, true)
    end
end)

AddEventHandler("Vehicles:Server:Deleted", function(veh)
    for k, v in pairs(_boosting) do
        if v and v.vehicle == veh then
            Laptop.LSUnderground.Boosting:Cancel(k)
        end
    end
end)

RegisterNetEvent("Vehicles:Server:BlownUp", function(veh)
    for k, v in pairs(_boosting) do
        if v and v.vehicle == veh then
            Laptop.LSUnderground.Boosting:Cancel(k)
        end
    end
end)

RegisterNetEvent("Towing:Server:TowingVehicle", function(vehNet)
    local veh = NetworkGetEntityFromNetworkId(vehNet)
    if veh and DoesEntityExist(veh) then
        for k, v in pairs(_boosting) do
            if v and v.vehicle == veh then
                Laptop.LSUnderground.Boosting:Cancel(k)
            end
        end
    end
end)

local _queueStarted = false
function SetupBoostingQueue()
    if _queueStarted then return; end
    _queueStarted = true

    CreateThread(function()
        Wait(BOOSTING_SERVER_START_WAIT)
        Logger:Info("Boosting", "Boosting Contracts Can Now Be Rewarded")

        while true do

            local chosen = false
            local makeDifficult = (GlobalState["Duty:police"] or 0) < BOOSTING_POLICE_DIFFICULT

            if #_boostingQueue > 0 then
                --local index = math.random(#_boostingQueue + (makeDifficult and BOOSTING_RANDOMNESS_DIFFICULT or BOOSTING_RANDOMNESS))

                local index = math.random(
                    #_boostingQueue - (makeDifficult and BOOSTING_RANDOMNESS_DIFFICULT or BOOSTING_RANDOMNESS),
                    #_boostingQueue + (makeDifficult and BOOSTING_RANDOMNESS_DIFFICULT or BOOSTING_RANDOMNESS)
                )

                if _boostingQueue[index] then
                    local plyr = Fetch:Source(_boostingQueue[index].source)
                    if plyr then
                        local char = plyr:GetData("Character")
                        if char then
                            local holdingContracts = char:GetData("BoostingContracts") or {}
                            local contractCount = 0

                            for k, v in ipairs(holdingContracts) do
                                if v.expires >= os.time() then
                                    contractCount += 1
                                end
                            end

                            if not _boosting[_boostingQueue[index].team] and (not _boostingContractCount[char:GetData("SID")] or (_boostingContractCount[char:GetData("SID")] < BOOSTING_MAX_CONTRACTS)) and (contractCount < BOOSTING_MAX_QUEUE) then
                                chosen = true

                                Laptop.LSUnderground.Boosting:RewardContract(char:GetData("Source"))
                            end
                        end
                    end
                end

                if not chosen then
                    Logger:Info("Boosting", string.format("Nobody Chosen for Boosting Contract (%s | %s)", index, #_boostingQueue))
                end
            end

            Wait((1000 * 60) * math.random(BOOSTING_TIME_BETWEEN_MIN, BOOSTING_TIME_BETWEEN_MAX))
        end
    end)
end

function IsPickupCloseToOtherActiveBoost(coords)
    for k, v in pairs(_boosting) do
        if v and v.pickUp and #(v.pickUp - coords) <= 10.0 then
            return true
        end
    end

    return false
end
