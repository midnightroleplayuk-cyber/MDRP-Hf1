NPCManager = NPCManager or {}

local function boolDefault(value, fallback)
    if value == nil then return fallback end
    return value == true
end

local function scenarioOptions()
    local options = {}
    for i = 1, #ScenarioPresets do
        options[#options + 1] = {
            label = ScenarioPresets[i].label,
            value = ScenarioPresets[i].value
        }
    end
    return options
end

local function animationOptions()
    local options = {}
    for i = 1, #AnimationPresets do
        options[#options + 1] = {
            label = AnimationPresets[i].label,
            value = i
        }
    end
    return options
end

local function getBehavior(existing)
    existing = existing or {}
    local input = lib.inputDialog('NPC Behaviour & Settings', {
        {
            type = 'select',
            label = 'Scenario preset',
            description = 'Scenarios take priority over custom animations.',
            options = scenarioOptions(),
            default = existing.scenario or '',
            searchable = true,
        },
        {
            type = 'select',
            label = 'Animation preset',
            description = 'Choose a preset or leave None and use custom fields below.',
            options = animationOptions(),
            default = 1,
            searchable = true,
        },
        {
            type = 'input',
            label = 'Custom animation dictionary',
            default = existing.animDict or '',
            placeholder = 'e.g. missheistdockssetup1clipboard@base',
        },
        {
            type = 'input',
            label = 'Custom animation name',
            default = existing.animName or '',
            placeholder = 'e.g. base',
        },
        {
            type = 'number',
            label = 'Animation flag',
            default = existing.animFlag or Config.Defaults.animFlag,
            min = 0,
            max = 51,
        },
        {
            type = 'checkbox',
            label = 'Invincible',
            checked = boolDefault(existing.invincible, Config.Defaults.invincible),
        },
        {
            type = 'checkbox',
            label = 'Frozen in place',
            checked = boolDefault(existing.frozen, Config.Defaults.frozen),
        },
        {
            type = 'checkbox',
            label = 'Block non-temporary events (stoic)',
            checked = boolDefault(existing.blockEvents, Config.Defaults.blockEvents),
        },
        {
            type = 'checkbox',
            label = 'Can ragdoll',
            checked = boolDefault(existing.canRagdoll, Config.Defaults.canRagdoll),
        },
        {
            type = 'checkbox',
            label = 'Collision enabled',
            checked = boolDefault(existing.collision, Config.Defaults.collision),
        },
        {
            type = 'number',
            label = 'Spawn / apply distance',
            default = existing.spawnDistance or Config.Defaults.spawnDistance,
            min = 25,
            max = 500,
        },
        {
            type = 'checkbox',
            label = 'Enable ox_target interaction',
            checked = existing.target and existing.target.enabled or false,
        },
        {
            type = 'input',
            label = 'ox_target label',
            default = existing.target and existing.target.label or Config.Defaults.targetLabel,
        },
        {
            type = 'input',
            label = 'ox_target icon',
            default = existing.target and existing.target.icon or Config.Defaults.targetIcon,
        },
        {
            type = 'input',
            label = 'Client event to trigger',
            description = 'Example: myresource:client:openShop',
            default = existing.target and existing.target.event or '',
        },
    }, { size = 'lg' })

    if not input then return nil end

    local animPreset = AnimationPresets[tonumber(input[2]) or 1] or AnimationPresets[1]
    local animDict = input[3] or ''
    local animName = input[4] or ''
    local animFlag = tonumber(input[5]) or Config.Defaults.animFlag

    if animPreset and animPreset.dict ~= '' and animDict == '' and animName == '' then
        animDict = animPreset.dict
        animName = animPreset.name
        animFlag = animPreset.flag
    end

    return {
        scenario = input[1] or '',
        animDict = animDict,
        animName = animName,
        animFlag = animFlag,
        invincible = input[6] == true,
        frozen = input[7] == true,
        blockEvents = input[8] == true,
        canRagdoll = input[9] == true,
        collision = input[10] == true,
        spawnDistance = tonumber(input[11]) or Config.Defaults.spawnDistance,
        target = {
            enabled = input[12] == true,
            label = input[13] or Config.Defaults.targetLabel,
            icon = input[14] or Config.Defaults.targetIcon,
            event = input[15] or '',
        }
    }
end

