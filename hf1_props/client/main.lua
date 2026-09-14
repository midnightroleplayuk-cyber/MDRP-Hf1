HF1Props = HF1Props or {}

local definitions = {}
local spawned = {}

local function requestModel(model)
    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) or IsModelAVehicle(hash) or IsModelAPed(hash) then
        return nil
    end

    RequestModel(hash)
    local deadline = GetGameTimer() + (Config.Streaming.modelLoadTimeout or 7000)
    while not HasModelLoaded(hash) and GetGameTimer() < deadline do Wait(10) end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

local function deleteSpawned(id)
    local entity = spawned[id]
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
    spawned[id] = nil
end

local function spawnDefinition(def)
    if spawned[def.id] and DoesEntityExist(spawned[def.id]) then return end
    local hash = requestModel(def.model)
    if not hash then
        if Config.Debug then print(('[hf1_props] Invalid/unavailable model: %s'):format(def.model)) end
        return
    end

    local c, r = def.coords, def.rotation
    local entity = CreateObjectNoOffset(hash, c.x, c.y, c.z, false, false, false)
    if entity == 0 then SetModelAsNoLongerNeeded(hash); return end

    SetEntityRotation(entity, r.x, r.y, r.z, 2, true)
    SetEntityCollision(entity, def.collision ~= false, def.collision ~= false)
    FreezeEntityPosition(entity, def.frozen ~= false)
    SetEntityAsMissionEntity(entity, true, false)
    spawned[def.id] = entity
    SetModelAsNoLongerNeeded(hash)
end

local function replaceDefinition(def)
    local id = tonumber(def.id)
    if not id then return end
    deleteSpawned(id)
    definitions[id] = def
end

function HF1Props.GetDefinitions()
    return definitions
end

function HF1Props.GetDefinition(id)
    return definitions[tonumber(id)]
end

function HF1Props.ValidateModel(model)
    model = type(model) == 'string' and (model:match('^%s*(.-)%s*$') or '') or ''
    if model == '' then return false, 'Enter a prop model name.' end
    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return false, 'That model is not currently available. If it is a custom prop, make sure its resource is started.'
    end
    if IsModelAVehicle(hash) or IsModelAPed(hash) then
        return false, 'That model is a vehicle or ped, not a prop/object.'
    end
    return true
end

RegisterNetEvent('hf1_props:client:setCache', function(list)
    local incoming = {}
    for i = 1, #(list or {}) do
        local def = list[i]
        local id = tonumber(def.id)
        if id then incoming[id] = def end
    end

    for id in pairs(definitions) do
        if not incoming[id] then deleteSpawned(id) end
    end
    for id, def in pairs(incoming) do
        local old = definitions[id]
        local changed = not old
            or old.model ~= def.model
            or old.coords.x ~= def.coords.x or old.coords.y ~= def.coords.y or old.coords.z ~= def.coords.z
            or old.rotation.x ~= def.rotation.x or old.rotation.y ~= def.rotation.y or old.rotation.z ~= def.rotation.z
            or old.frozen ~= def.frozen or old.collision ~= def.collision
        if changed then deleteSpawned(id) end
    end
    definitions = incoming
end)

RegisterNetEvent('hf1_props:client:upsert', function(def)
    replaceDefinition(def)
    local id = tonumber(def.id)
    if not id then return end
    local pos = GetEntityCoords(PlayerPedId())
    local c = def.coords
    local dx, dy, dz = pos.x - c.x, pos.y - c.y, pos.z - c.z
    local maxDist = Config.Streaming.spawnDistance or 180.0
    if (dx * dx + dy * dy + dz * dz) <= maxDist * maxDist then
        spawnDefinition(def)
    end
end)

RegisterNetEvent('hf1_props:client:remove', function(id)
    id = tonumber(id)
    if not id then return end
    deleteSpawned(id)
    definitions[id] = nil
end)

RegisterNetEvent('hf1_props:client:notify', function(description, kind)
    lib.notify({ title = 'Prop Admin', description = description, type = kind or 'inform' })
end)

CreateThread(function()
    Wait(500)
    TriggerServerEvent('hf1_props:server:requestCache')

    while true do
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local spawnDistance = Config.Streaming.spawnDistance or 180.0
        local despawnDistance = Config.Streaming.despawnDistance or 220.0

        for id, def in pairs(definitions) do
            local c = def.coords
            local dx, dy, dz = pos.x - c.x, pos.y - c.y, pos.z - c.z
            local distSq = dx * dx + dy * dy + dz * dz
            local entity = spawned[id]

            if entity and DoesEntityExist(entity) then
                if distSq > despawnDistance * despawnDistance then
                    deleteSpawned(id)
                end
            elseif distSq <= spawnDistance * spawnDistance then
                spawnDefinition(def)
            end
        end

        Wait(Config.Streaming.refreshInterval or 1500)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for id in pairs(spawned) do deleteSpawned(id) end
end)
