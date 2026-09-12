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


local function isConfiguredDialogueSound(soundName)
    if type(soundName) ~= 'string' or soundName == '' then return false end
    local configured = Config.DialogueSounds or {}
    for i = 1, #configured do
        if type(configured[i]) == 'table' and configured[i].value == soundName then
            return true
        end
    end
    return false
end

local function playDialogueSound(soundName)
    if not isConfiguredDialogueSound(soundName) then return end
    SendNUIMessage({
        action = 'playDialogueSound',
        sound = soundName,
        volume = math.max(0.0, math.min(1.0, tonumber(Config.DialogueSoundVolume) or 0.65)),
    })
end

local function triggerNpcClientEvent(eventName, npc, entity, reply)
    if not eventName or eventName == '' then return end
    TriggerEvent(eventName, {
        npcId = npc.id,
        entity = entity,
        npc = npc,
        reply = reply,
    })
end

local function runDialogueAction(reply, npc, entity, showNode, currentNode)
    local action = reply.action
    if not action or action == '' then
        if reply.nextStep then action = 'branch'
        elseif reply.event and reply.event ~= '' then action = 'client_event'
        elseif reply.close == false then action = 'back'
        else action = 'close' end
    end

    if action == 'branch' then
        local nextStep = tonumber(reply.nextStep)
        if nextStep then showNode(nextStep) else showNode(currentNode) end
    elseif action == 'client_event' then
        triggerNpcClientEvent(reply.event, npc, entity, reply)
        lib.hideMenu(false)
    elseif action == 'server_event' then
        if reply.event and reply.event ~= '' then
            TriggerServerEvent(reply.event, {
                npcId = npc.id,
                npc = npc,
                reply = reply,
            })
        end
        lib.hideMenu(false)
    elseif action == 'command' then
        if reply.command and reply.command ~= '' then ExecuteCommand(reply.command) end
        lib.hideMenu(false)
    elseif action == 'back' then
        showNode(currentNode)
    else
        lib.hideMenu(false)
    end
end

local function checkReplyCondition(reply)
    local condition = type(reply.condition) == 'table' and reply.condition or { type = 'always', visibility = 'hidden' }
    if not condition.type or condition.type == '' or condition.type == 'always' then
        return true, nil
    end

    local result = lib.callback.await('hf1_npcs:server:checkDialogueCondition', false, condition)
    if type(result) ~= 'table' then
        return false, 'Requirement check failed'
    end
    return result.allowed == true, result.reason
end

local function showDialogueContext(context)
    -- Keep one ox_lib context alive at a time and give NUI layout a full frame
    -- to settle before mounting the next view.
    if lib.getOpenContextMenu and lib.getOpenContextMenu() then
        lib.hideContext(false)
        Wait(140)
    else
        Wait(80)
    end

    lib.registerContext(context)
    Wait(20)
    lib.showContext(context.id)
end

