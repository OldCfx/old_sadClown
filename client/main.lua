local spawnedPeds = {}
local completedClowns = {}
local activeBlips = {}
local isInteracting = false
local isBeingRobbed = false

local function setupBlips()
    if not Config.EnableBlips then return end

    for id, coords in pairs(Config.Clowns) do
        if not completedClowns[id] and not activeBlips[id] then
            local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
            SetBlipSprite(blip, Config.BlipSettings.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, Config.BlipSettings.scale)
            SetBlipColour(blip, Config.BlipSettings.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(Config.BlipSettings.name)
            EndTextCommandSetBlipName(blip)

            activeBlips[id] = blip
        end
    end
end

local function removeBlip(id)
    if activeBlips[id] then
        RemoveBlip(activeBlips[id])
        activeBlips[id] = nil
    end
end

local function cheerUpClown(id)
    local clownData = spawnedPeds[id]
    if not clownData or not clownData.entity or not DoesEntityExist(clownData.entity) then return end

    clownData.isHappy = true
    ClearPedTasks(clownData.entity)
    FreezeEntityPosition(clownData.entity, false)

    ESX.Streaming.RequestAnimDict(Config.ClownHappyAnim.dict, function(animDict)
        if clownData.entity and DoesEntityExist(clownData.entity) then
            TaskPlayAnim(clownData.entity, animDict, Config.ClownHappyAnim.anim, 2.0, 2.0, -1, 1, 0.0, false, false,
                false)
            RemoveAnimDict(animDict)
        end
    end)
end

local function removeClown(id)
    if spawnedPeds[id] then
        if spawnedPeds[id].entity and DoesEntityExist(spawnedPeds[id].entity) then
            DeleteEntity(spawnedPeds[id].entity)
        end
        spawnedPeds[id] = nil
    end
end

local function handleRobberBehavior(id, totalCount)
    local clownData = spawnedPeds[id]
    if not clownData or not DoesEntityExist(clownData.entity) then return end

    local ped = clownData.entity
    local playerPed = PlayerPedId()

    clownData.isHostile = true
    clownData.stolenAmount = totalCount
    clownData.looted = false
    clownData.fleeing = false
    isBeingRobbed = true

    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    SetPedSuffersCriticalHits(ped, false)

    GiveWeaponToPed(ped, Config.WeaponModel, 1, false, true)
    SetPedDropsWeaponsWhenDead(ped, false)
    SetCurrentPedWeapon(ped, Config.WeaponModel, true)

    TaskTurnPedToFaceEntity(ped, playerPed, 800)
    Wait(400)

    ESX.Streaming.RequestAnimDict('combat@gestures@gang@pistol_1h@beckon', function(dict)
        if DoesEntityExist(ped) and not IsPedDeadOrDying(ped, true) then
            TaskPlayAnim(ped, dict, '0', 2.0, 2.0, -1, 49, 0.0, false, false, false)
            RemoveAnimDict(dict)
        end
    end)

    CreateThread(function()
        local aimEndTime = GetGameTimer() + Config.RobberyAimTime
        local isAttacking = false

        while DoesEntityExist(ped) and not IsPedDeadOrDying(ped, true) and not clownData.fleeing do
            local currentTarget = PlayerPedId()

            if IsPedDeadOrDying(currentTarget, true) then
                isBeingRobbed = false
                clownData.fleeing = true
                ClearPedTasks(ped)
                TaskSmartFleePed(ped, currentTarget, 300.0, -1, false, false)
                SetPedKeepTask(ped, true)
                break
            end

            if not isAttacking then
                if isBeingRobbed then
                    ESX.ShowHelpNotification(Config.Notifications.robberyChoice)

                    if IsControlJustReleased(0, 38) then
                        if not IsPedInAnyVehicle(playerPed, false) then
                            isBeingRobbed = false
                            clownData.fleeing = true

                            ESX.Streaming.RequestAnimDict('random@mugging3', function(dict)
                                TaskPlayAnim(currentTarget, dict, 'handsup_standing_base', 2.0, 2.0, 3000, 49, 0.0, false,
                                    false, false)
                                RemoveAnimDict(dict)
                            end)

                            TriggerServerEvent('old_sadClown:surrenderCandies', id)
                            ESX.ShowNotification(Config.Notifications.surrendered)

                            ClearPedTasks(ped)
                            SetPedFleeAttributes(ped, 0, false)
                            SetPedCombatAttributes(ped, 17, true)
                            TaskSmartFleePed(ped, currentTarget, 350.0, -1, false, false)
                            SetPedKeepTask(ped, true)
                            break
                        else
                            ESX.ShowNotification(Config.Notifications.noVehicle)
                        end
                    end

                    if IsControlJustReleased(0, 73) or HasEntityBeenDamagedByEntity(ped, currentTarget, true) then
                        isAttacking = true
                        isBeingRobbed = false
                        ClearPedTasks(ped)
                        TaskCombatPed(ped, currentTarget, 0, 16)
                        SetPedKeepTask(ped, true)
                    end
                end

                if GetGameTimer() >= aimEndTime and not isAttacking and isBeingRobbed then
                    isAttacking = true
                    isBeingRobbed = false
                    ClearPedTasks(ped)
                    TaskCombatPed(ped, currentTarget, 0, 16)
                    SetPedKeepTask(ped, true)
                elseif not isAttacking then
                    TaskTurnPedToFaceEntity(ped, currentTarget, 400)
                end
            end

            Wait(0)
        end

        isBeingRobbed = false
    end)
end

local function spawnClown(id)
    if spawnedPeds[id] then return end

    local coords = Config.Clowns[id]
    if not coords then return end

    spawnedPeds[id] = { spawning = true }

    local modelHash = type(Config.PedModel) == 'number' and Config.PedModel or joaat(Config.PedModel)

    CreateThread(function()
        RequestModel(modelHash)
        while not HasModelLoaded(modelHash) do
            Wait(10)
        end

        RequestAnimDict(Config.ClownSadAnim.dict)
        while not HasAnimDictLoaded(Config.ClownSadAnim.dict) do
            Wait(10)
        end

        if not spawnedPeds[id] or not spawnedPeds[id].spawning then
            return
        end

        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        local ped = CreatePed(4, modelHash, coords.x, coords.y, coords.z - 1.0, coords.w, false, false)

        SetEntityAsMissionEntity(ped, true, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedCanRagdoll(ped, false)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)

        TaskPlayAnim(ped, Config.ClownSadAnim.dict, Config.ClownSadAnim.anim, 2.0, 2.0, -1, 1, 0.0, false, false, false)

        spawnedPeds[id] = {
            entity = ped,
            isHappy = false,
            isHostile = false,
            fleeing = false,
            stolenAmount = 0,
            looted = false,
            spawning = false
        }

        CreateThread(function()
            while Config.speech and spawnedPeds[id] and DoesEntityExist(ped) and not spawnedPeds[id].isHappy and not spawnedPeds[id].isHostile do
                local pCoords = GetEntityCoords(PlayerPedId())
                local cCoords = GetEntityCoords(ped)

                if #(pCoords - cCoords) <= 8.0 then
                    PlayPedAmbientSpeechNative(ped, 'DYING_MOAN', 'SPEECH_PARAMS_FORCE_SHOUTED_CLEAR')
                end

                Wait(math.random(5000, 9000))
            end
        end)
    end)
end

CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local pCoords = GetEntityCoords(playerPed)

        for id, coords in pairs(Config.Clowns) do
            local clown = spawnedPeds[id]

            if not completedClowns[id] then
                local distToSpawn = #(pCoords - coords.xyz)

                if distToSpawn <= Config.DistanceSpawn and not clown then
                    spawnClown(id)
                elseif distToSpawn > Config.DistanceSpawn and clown and not clown.spawning and not clown.isHostile then
                    removeClown(id)
                end
            else
                if clown and not clown.spawning and clown.entity and DoesEntityExist(clown.entity) then
                    local currentClownCoords = GetEntityCoords(clown.entity)
                    local currentDist = #(pCoords - currentClownCoords)

                    if currentDist > Config.DistanceDespawn then
                        removeClown(id)
                    end
                end
            end
        end

        Wait(1000)
    end
end)