local function chooseModel()
    local input = lib.inputDialog('Choose NPC Model', {
        {
            type = 'input',
            label = 'Search or enter model',
            description = 'Enter any valid FiveM/GTA ped model, or type part of a name/model to browse matches.',
            placeholder = 's_m_y_cop_01 or cop',
            required = true,
        }
    })

    if not input then return nil end
    local query = tostring(input[1] or ''):lower()
    if query == '' then return nil end

    local exactHash = joaat(query)
    if IsModelInCdimage(exactHash) and IsModelValid(exactHash) and IsModelAPed(exactHash) then
        return query
    end

    local matches = {}
    for i = 1, #PedCatalog do
        local ped = PedCatalog[i]
        if ped.label:lower():find(query, 1, true) or ped.model:lower():find(query, 1, true) then
            matches[#matches + 1] = {
                label = ('%s (%s)'):format(ped.label, ped.model),
                value = ped.model
            }
        end
    end

    if #matches == 0 then
        NPCManager.Notify('No catalog matches, and that exact model is invalid.', 'error')
        return nil
    end

    local selection = lib.inputDialog(('Ped results for "%s"'):format(query), {
        {
            type = 'select',
            label = 'Ped model',
            options = matches,
            searchable = true,
            required = true,
        }
    })

    return selection and selection[1] or nil
end

local function buildNpc(existing, replacingPosition)
    local initial = lib.inputDialog(existing and 'Edit NPC' or 'Create NPC', {
        {
            type = 'input',
            label = 'NPC name',
            description = 'Friendly name used in the manager.',
            default = existing and existing.name or '',
            required = true,
            min = 2,
            max = 100,
        },
        {
            type = 'input',
            label = 'Ped model',
            description = 'Any valid GTA/FiveM ped model. Leave this unchanged when editing.',
            default = existing and existing.model or '',
            required = existing ~= nil,
        },
    })

    if not initial then return nil end

    local name = initial[1]
    local model = initial[2]

    if not model or model == '' then
        model = chooseModel()
        if not model then return nil end
    else
        local hash = joaat(model)
        if not IsModelInCdimage(hash) or not IsModelValid(hash) or not IsModelAPed(hash) then
            NPCManager.Notify('That ped model is invalid.', 'error')
            return nil
        end
    end

    local coords = existing and existing.coords or nil
    if not existing or replacingPosition then
        coords = NPCManager.PlacePed(model, replacingPosition and existing.coords or nil)
        if not coords then return nil end
    end

    local behavior = getBehavior(existing)
    if not behavior then return nil end

    return {
        id = existing and existing.id or nil,
        name = name,
        model = model,
        coords = coords,
        scenario = behavior.scenario,
        animDict = behavior.animDict,
        animName = behavior.animName,
        animFlag = behavior.animFlag,
        invincible = behavior.invincible,
        frozen = behavior.frozen,
        blockEvents = behavior.blockEvents,
        canRagdoll = behavior.canRagdoll,
        collision = behavior.collision,
        spawnDistance = behavior.spawnDistance,
        target = behavior.target,
    }
end

local function createNpc()
    local data = buildNpc(nil, true)
    if not data then return end

    local response = lib.callback.await('qbx_npcmanager:server:createNpc', false, data)
    if response and response.ok then
        NPCManager.Notify(('NPC #%s created successfully.'):format(response.id), 'success')
    else
        NPCManager.Notify(response and response.message or 'Failed to create NPC.', 'error')
    end
end

local function teleportToNpc(npc)
    SetEntityCoords(cache.ped, npc.coords.x, npc.coords.y, npc.coords.z + 1.0, false, false, false, false)
    SetEntityHeading(cache.ped, npc.coords.w)
end

local function editNpc(npc)
    local data = buildNpc(npc, false)
    if not data then return end

    local response = lib.callback.await('qbx_npcmanager:server:updateNpc', false, data)
    if response and response.ok then
        NPCManager.Notify(('NPC #%s updated.'):format(npc.id), 'success')
    else
        NPCManager.Notify(response and response.message or 'Failed to update NPC.', 'error')
    end
end

local function moveNpc(npc)
    local newCoords = NPCManager.PlacePed(npc.model, npc.coords)
    if not newCoords then return end

    local updated = {}
    for k, v in pairs(npc) do updated[k] = v end
    updated.coords = newCoords

    local response = lib.callback.await('qbx_npcmanager:server:updateNpc', false, updated)
    if response and response.ok then
        NPCManager.Notify(('NPC #%s moved.'):format(npc.id), 'success')
    else
        NPCManager.Notify(response and response.message or 'Failed to move NPC.', 'error')
    end
end

local function duplicateNpc(npc)
    local newCoords = NPCManager.PlacePed(npc.model, nil)
    if not newCoords then return end

    local copy = {}
    for k, v in pairs(npc) do copy[k] = v end
    copy.id = nil
    copy.name = ('%s Copy'):format(npc.name)
    copy.coords = newCoords

    local response = lib.callback.await('qbx_npcmanager:server:createNpc', false, copy)
    if response and response.ok then
        NPCManager.Notify(('NPC duplicated as #%s.'):format(response.id), 'success')
    else
        NPCManager.Notify(response and response.message or 'Failed to duplicate NPC.', 'error')
    end
