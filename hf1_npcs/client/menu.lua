NPCManager = NPCManager or {}

local function boolDefault(value, fallback)
    if value == nil then return fallback end
    return value == true
end

local function activityOptions()
    local options = {}
    for i = 1, #ActivityPresets do
        options[#options + 1] = {
            label = ActivityPresets[i].label,
            value = ActivityPresets[i].value,
        }
    end
    return options
end

local function presetForExisting(existing)
    existing = existing or {}

    if existing.scenario and existing.scenario ~= '' then
        for i = 1, #ActivityPresets do
            local preset = ActivityPresets[i]
            if preset.type == 'scenario' and preset.scenario == existing.scenario then
                return preset.value
            end
        end
        return 'advanced'
    end

    if existing.animDict and existing.animDict ~= '' and existing.animName and existing.animName ~= '' then
        for i = 1, #ActivityPresets do
            local preset = ActivityPresets[i]
            if preset.type == 'anim' and preset.dict == existing.animDict and preset.name == existing.animName then
                return preset.value
            end
        end
        return 'advanced'
    end

    return 'none'
end

local function getActivityPreset(value)
    for i = 1, #ActivityPresets do
        if ActivityPresets[i].value == value then
            return ActivityPresets[i]
        end
    end
    return ActivityPresets[1]
end

local function getBehavior(existing)
    existing = existing or {}

    local input = lib.inputDialog('NPC Behaviour & Settings', {
        {
            type = 'select',
            label = 'Activity / Pose',
            description = 'Pick what the NPC should do. Props and animations are configured automatically.',
            options = activityOptions(),
            default = presetForExisting(existing),
            searchable = true,
            clearable = false,
            required = true,
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
            label = 'Ignore nearby events / stay calm',
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
            label = 'Spawn distance',
            description = 'How close a player should be before this NPC is managed/applied.',
            default = existing.spawnDistance or Config.Defaults.spawnDistance,
            min = 25,
            max = 500,
        },
        {
            type = 'checkbox',
            label = 'Enable ox_target interaction',
            description = 'Optional. This is the basic interaction hook; the planned conversation builder can replace/extend this later.',
            checked = existing.target and existing.target.enabled or false,
        },
        {
            type = 'input',
            label = 'Interaction label',
            description = 'Example: Talk to Receptionist',
            default = existing.target and existing.target.label or Config.Defaults.targetLabel,
        },
        {
            type = 'input',
            label = 'Interaction icon',
            default = existing.target and existing.target.icon or Config.Defaults.targetIcon,
        },
        {
            type = 'input',
            label = 'Client event to trigger',
            description = 'Optional advanced hook, e.g. myresource:client:openShop',
            default = existing.target and existing.target.event or '',
        },
    }, { size = 'lg' })

    if not input then return nil end

    local preset = getActivityPreset(input[1])
    local scenario, animDict, animName, animFlag = '', '', '', Config.Defaults.animFlag

    if preset.type == 'scenario' then
        scenario = preset.scenario or ''
    elseif preset.type == 'anim' then
        animDict = preset.dict or ''
        animName = preset.name or ''
        animFlag = preset.flag or Config.Defaults.animFlag
    elseif preset.type == 'advanced' then
        local advanced = lib.inputDialog('Advanced Custom Animation', {
            {
                type = 'input',
                label = 'Animation dictionary',
                description = 'Only use this if you know the GTA/FiveM animation dictionary.',
                default = existing.animDict or '',
                required = true,
            },
            {
                type = 'input',
                label = 'Animation name',
                description = 'The clip/name inside that animation dictionary.',
                default = existing.animName or '',
                required = true,
            },
            {
                type = 'number',
                label = 'Animation flag',
                description = 'Normally 1 for a looping stationary animation, or 49 for some upper-body/prop animations.',
                default = existing.animFlag or Config.Defaults.animFlag,
                min = 0,
                max = 51,
            },
        })

        if not advanced then return nil end
        animDict = advanced[1] or ''
        animName = advanced[2] or ''
        animFlag = tonumber(advanced[3]) or Config.Defaults.animFlag
    end

    return {
        scenario = scenario,
        animDict = animDict,
        animName = animName,
        animFlag = animFlag,
        invincible = input[2] == true,
        frozen = input[3] == true,
        blockEvents = input[4] == true,
        canRagdoll = input[5] == true,
        collision = input[6] == true,
        spawnDistance = tonumber(input[7]) or Config.Defaults.spawnDistance,
        target = {
            enabled = input[8] == true,
            label = input[9] or Config.Defaults.targetLabel,
            icon = input[10] or Config.Defaults.targetIcon,
            event = input[11] or '',
        }
    }
