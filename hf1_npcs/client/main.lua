NPCManager = NPCManager or {}
NPCManager.cache = NPCManager.cache or {}
NPCManager.entities = NPCManager.entities or {}
NPCManager.targets = NPCManager.targets or {}

local function dbg(...)
    if Config.Debug then
        print('[hf1_npcs]', ...)
    end
end

function NPCManager.Notify(description, ntype)
    lib.notify({
        title = 'NPC Manager',
        description = description,
        type = ntype or 'inform'
    })
end

function NPCManager.HasAccess()
    return lib.callback.await('hf1_npcs:server:hasAccess', false) == true
end

function NPCManager.LoadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) or not IsModelAPed(hash) then
        return nil, 'That is not a valid ped model.'
    end

    RequestModel(hash)
    local timeout = GetGameTimer() + 10000
    while not HasModelLoaded(hash) do
        Wait(0)
        if GetGameTimer() > timeout then
            return nil, 'Timed out loading that ped model.'
        end
    end

    return hash
end

local function clearTarget(id, entity)
    if NPCManager.targets[id] and GetResourceState('ox_target') == 'started' and entity and DoesEntityExist(entity) then
        pcall(function()
            exports.ox_target:removeLocalEntity(entity, ('hf1_npcs:%s'):format(id))
        end)
    end
    NPCManager.targets[id] = nil
end

local function setupTarget(npc, entity)
    clearTarget(npc.id, entity)

    if not npc.target or not npc.target.enabled or npc.target.event == '' then return end
    if GetResourceState('ox_target') ~= 'started' then return end

    local optionName = ('hf1_npcs:%s'):format(npc.id)
    exports.ox_target:addLocalEntity(entity, {
        {
            name = optionName,
            icon = npc.target.icon or 'fa-solid fa-user',
            label = npc.target.label or 'Interact',
            distance = 2.5,
            onSelect = function(data)
                TriggerEvent(npc.target.event, {
                    npcId = npc.id,
                    entity = data.entity,
                    npc = npc,
                })
            end
        }
    })

    NPCManager.targets[npc.id] = true
end

local function deleteLocalNpc(id)
    local entity = NPCManager.entities[id]
    if entity and DoesEntityExist(entity) then
        clearTarget(id, entity)
        SetEntityAsMissionEntity(entity, true, true)
        DeletePed(entity)
        if DoesEntityExist(entity) then DeleteEntity(entity) end
    end
    NPCManager.entities[id] = nil
    NPCManager.targets[id] = nil
end

function NPCManager.ApplyToEntity(npc, entity)
    if not entity or entity == 0 or not DoesEntityExist(entity) then return false end

    SetEntityInvincible(entity, npc.invincible == true)
    FreezeEntityPosition(entity, npc.frozen == true)
    SetBlockingOfNonTemporaryEvents(entity, npc.blockEvents == true)
    SetPedCanRagdoll(entity, npc.canRagdoll == true)
    SetEntityCollision(entity, npc.collision ~= false, npc.collision ~= false)
    SetPedFleeAttributes(entity, 0, false)
    SetPedCombatAttributes(entity, 17, true)
    SetPedDropsWeaponsWhenDead(entity, false)
    SetEntityHeading(entity, npc.coords.w or 0.0)

    if npc.scenario and npc.scenario ~= '' then
        ClearPedTasks(entity)
        TaskStartScenarioInPlace(entity, npc.scenario, 0, true)
    elseif npc.animDict and npc.animDict ~= '' and npc.animName and npc.animName ~= '' then
        RequestAnimDict(npc.animDict)
        local timeout = GetGameTimer() + 5000
        while not HasAnimDictLoaded(npc.animDict) and GetGameTimer() < timeout do Wait(0) end
        if HasAnimDictLoaded(npc.animDict) then
            ClearPedTasks(entity)
            TaskPlayAnim(entity, npc.animDict, npc.animName, 8.0, -8.0, -1, npc.animFlag or 1, 0.0, false, false, false)
        end
    end

    setupTarget(npc, entity)
    return true
end