end

local function deleteNpc(npc)
    local confirm = lib.alertDialog({
        header = ('Delete NPC #%s?'):format(npc.id),
        content = ('This will permanently delete **%s** from the database.'):format(npc.name),
        centered = true,
        cancel = true,
        labels = { confirm = 'Delete', cancel = 'Cancel' }
    })

    if confirm ~= 'confirm' then return end

    local response = lib.callback.await('qbx_npcmanager:server:deleteNpc', false, npc.id)
    if response and response.ok then
        NPCManager.Notify(('NPC #%s deleted.'):format(npc.id), 'success')
    else
        NPCManager.Notify(response and response.message or 'Failed to delete NPC.', 'error')
    end
end

local function openNpcActions(npc)
    lib.registerContext({
        id = 'qbx_npcmanager_actions',
        title = ('#%s - %s'):format(npc.id, npc.name),
        menu = 'qbx_npcmanager_manage',
        options = {
            {
                title = 'Teleport To',
                description = ('%.2f, %.2f, %.2f'):format(npc.coords.x, npc.coords.y, npc.coords.z),
                icon = 'location-dot',
                onSelect = function() teleportToNpc(npc) end,
            },
            {
                title = 'Edit Settings',
                description = 'Change model, behaviour, animation and target settings.',
                icon = 'pen',
                onSelect = function() editNpc(npc) end,
            },
            {
                title = 'Move / Reposition',
                description = 'Open visual placement mode at its current location.',
                icon = 'arrows-up-down-left-right',
                onSelect = function() moveNpc(npc) end,
            },
            {
                title = 'Duplicate',
                description = 'Create a copy and place it somewhere else.',
                icon = 'copy',
                onSelect = function() duplicateNpc(npc) end,
            },
            {
                title = 'Delete',
                description = 'Permanently remove this NPC.',
                icon = 'trash',
                iconColor = '#ef4444',
                onSelect = function() deleteNpc(npc) end,
            },
        }
    })

    lib.showContext('qbx_npcmanager_actions')
end

local function manageNpcs()
    local list = lib.callback.await('qbx_npcmanager:server:getNpcs', false) or {}
    if #list == 0 then
        NPCManager.Notify('There are no saved NPCs yet.', 'inform')
        return
    end

    local search = lib.inputDialog('Manage NPCs', {
        {
            type = 'input',
            label = 'Search',
            description = 'Optional: search by ID, name or model.',
            placeholder = 'Leave blank for all NPCs',
        }
    })

    if not search then return end
    local query = tostring(search[1] or ''):lower()
    local options = {}

    for i = 1, #list do
        local npc = list[i]
        local haystack = ('%s %s %s'):format(npc.id, npc.name, npc.model):lower()
        if query == '' or haystack:find(query, 1, true) then
            options[#options + 1] = {
                title = ('#%s - %s'):format(npc.id, npc.name),
                description = ('%s | %.1f, %.1f, %.1f'):format(npc.model, npc.coords.x, npc.coords.y, npc.coords.z),
                icon = 'person',
                onSelect = function() openNpcActions(npc) end,
            }
        end
    end

    if #options == 0 then
        NPCManager.Notify('No NPCs matched that search.', 'inform')
        return
    end

    lib.registerContext({
        id = 'qbx_npcmanager_manage',
        title = ('Manage NPCs (%s)'):format(#options),
        menu = 'qbx_npcmanager_main',
        options = options
    })
    lib.showContext('qbx_npcmanager_manage')
end

function NPCManager.OpenMainMenu()
    if not NPCManager.HasAccess() then
        NPCManager.Notify('You do not have permission to use the NPC Manager.', 'error')
        return
    end

    lib.registerContext({
        id = 'qbx_npcmanager_main',
        title = 'Qbox NPC Manager',
        options = {
            {
                title = 'Create NPC',
                description = 'Choose a ped, place it visually, configure it and save it.',
                icon = 'user-plus',
                onSelect = createNpc,
            },
            {
                title = 'Manage NPCs',
                description = 'Search, edit, move, duplicate, teleport to or delete saved NPCs.',
                icon = 'users-gear',
                onSelect = manageNpcs,
            },
            {
                title = 'Refresh NPC Cache',
                description = 'Request the latest NPC list from the server.',
                icon = 'rotate',
                onSelect = function()
                    TriggerServerEvent('qbx_npcmanager:server:requestSync')
                    NPCManager.Notify('NPC cache refreshed.', 'success')
                end,
            },
        }
    })

    lib.showContext('qbx_npcmanager_main')
end