end

local function pedModelOptions(existingModel)
    local options = {}
    local hasExisting = not existingModel

    for i = 1, #PedCatalog do
        local ped = PedCatalog[i]
        options[#options + 1] = {
            label = ('%s — %s'):format(ped.model, ped.label),
            value = ped.model,
        }

        if existingModel and ped.model == existingModel then
            hasExisting = true
        end
    end

    if existingModel and not hasExisting then
        options[#options + 1] = {
            label = ('%s — Current saved model'):format(existingModel),
            value = existingModel,
        }
    end

    table.sort(options, function(a, b)
        return a.label:lower() < b.label:lower()
    end)

    return options
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
            type = 'select',
            label = 'Ped model',
            description = 'Choose a Cfx.re/FiveM ped model. Start typing a model name to instantly filter the list.',
            options = pedModelOptions(existing and existing.model or nil),
            default = existing and existing.model or nil,
            searchable = true,
            -- Do not open the model list just because the field receives focus.
            -- Clicking the field opens it; typing still opens and filters matches.
            openOnFocus = false,
            placeholder = 'Click to choose or type to search...',
            clearable = false,
            required = true,
        },
    })

    if not initial then return nil end

    local name = initial[1]
    local model = initial[2]

    if not model or model == '' then
        NPCManager.Notify('Please select a ped model.', 'error')
        return nil
    end

    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) or not IsModelAPed(hash) then
        NPCManager.Notify('That ped model is invalid.', 'error')
        return nil
    end

    local coords = existing and existing.coords or nil
    if not existing or replacingPosition then
        local existingCoords = existing and existing.coords or nil
        coords = NPCManager.PlacePed(model, replacingPosition and existingCoords or nil)
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

    local response = lib.callback.await('hf1_npcs:server:createNpc', false, data)
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

    local response = lib.callback.await('hf1_npcs:server:updateNpc', false, data)
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

    local response = lib.callback.await('hf1_npcs:server:updateNpc', false, updated)
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

    local response = lib.callback.await('hf1_npcs:server:createNpc', false, copy)
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

    local response = lib.callback.await('hf1_npcs:server:deleteNpc', false, npc.id)
    if response and response.ok then
        NPCManager.Notify(('NPC #%s deleted.'):format(npc.id), 'success')
    else
        NPCManager.Notify(response and response.message or 'Failed to delete NPC.', 'error')
    end
end

local function openNpcActions(npc)
    lib.registerContext({
        id = 'hf1_npcs_actions',
        title = ('#%s - %s'):format(npc.id, npc.name),
        menu = 'hf1_npcs_manage',
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

    lib.showContext('hf1_npcs_actions')
end

local function manageNpcs()
    local list = lib.callback.await('hf1_npcs:server:getNpcs', false) or {}
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
        id = 'hf1_npcs_manage',
        title = ('Manage NPCs (%s)'):format(#options),
        menu = 'hf1_npcs_main',
        options = options
    })
    lib.showContext('hf1_npcs_manage')
end

function NPCManager.OpenMainMenu()
    if not NPCManager.HasAccess() then
        NPCManager.Notify('You do not have permission to use the NPC Manager.', 'error')
        return
    end

    lib.registerContext({
        id = 'hf1_npcs_main',
        title = 'HF1 NPCs',
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
                    TriggerServerEvent('hf1_npcs:server:requestSync')
                    NPCManager.Notify('NPC cache refreshed.', 'success')
                end,
            },
        }
    })

    lib.showContext('hf1_npcs_main')
end