local function openNpcDialogue(npc, entity)
    local dialogue = npc.dialogue or {}
    if not dialogue.enabled or not dialogue.text or dialogue.text == '' then
        NPCManager.Notify('This NPC has no dialogue configured.', 'error')
        return
    end

    local function nodeData(nodeIndex)
        if nodeIndex == 0 then return dialogue.text, dialogue.replies or {} end
        local step = dialogue.steps and dialogue.steps[nodeIndex]
        if not step then return nil, nil end
        return step.text, step.replies or {}
    end

    local showNode
    showNode = function(nodeIndex)
        local text, replies = nodeData(nodeIndex)
        if not text then
            NPCManager.Notify('That dialogue step no longer exists.', 'error')
            lib.hideContext()
            return
        end

        local menuId = ('hf1_npcs:dialogue:%s:node:%s'):format(npc.id, nodeIndex)
        local options = {
            {
                title = ('%s Says:'):format(npc.name or 'NPC'),
                description = text,
                icon = 'fa-solid fa-comment-dots',
                readOnly = true,
            }
        }

        for i = 1, #replies do
            local reply = replies[i]
            if reply.label and reply.label ~= '' then
                local allowed, reason = checkReplyCondition(reply)
                local visibility = type(reply.condition) == 'table' and reply.condition.visibility or 'hidden'

                if allowed or visibility == 'locked' then
                    local capturedReply = reply
                    local capturedAllowed = allowed
                    local capturedReason = reason
                    options[#options + 1] = {
                        title = capturedReply.label,
                        description = (not capturedAllowed and capturedReason) or nil,
                        icon = capturedAllowed and (capturedReply.icon or 'fa-solid fa-reply') or 'fa-solid fa-lock',
                        disabled = not capturedAllowed,
                        onSelect = capturedAllowed and function()
                            playDialogueSound(capturedReply.sound)

                            local function doAction()
                                runDialogueAction(capturedReply, npc, entity, showNode, nodeIndex)
                            end

                            if capturedReply.response and capturedReply.response ~= '' then
                                local responseId = ('hf1_npcs:dialogue:%s:node:%s:reply:%s'):format(npc.id, nodeIndex, i)
                                showDialogueContext({
                                    id = responseId,
                                    title = npc.name or 'NPC',
                                    options = {
                                        {
                                            title = ('%s Says:'):format(npc.name or 'NPC'),
                                            description = capturedReply.response,
                                            icon = 'fa-solid fa-comment-dots',
                                            readOnly = true,
                                        },
                                        {
                                            title = capturedReply.action == 'branch' and 'Continue' or (capturedReply.action == 'back' and 'Back to conversation' or 'Continue'),
                                            icon = capturedReply.action == 'close' and 'fa-solid fa-door-open' or 'fa-solid fa-arrow-right',
                                            onSelect = doAction,
                                        }
                                    }
                                })
                            else
                                doAction()
                            end
                        end or nil,
                    }
                end
            end
        end

        options[#options + 1] = {
            title = 'Goodbye',
            icon = 'fa-solid fa-door-open',
            onSelect = function() lib.hideContext() end,
        }

        showDialogueContext({ id = menuId, title = npc.name or 'NPC', options = options })
    end

    -- Let ox_target close its own NUI before opening the conversation context.
    Wait(250)
    showNode(0)
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

    if not npc.target or not npc.target.enabled then return end
    if GetResourceState('ox_target') ~= 'started' then return end

    local optionName = ('hf1_npcs:%s'):format(npc.id)
    exports.ox_target:addLocalEntity(entity, {
        {
            name = optionName,
            icon = npc.target.icon or 'fa-solid fa-user',
            label = npc.target.label or 'Interact',
            distance = 2.5,
            canInteract = function(targetEntity)
                return targetEntity ~= 0
                    and DoesEntityExist(targetEntity)
                    and not IsEntityDead(targetEntity)
                    and not IsPedDeadOrDying(targetEntity, true)
            end,
            onSelect = function(data)
                if not data.entity or data.entity == 0 or not DoesEntityExist(data.entity) then return end
                if IsEntityDead(data.entity) or IsPedDeadOrDying(data.entity, true) then return end

                local mode = npc.target.mode or ((npc.dialogue and npc.dialogue.enabled) and 'talk' or 'event')
                if mode == 'talk' then
                    openNpcDialogue(npc, data.entity)
                elseif npc.target.event and npc.target.event ~= '' then
                    triggerNpcClientEvent(npc.target.event, npc, data.entity)
                end
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

    -- Use model bounds only to get the ped instantiated safely. Once the skeleton
    -- exists, calculate the real origin-to-foot distance from its foot bones so
    -- invisible model bounds cannot leave the NPC visibly hovering.
    local minDim, _ = GetModelDimensions(hash)
    local fallbackOffset = math.max(0.0, -minDim.z)
    local spawnZ = npc.coords.z + fallbackOffset
    local ped = CreatePed(4, hash, npc.coords.x, npc.coords.y, spawnZ, npc.coords.w or 0.0, false, false)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        SetModelAsNoLongerNeeded(hash)
        dbg(('failed creating local npc #%s (%s)'):format(npc.id, npc.model))
        return nil
    end

    SetEntityAsMissionEntity(ped, true, true)
    SetEntityHeading(ped, npc.coords.w or 0.0)
    Wait(0)

    local entityZ = GetEntityCoords(ped).z
    local leftFoot = GetPedBoneCoords(ped, 14201, 0.0, 0.0, 0.0) -- SKEL_L_Foot
    local rightFoot = GetPedBoneCoords(ped, 52301, 0.0, 0.0, 0.0) -- SKEL_R_Foot
    local feetOffset = fallbackOffset + (Config.Placement.groundOffset or 0.0)

    if leftFoot and rightFoot then
        local lowestFootZ = math.min(leftFoot.z, rightFoot.z)
        local boneOffset = entityZ - lowestFootZ
        if boneOffset > 0.05 and boneOffset < 3.0 then
            feetOffset = boneOffset + (Config.Placement.soleOffset or 0.025)
        end
    end

    spawnZ = npc.coords.z + feetOffset
    RequestCollisionAtCoord(npc.coords.x, npc.coords.y, npc.coords.z)
    SetEntityCoordsNoOffset(ped, npc.coords.x, npc.coords.y, spawnZ, false, false, false)
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
                    -- Dead NPCs must no longer expose ox_target options. Leave the corpse
                    -- in-world until normal streaming cleanup, but never restart behaviour.
                    if IsEntityDead(entity) or IsPedDeadOrDying(entity, true) then
                        clearTarget(id, entity)
                    else
                        -- Re-assert long-running scenarios/animations if GTA clears them.
                        if npc.scenario and npc.scenario ~= '' and not IsPedUsingScenario(entity, npc.scenario) then
                            TaskStartScenarioInPlace(entity, npc.scenario, 0, true)
                        elseif npc.animDict and npc.animDict ~= '' and npc.animName ~= ''
                            and not IsEntityPlayingAnim(entity, npc.animDict, npc.animName, 3) then
                            NPCManager.ApplyToEntity(npc, entity)
                        end
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
