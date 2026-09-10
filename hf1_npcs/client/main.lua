NPCManager = NPCManager or {}
NPCManager.cache = NPCManager.cache or {}
NPCManager.applied = NPCManager.applied or {}
NPCManager.targets = NPCManager.targets or {}

local function dbg(...)
    if Config.Debug then
        print('[qbx_npcmanager]', ...)
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
    return lib.callback.await('qbx_npcmanager:server:hasAccess', false) == true
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
            exports.ox_target:removeLocalEntity(entity, ('qbx_npcmanager:%s'):format(id))
        end)
    end
    NPCManager.targets[id] = nil
end

local function setupTarget(npc, entity)
    clearTarget(npc.id, entity)

    if not npc.target or not npc.target.enabled or npc.target.event == '' then return end
    if GetResourceState('ox_target') ~= 'started' then return end

    local optionName = ('qbx_npcmanager:%s'):format(npc.id)
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

    if npc.scenario and npc.scenario ~= '' then
        if not IsPedUsingScenario(entity, npc.scenario) then
            ClearPedTasks(entity)
            TaskStartScenarioInPlace(entity, npc.scenario, 0, true)
        end
    elseif npc.animDict and npc.animDict ~= '' and npc.animName and npc.animName ~= '' then
        if not IsEntityPlayingAnim(entity, npc.animDict, npc.animName, 3) then
            RequestAnimDict(npc.animDict)
            local timeout = GetGameTimer() + 5000
            while not HasAnimDictLoaded(npc.animDict) and GetGameTimer() < timeout do Wait(0) end
            if HasAnimDictLoaded(npc.animDict) then
                ClearPedTasks(entity)
                TaskPlayAnim(entity, npc.animDict, npc.animName, 8.0, -8.0, -1, npc.animFlag or 1, 0.0, false, false, false)
            end
        end
    end

    setupTarget(npc, entity)
    return true
end

RegisterNetEvent('qbx_npcmanager:client:setCache', function(list)
    NPCManager.cache = {}
    for i = 1, #(list or {}) do
        NPCManager.cache[list[i].id] = list[i]
    end
    NPCManager.applied = {}
end)

RegisterNetEvent('qbx_npcmanager:client:open', function()
    if NPCManager.OpenMainMenu then
        NPCManager.OpenMainMenu()
    end
end)

CreateThread(function()
    Wait(1000)
    TriggerServerEvent('qbx_npcmanager:server:requestSync')

    while true do
        local playerCoords = GetEntityCoords(cache.ped)

        for id, npc in pairs(NPCManager.cache) do
            local dist = #(playerCoords - vec3(npc.coords.x, npc.coords.y, npc.coords.z))
            if dist <= (npc.spawnDistance or Config.Sync.applyDistance) then
                local entity = nil
                local pool = GetGamePool('CPed')

                for i = 1, #pool do
                    local ped = pool[i]
                    if DoesEntityExist(ped) and Entity(ped).state.qbxNpcId == id then
                        entity = ped
                        break
                    end
                end

                if entity then
                    local token = ('%s:%s'):format(entity, npc.updatedAt or '')
                    if NPCManager.applied[id] ~= token then
                        if NPCManager.ApplyToEntity(npc, entity) then
                            NPCManager.applied[id] = token
                            dbg(('applied npc #%s to entity %s'):format(id, entity))
                        end
                    elseif npc.scenario and npc.scenario ~= '' and not IsPedUsingScenario(entity, npc.scenario) then
                        TaskStartScenarioInPlace(entity, npc.scenario, 0, true)
                    elseif npc.animDict and npc.animDict ~= '' and npc.animName ~= '' and not IsEntityPlayingAnim(entity, npc.animDict, npc.animName, 3) then
                        NPCManager.applied[id] = nil
                    end
                end
            end
        end

        Wait(Config.Sync.refreshInterval)
    end
end)

lib.addKeybind({
    name = 'qbx_npcmanager_open',
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