CreateThread(function()
    while true do
        local sleep = 500
        local playerPed = PlayerPedId()
        local pCoords = GetEntityCoords(playerPed)

        if not isInteracting and not isBeingRobbed then
            for clownId, clown in pairs(spawnedPeds) do
                if not completedClowns[clownId] and not clown.spawning and not clown.isHappy and not clown.isHostile and clown.entity and DoesEntityExist(clown.entity) then
                    local clownCoords = GetEntityCoords(clown.entity)
                    local dist = #(pCoords - clownCoords)

                    if dist <= Config.DistanceInteraction then
                        sleep = 0
                        ESX.ShowHelpNotification(Config.Notifications.pressE)

                        if IsControlJustReleased(0, 38) then
                            if not IsPedInAnyVehicle(playerPed, false) then
                                isInteracting = true

                                ESX.TriggerServerCallback('old_sadClown:checkCandy', function(hasItem)
                                    if not hasItem then
                                        ESX.ShowNotification(Config.Notifications.noCandy)
                                        isInteracting = false
                                        return
                                    end

                                    ESX.Streaming.RequestAnimDict(Config.PlayerAnim.dict, function(animDict)
                                        TaskPlayAnim(playerPed, animDict, Config.PlayerAnim.anim, 2.0, 2.0,
                                            Config.PlayerAnim.duration, 0, 0.0, false, false, false)
                                        RemoveAnimDict(animDict)

                                        Wait(Config.PlayerAnim.duration)
                                        TriggerServerEvent('old_sadClown:giveCandy', clownId)
                                    end)
                                end)
                            else
                                ESX.ShowNotification(Config.Notifications.noVehicle)
                            end
                        end
                    end
                elseif clown.isHostile and not clown.looted and clown.entity and DoesEntityExist(clown.entity) and IsPedDeadOrDying(clown.entity, true) then
                    local clownCoords = GetEntityCoords(clown.entity)
                    local dist = #(pCoords - clownCoords)

                    if dist <= Config.DistanceInteraction then
                        sleep = 0
                        ESX.ShowHelpNotification(Config.Notifications.pressELoot)

                        if IsControlJustReleased(0, 38) then
                            if not IsPedInAnyVehicle(playerPed, false) then
                                clown.looted = true

                                ESX.Streaming.RequestAnimDict('pickup_object', function(dict)
                                    TaskPlayAnim(playerPed, dict, 'pickup_low', 2.0, 2.0, 1500, 0, 0.0, false, false,
                                        false)
                                    RemoveAnimDict(dict)

                                    Wait(1500)
                                    TriggerServerEvent('old_sadClown:recoverCandy', clownId, clown.stolenAmount)
                                end)
                            else
                                ESX.ShowNotification(Config.Notifications.noVehicle)
                            end
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)



