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
    local function sanitizeReply(reply, maxSteps)
        reply = type(reply) == 'table' and reply or {}
        local label = sanitizeString(reply.label, 120)
        if label == '' then return nil end
        local action = sanitizeString(reply.action, 20)
        if action ~= 'branch' and action ~= 'client_event' and action ~= 'server_event' and action ~= 'command' and action ~= 'back' and action ~= 'close' then
            if tonumber(reply.nextStep) then action = 'branch'
            elseif sanitizeString(reply.event, 120) ~= '' then action = 'client_event'
            elseif reply.close == false then action = 'back'
            else action = 'close' end
        end
        local nextStep = math.floor(tonumber(reply.nextStep) or 0)
        if nextStep < 1 or nextStep > maxSteps then nextStep = nil end

        local rawCondition = type(reply.condition) == 'table' and reply.condition or {}
        local conditionType = sanitizeString(rawCondition.type, 20)
        if conditionType ~= 'group' and conditionType ~= 'item' and conditionType ~= 'no_item' and conditionType ~= 'cash' and conditionType ~= 'bank' then
            conditionType = 'always'
        end
        local visibility = sanitizeString(rawCondition.visibility, 10)
        if visibility ~= 'locked' then visibility = 'hidden' end
        local condition = {
            type = conditionType,
            visibility = visibility,
            name = sanitizeString(rawCondition.name, 80),
            amount = math.max(0, math.floor(tonumber(rawCondition.amount) or 0)),
        }

        return {
            label = label,
            icon = sanitizeString(reply.icon, 80),
            response = sanitizeString(reply.response, 500),
            sound = sanitizeString(reply.sound, 120),
            action = action,
            event = sanitizeString(reply.event, 120),
            command = sanitizeString(reply.command, 120):gsub('^/', ''),
            nextStep = nextStep,
            close = action ~= 'back' and action ~= 'branch',
            condition = condition,
        }
    end

    local rawSteps = type(dialogue.steps) == 'table' and dialogue.steps or {}
    local stepCount = math.min(#rawSteps, 4)
    local dialogueReplies = type(dialogue.replies) == 'table' and dialogue.replies or {}
    local cleanedReplies = {}
    for i = 1, math.min(#dialogueReplies, 4) do
        local cleanedReply = sanitizeReply(dialogueReplies[i], stepCount)
        if cleanedReply then cleanedReplies[#cleanedReplies + 1] = cleanedReply end
    end

    local cleanedSteps = {}
    for i = 1, stepCount do
        local rawStep = type(rawSteps[i]) == 'table' and rawSteps[i] or {}
        local rawReplies = type(rawStep.replies) == 'table' and rawStep.replies or {}
        local stepReplies = {}
        for j = 1, math.min(#rawReplies, 4) do
            local cleanedReply = sanitizeReply(rawReplies[j], stepCount)
            if cleanedReply then stepReplies[#stepReplies + 1] = cleanedReply end
        end
        cleanedSteps[#cleanedSteps + 1] = {
            text = sanitizeString(rawStep.text, 500),
            replies = stepReplies,
        }
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
            steps = cleanedSteps,
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

lib.callback.register('hf1_npcs:server:checkDialogueCondition', function(source, condition)
    condition = type(condition) == 'table' and condition or {}
    local ctype = sanitizeString(condition.type, 20)
    local name = sanitizeString(condition.name, 80)
    local amount = math.max(0, math.floor(tonumber(condition.amount) or 0))

    if ctype == '' or ctype == 'always' then
        return { allowed = true }
    end

    if ctype == 'group' then
        if name == '' then return { allowed = false, reason = 'Requires a configured job/group' } end
        local groups = exports.qbx_core:GetGroups(source) or {}
        local grade = tonumber(groups[name])
        local allowed = grade ~= nil and grade >= amount
        return { allowed = allowed, reason = ('Requires %s grade %s+'):format(name, amount) }
    end

    if ctype == 'item' or ctype == 'no_item' then
        if name == '' then return { allowed = false, reason = 'Requires a configured item' } end
        if GetResourceState('ox_inventory') ~= 'started' then
            return { allowed = false, reason = 'ox_inventory is not available' }
        end
        local count = exports.ox_inventory:GetItemCount(source, name) or 0
        if ctype == 'item' then
            return { allowed = count >= math.max(1, amount), reason = ('Requires %sx %s'):format(math.max(1, amount), name) }
        end
        return { allowed = count < math.max(1, amount), reason = ('Unavailable while carrying %sx %s'):format(math.max(1, amount), name) }
    end

    if ctype == 'cash' or ctype == 'bank' then
        local balance = exports.qbx_core:GetMoney(source, ctype) or 0
        return { allowed = balance >= amount, reason = ('Requires $%s %s'):format(amount, ctype) }
    end

    return { allowed = true }
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
