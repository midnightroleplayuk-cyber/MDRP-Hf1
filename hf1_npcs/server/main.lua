local npcCache = {}

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
    local dialogue = type(data.dialogue) == 'table' and data.dialogue or {}
    local dialogueReplies = type(dialogue.replies) == 'table' and dialogue.replies or {}
    local cleanedReplies = {}
    for i = 1, math.min(#dialogueReplies, 4) do
        local reply = type(dialogueReplies[i]) == 'table' and dialogueReplies[i] or {}
        local label = sanitizeString(reply.label, 120)
        if label ~= '' then
            cleanedReplies[#cleanedReplies + 1] = {
                label = label,
                response = sanitizeString(reply.response, 500),
                event = sanitizeString(reply.event, 120),
                close = reply.close ~= false,
            }
        end
    end

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
            mode = sanitizeString(target.mode, 20),
            label = sanitizeString(target.label, 80),
            icon = sanitizeString(target.icon, 80),
            event = sanitizeString(target.event, 120),
        },
        dialogue = {
            enabled = dialogue.enabled == true,
            text = sanitizeString(dialogue.text, 500),
            replies = cleanedReplies,
        },
    }

    if cleaned.target.mode ~= 'talk' and cleaned.target.mode ~= 'event' then
        cleaned.target.mode = cleaned.dialogue.enabled and 'talk' or 'event'
    end
    if cleaned.target.label == '' then cleaned.target.label = Config.Defaults.targetLabel end
    if cleaned.target.icon == '' then cleaned.target.icon = Config.Defaults.targetIcon end
    if cleaned.target.mode == 'talk' and cleaned.dialogue.text == '' then
        return nil, 'Talk to NPC requires an opening line.'
    end
    if cleaned.target.mode == 'event' and cleaned.target.enabled and cleaned.target.event == '' then
        return nil, 'Direct Client Event interaction requires an event name.'
    end

    return cleaned
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
    print(('[hf1_npcs] Loaded %s persistent NPC definition(s). Clients will stream them locally.'):format(#list))
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