RegisterNetEvent('old_sadClown:syncCompleted', function(list)
    completedClowns = list
    setupBlips()
end)

RegisterNetEvent('old_sadClown:validated', function(id)
    completedClowns[id] = true
    isInteracting = false
    removeBlip(id)
    cheerUpClown(id)
    ESX.ShowNotification(Config.Notifications.success)
end)

RegisterNetEvent('old_sadClown:robbed', function(id, count)
    completedClowns[id] = true
    isInteracting = false
    removeBlip(id)
    ESX.ShowNotification(Config.Notifications.robbery)
    handleRobberBehavior(id, count)
end)

RegisterNetEvent('old_sadClown:recovered', function()
    ESX.ShowNotification(Config.Notifications.recovered)
end)

RegisterNetEvent('old_sadClown:failed', function()
    isInteracting = false
    isBeingRobbed = false
end)

RegisterNetEvent('esx:playerLoaded', function()
    TriggerServerEvent('old_sadClown:playerLoaded')
    ESX.ShowNotification(Config.Notifications.missionStart)
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    if ESX.PlayerLoaded then
        TriggerServerEvent('old_sadClown:playerLoaded')
        ESX.ShowNotification(Config.Notifications.missionStart)
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, clown in pairs(spawnedPeds) do
        if clown.entity and DoesEntityExist(clown.entity) then
            DeleteEntity(clown.entity)
        end
    end
    for _, blip in pairs(activeBlips) do
        RemoveBlip(blip)
    end
end)
