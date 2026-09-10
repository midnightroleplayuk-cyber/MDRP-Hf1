local npcCache = {}
local spawned = {}

local function dbg(...)
    if Config.Debug then
        print('[hf1_npcs]', ...)
    end
end

local function notify(source, description, ntype)
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'NPC Manager',
        description = description,
        type = ntype or 'inform'
    })
end

local function sanitizeString(value, maxLen)
    if type(value) ~= 'string' then return '' end
    value = value:gsub('[%z\1-\31]', ''):sub(1, maxLen or 100)
    return value
end

local function sanitizeNpc(data, requireId)
    if type(data) ~= 'table' then return nil, 'Invalid NPC data.' end
    if requireId and type(data.id) ~= 'number' then return nil, 'Invalid NPC ID.' end

    local coords = data.coords
    if type(coords) ~= 'table' then return nil, 'Invalid coordinates.' end

    local x, y, z, w = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z), tonumber(coords.w)
    if not x or not y or not z or not w then return nil, 'Invalid coordinates.' end

    local model = sanitizeString(data.model, 80)
    local name = sanitizeString(data.name, 100)
    if model == '' or name == '' then return nil, 'Name and model are required.' end

    local target = type(data.target) == 'table' and data.target or {}

    local cleaned = {
        id = requireId and math.floor(data.id) or nil,
        name = name,
        model = model,
        coords = { x = x + 0.0, y = y + 0.0, z = z + 0.0, w = w % 360.0 },
        scenario = sanitizeString(data.scenario, 100),
        animDict = sanitizeString(data.animDict, 150),
        animName = sanitizeString(data.animName, 150),
        animFlag = math.floor(tonumber(data.animFlag) or Config.Defaults.animFlag),
        invincible = data.invincible == true,
        frozen = data.frozen == true,
        blockEvents = data.blockEvents == true,
        canRagdoll = data.canRagdoll == true,
        collision = data.collision ~= false,
        spawnDistance = math.max(25.0, math.min(500.0, tonumber(data.spawnDistance) or Config.Defaults.spawnDistance)),
        target = {
            enabled = target.enabled == true,
            label = sanitizeString(target.label, 80),
            icon = sanitizeString(target.icon, 80),
            event = sanitizeString(target.event, 120),
        },
    }

    if cleaned.target.label == '' then cleaned.target.label = Config.Defaults.targetLabel end
    if cleaned.target.icon == '' then cleaned.target.icon = Config.Defaults.targetIcon end

    return cleaned
end

local function deleteSpawned(id)
    local entity = spawned[id]
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
    spawned[id] = nil
end

local function spawnNpc(npc)
    deleteSpawned(npc.id)

    local hash = joaat(npc.model)
    local ped = CreatePed(4, hash, npc.coords.x, npc.coords.y, npc.coords.z, npc.coords.w, true, true)

    if not ped or ped == 0 then
        print(('[hf1_npcs] Failed to create ped #%s (%s)'):format(npc.id, npc.model))
        return
    end

    SetEntityOrphanMode(ped, 2)
    FreezeEntityPosition(ped, npc.frozen)
    SetEntityInvincible(ped, npc.invincible)

    Entity(ped).state:set('qbxNpcId', npc.id, true)
    Entity(ped).state:set('qbxNpcManaged', true, true)

    spawned[npc.id] = ped
    dbg(('spawned #%s entity %s'):format(npc.id, ped))
end

local function rebuildNpc(id)
    local npc = npcCache[id]
    if npc then spawnNpc(npc) end
end

local function loadCache()
    npcCache = {}
    local list = NPCManagerDB.LoadAll()
    for i = 1, #list do
        npcCache[list[i].id] = list[i]
    end
    return list
end

local function getList()
    local list = {}
    for _, npc in pairs(npcCache) do
        list[#list + 1] = npc
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

local function broadcast()
    TriggerClientEvent('hf1_npcs:client:setCache', -1, getList())
end

MySQL.ready(function()
    local list = loadCache()
    for i = 1, #list do
        spawnNpc(list[i])
        Wait(0)
    end
    print(('[hf1_npcs] Loaded %s persistent NPC(s).'):format(#list))
end)

lib.callback.register('hf1_npcs:server:hasAccess', function(source)
    return NPCManagerPermissions.HasAccess(source)
end)

lib.callback.register('hf1_npcs:server:getNpcs', function(source)
    return getList()
end)

lib.callback.register('hf1_npcs:server:createNpc', function(source, data)
    if not NPCManagerPermissions.HasAccess(source) then
        return { ok = false, message = 'You do not have permission.' }
    end

    local cleaned, err = sanitizeNpc(data, false)
    if not cleaned then return { ok = false, message = err } end

    local id = NPCManagerDB.Insert(cleaned, NPCManagerPermissions.GetCreatorIdentifier(source))
    if not id then return { ok = false, message = 'Database insert failed.' } end

    cleaned.id = id
    npcCache[id] = cleaned
    spawnNpc(cleaned)
    broadcast()

    return { ok = true, id = id }
end)

lib.callback.register('hf1_npcs:server:updateNpc', function(source, data)
    if not NPCManagerPermissions.HasAccess(source) then
        return { ok = false, message = 'You do not have permission.' }
    end

    local cleaned, err = sanitizeNpc(data, true)
    if not cleaned then return { ok = false, message = err } end
    if not npcCache[cleaned.id] then return { ok = false, message = 'NPC not found.' } end

    local affected = NPCManagerDB.Update(cleaned)
    if not affected or affected < 1 then
        return { ok = false, message = 'Database update failed.' }
    end

    npcCache[cleaned.id] = cleaned
    rebuildNpc(cleaned.id)
    broadcast()

    return { ok = true }
end)

lib.callback.register('hf1_npcs:server:deleteNpc', function(source, id)
    if not NPCManagerPermissions.HasAccess(source) then
        return { ok = false, message = 'You do not have permission.' }
    end

    id = tonumber(id)
    if not id or not npcCache[id] then return { ok = false, message = 'NPC not found.' } end

    NPCManagerDB.Delete(id)
    deleteSpawned(id)
    npcCache[id] = nil
    broadcast()

    return { ok = true }
end)

RegisterNetEvent('hf1_npcs:server:requestSync', function()
    TriggerClientEvent('hf1_npcs:client:setCache', source, getList())
end)

RegisterCommand(Config.Command, function(source)
    if source == 0 then
        print('[hf1_npcs] This command is player-only.')
        return
    end

    if not NPCManagerPermissions.HasAccess(source) then
        notify(source, 'You do not have permission to use the NPC Manager.', 'error')
        return
    end

    TriggerClientEvent('hf1_npcs:client:open', source)
end, false)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for id in pairs(spawned) do
        deleteSpawned(id)
    end
end)