local function spawnLocalNpc(npc)
    if NPCManager.entities[npc.id] and DoesEntityExist(NPCManager.entities[npc.id]) then
        return NPCManager.entities[npc.id]
    end

    local hash, err = NPCManager.LoadModel(npc.model)
    if not hash then
        dbg(('failed loading npc #%s model %s: %s'):format(npc.id, npc.model, err or 'unknown error'))
        return nil
    end

    -- Treat the saved Z as the floor point. Start from the model's lower bound,
    -- then remove any remaining measured gap after collision has loaded.
    local minDim, _ = GetModelDimensions(hash)
    local feetOffset = math.abs(minDim.z)
    local spawnZ = npc.coords.z + feetOffset + 0.10
    local ped = CreatePed(4, hash, npc.coords.x, npc.coords.y, spawnZ, npc.coords.w or 0.0, false, false)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        SetModelAsNoLongerNeeded(hash)
        dbg(('failed creating local npc #%s (%s)'):format(npc.id, npc.model))
        return nil
    end

    SetEntityAsMissionEntity(ped, true, true)
    SetEntityCoordsNoOffset(ped, npc.coords.x, npc.coords.y, spawnZ, false, false, false)
    SetEntityHeading(ped, npc.coords.w or 0.0)

    -- Give collision a moment to resolve, then remove the measured gap between
    -- the ped and the floor. This avoids the unavailable PlaceEntityOnGroundProperly
    -- helper and keeps preview/final placement on the same maths.
    RequestCollisionAtCoord(npc.coords.x, npc.coords.y, npc.coords.z)
    local timeout = GetGameTimer() + 1000
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < timeout do
        Wait(0)
    end

    if HasCollisionLoadedAroundEntity(ped) then
        local height = GetEntityHeightAboveGround(ped)
        if height and height > 0.001 and height < 2.0 then
            local pos = GetEntityCoords(ped)
            SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z - height, false, false, false)
        end
    end

    SetEntityHeading(ped, npc.coords.w or 0.0)
    SetModelAsNoLongerNeeded(hash)

    NPCManager.entities[npc.id] = ped
    NPCManager.ApplyToEntity(npc, ped)
    dbg(('spawned local npc #%s entity %s'):format(npc.id, ped))

    return ped
end

RegisterNetEvent('hf1_npcs:client:setCache', function(list)
    local newCache = {}
    for i = 1, #(list or {}) do
        newCache[list[i].id] = list[i]
    end

    -- Delete removed NPCs, and rebuild NPCs whose saved definition changed.
    for id, entity in pairs(NPCManager.entities) do
        local oldNpc = NPCManager.cache[id]
        local newNpc = newCache[id]

        if not newNpc then
            deleteLocalNpc(id)
        elseif oldNpc then
            local changed = oldNpc.model ~= newNpc.model
                or oldNpc.coords.x ~= newNpc.coords.x
                or oldNpc.coords.y ~= newNpc.coords.y
                or oldNpc.coords.z ~= newNpc.coords.z
                or oldNpc.coords.w ~= newNpc.coords.w
                or oldNpc.scenario ~= newNpc.scenario
                or oldNpc.animDict ~= newNpc.animDict
                or oldNpc.animName ~= newNpc.animName
                or oldNpc.animFlag ~= newNpc.animFlag
                or oldNpc.invincible ~= newNpc.invincible
                or oldNpc.frozen ~= newNpc.frozen
                or oldNpc.blockEvents ~= newNpc.blockEvents
                or oldNpc.canRagdoll ~= newNpc.canRagdoll
                or oldNpc.collision ~= newNpc.collision

            if changed then
                deleteLocalNpc(id)
            elseif entity and DoesEntityExist(entity) then
                -- Target settings may have changed without requiring a respawn.
                setupTarget(newNpc, entity)
            end
        end
    end

    NPCManager.cache = newCache
end)

RegisterNetEvent('hf1_npcs:client:open', function()
    if NPCManager.OpenMainMenu then
        NPCManager.OpenMainMenu()
    end
end)

CreateThread(function()
    Wait(1000)
    TriggerServerEvent('hf1_npcs:server:requestSync')

    while true do
        local playerCoords = GetEntityCoords(cache.ped)

        for id, npc in pairs(NPCManager.cache) do
            local dist = #(playerCoords - vec3(npc.coords.x, npc.coords.y, npc.coords.z))
            local spawnDistance = npc.spawnDistance or Config.Sync.applyDistance
            local entity = NPCManager.entities[id]

            if dist <= spawnDistance then
                if not entity or not DoesEntityExist(entity) then
                    spawnLocalNpc(npc)
                else
                    -- Re-assert long-running scenarios/animations if GTA clears them.
                    if npc.scenario and npc.scenario ~= '' and not IsPedUsingScenario(entity, npc.scenario) then
                        TaskStartScenarioInPlace(entity, npc.scenario, 0, true)
                    elseif npc.animDict and npc.animDict ~= '' and npc.animName ~= ''
                        and not IsEntityPlayingAnim(entity, npc.animDict, npc.animName, 3) then
                        NPCManager.ApplyToEntity(npc, entity)
                    end
                end
            elseif entity and DoesEntityExist(entity) and dist > (spawnDistance + 25.0) then
                deleteLocalNpc(id)
            end
        end

        Wait(Config.Sync.refreshInterval)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for id in pairs(NPCManager.entities) do
        deleteLocalNpc(id)
    end
end)

lib.addKeybind({
    name = 'hf1_npcs_open',
    description = 'Open NPC Manager',
    defaultKey = Config.Keybind,
    onPressed = function()
        if NPCManager.HasAccess() then
            NPCManager.OpenMainMenu()
        else
            NPCManager.Notify('You do not have permission to use the NPC Manager.', 'error')
        end
    end
})
