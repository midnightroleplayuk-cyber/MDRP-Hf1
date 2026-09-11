NPCManager = NPCManager or {}

local function boolDefault(value, fallback)
    if value == nil then return fallback end
    return value == true
end


local InteractionIcons = {
    { label = 'Talk / Conversation', value = 'fa-solid fa-comments', icon = 'fa-solid fa-comments' },
    { label = 'Person / General interaction', value = 'fa-solid fa-user', icon = 'fa-solid fa-user' },
    { label = 'Information / Help', value = 'fa-solid fa-circle-info', icon = 'fa-solid fa-circle-info' },
    { label = 'Shop / Store', value = 'fa-solid fa-store', icon = 'fa-solid fa-store' },
    { label = 'Shopping basket', value = 'fa-solid fa-basket-shopping', icon = 'fa-solid fa-basket-shopping' },
    { label = 'Money / Payment', value = 'fa-solid fa-money-bill', icon = 'fa-solid fa-money-bill' },
    { label = 'Briefcase / Job', value = 'fa-solid fa-briefcase', icon = 'fa-solid fa-briefcase' },
    { label = 'Police / Security', value = 'fa-solid fa-shield-halved', icon = 'fa-solid fa-shield-halved' },
    { label = 'Medical', value = 'fa-solid fa-kit-medical', icon = 'fa-solid fa-kit-medical' },
    { label = 'Garage / Vehicle', value = 'fa-solid fa-car', icon = 'fa-solid fa-car' },
    { label = 'Mechanic / Repair', value = 'fa-solid fa-screwdriver-wrench', icon = 'fa-solid fa-screwdriver-wrench' },
    { label = 'Key / Access', value = 'fa-solid fa-key', icon = 'fa-solid fa-key' },
    { label = 'House / Property', value = 'fa-solid fa-house', icon = 'fa-solid fa-house' },
    { label = 'Food', value = 'fa-solid fa-utensils', icon = 'fa-solid fa-utensils' },
    { label = 'Drink / Bar', value = 'fa-solid fa-martini-glass', icon = 'fa-solid fa-martini-glass' },
    { label = 'Phone', value = 'fa-solid fa-phone', icon = 'fa-solid fa-phone' },
    { label = 'Clipboard / Tasks', value = 'fa-solid fa-clipboard', icon = 'fa-solid fa-clipboard' },
    { label = 'Package / Delivery', value = 'fa-solid fa-box', icon = 'fa-solid fa-box' },
    { label = 'Map / Travel', value = 'fa-solid fa-map-location-dot', icon = 'fa-solid fa-map-location-dot' },
    { label = 'Question / Ask', value = 'fa-solid fa-circle-question', icon = 'fa-solid fa-circle-question' },
}

local function interactionIconOptions(existingIcon)
    local options, found = {}, false
    for i = 1, #InteractionIcons do
        local option = InteractionIcons[i]
        options[#options + 1] = option
        if option.value == existingIcon then found = true end
    end

    if existingIcon and existingIcon ~= '' and not found then
        table.insert(options, 1, {
            label = ('Current/custom icon — %s'):format(existingIcon),
            value = existingIcon,
            icon = existingIcon,
        })
    end

    return options
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

local function interactionModeForExisting(existing)
    existing = existing or {}
    local target = existing.target or {}
    if not target.enabled then return 'none' end
    if target.mode == 'talk' or (existing.dialogue and existing.dialogue.enabled) then return 'talk' end
    return 'event'
end

local ReplyIcons = {
    { label = 'Reply / Conversation', value = 'fa-solid fa-reply', icon = 'fa-solid fa-reply' },
    { label = 'Continue / Next', value = 'fa-solid fa-arrow-right', icon = 'fa-solid fa-arrow-right' },
    { label = 'Information', value = 'fa-solid fa-circle-info', icon = 'fa-solid fa-circle-info' },
    { label = 'Question', value = 'fa-solid fa-circle-question', icon = 'fa-solid fa-circle-question' },
    { label = 'Shop', value = 'fa-solid fa-store', icon = 'fa-solid fa-store' },
    { label = 'Money / Payment', value = 'fa-solid fa-money-bill', icon = 'fa-solid fa-money-bill' },
    { label = 'Job / Briefcase', value = 'fa-solid fa-briefcase', icon = 'fa-solid fa-briefcase' },
    { label = 'Vehicle / Garage', value = 'fa-solid fa-car', icon = 'fa-solid fa-car' },
    { label = 'Police / Security', value = 'fa-solid fa-shield-halved', icon = 'fa-solid fa-shield-halved' },
    { label = 'Medical', value = 'fa-solid fa-kit-medical', icon = 'fa-solid fa-kit-medical' },
    { label = 'Key / Access', value = 'fa-solid fa-key', icon = 'fa-solid fa-key' },
    { label = 'Package / Delivery', value = 'fa-solid fa-box', icon = 'fa-solid fa-box' },
    { label = 'Goodbye / Leave', value = 'fa-solid fa-door-open', icon = 'fa-solid fa-door-open' },
}

local function replyIconOptions(existingIcon)
    local options, found = {}, false
    for i = 1, #ReplyIcons do
        local option = ReplyIcons[i]
        options[#options + 1] = option
        if option.value == existingIcon then found = true end
    end
    if existingIcon and existingIcon ~= '' and not found then
        table.insert(options, 1, { label = ('Current/custom icon — %s'):format(existingIcon), value = existingIcon, icon = existingIcon })
    end
    return options
end

local function replyActionForExisting(reply)
    if reply.action and reply.action ~= '' then return reply.action end
    if reply.nextStep and tonumber(reply.nextStep) then return 'branch' end
    if reply.event and reply.event ~= '' then return 'client_event' end
    if reply.close == false then return 'back' end
    return 'close'
end


local function conditionForExisting(reply)
    local condition = type(reply.condition) == 'table' and reply.condition or {}
    return condition.type or 'always'
end

local function conditionVisibilityForExisting(reply)
    local condition = type(reply.condition) == 'table' and reply.condition or {}
    return condition.visibility == 'locked' and 'locked' or 'hidden'
end

local function editReplyCondition(old)
    old = type(old) == 'table' and old or {}
    local existing = type(old.condition) == 'table' and old.condition or {}

    local choice = lib.inputDialog('Reply Requirement', {
        {
            type = 'select', label = 'Show this reply when...',
            description = 'Choose who should be able to use this response.',
            options = {
                { label = 'Always available', value = 'always' },
                { label = 'Player has a job / group (minimum grade)', value = 'group' },
                { label = 'Player has an item', value = 'item' },
                { label = 'Player does NOT have an item', value = 'no_item' },
                { label = 'Player has enough cash', value = 'cash' },
                { label = 'Player has enough bank money', value = 'bank' },
            },
            default = conditionForExisting(old), clearable = false, required = true,
        },
        {
            type = 'select', label = 'If requirement is not met',
            description = 'Hide the reply completely, or show it locked with the requirement.',
            options = {
                { label = 'Hide the reply', value = 'hidden' },
                { label = 'Show it locked', value = 'locked' },
            },
            default = conditionVisibilityForExisting(old), clearable = false, required = true,
        },
    }, { size = 'md' })
    if not choice then return nil end

    local ctype = choice[1] or 'always'
    local condition = { type = ctype, visibility = choice[2] or 'hidden', name = '', amount = 0 }
    if ctype == 'always' then return condition end

    if ctype == 'group' then
        local detail = lib.inputDialog('Job / Group Requirement', {
            { type = 'input', label = 'Job / group name', description = 'Example: police, ambulance, mechanic', default = existing.name or '', required = true, max = 80 },
            { type = 'number', label = 'Minimum grade', description = '0 allows every grade in that job/group.', default = tonumber(existing.amount) or 0, min = 0, max = 100, required = true },
        })
        if not detail then return nil end
        condition.name = detail[1] or ''
        condition.amount = math.floor(tonumber(detail[2]) or 0)
    elseif ctype == 'item' or ctype == 'no_item' then
        local detail = lib.inputDialog(ctype == 'item' and 'Item Requirement' or 'Missing Item Requirement', {
            { type = 'input', label = 'Item name', description = 'Use the item spawn name, e.g. water or lockpick.', default = existing.name or '', required = true, max = 80 },
            { type = 'number', label = ctype == 'item' and 'Minimum amount' or 'Check amount', default = math.max(1, tonumber(existing.amount) or 1), min = 1, max = 100000, required = true },
        })
        if not detail then return nil end
        condition.name = detail[1] or ''
        condition.amount = math.floor(tonumber(detail[2]) or 1)
    elseif ctype == 'cash' or ctype == 'bank' then
        local detail = lib.inputDialog(ctype == 'cash' and 'Cash Requirement' or 'Bank Requirement', {
            { type = 'number', label = 'Minimum amount', description = 'This only checks the balance; it does not remove money.', default = math.max(0, tonumber(existing.amount) or 0), min = 0, max = 100000000, required = true },
        })
        if not detail then return nil end
        condition.amount = math.floor(tonumber(detail[1]) or 0)
    end

    return condition
end

local function editDialogueReply(old, replyNumber, stepCount)
    old = old or {}
    local basic = lib.inputDialog(('Reply %s'):format(replyNumber), {
        {
            type = 'input', label = 'Player reply text',
            description = 'The response option shown to the player.',
            default = old.label or '', placeholder = 'Example: Show me what you have.', required = true, min = 1, max = 120,
        },
        {
            type = 'select', label = 'Reply icon',
            description = 'Pick a visual hint for this response.',
            options = replyIconOptions(old.icon or 'fa-solid fa-reply'),
            default = old.icon or 'fa-solid fa-reply', searchable = true, clearable = false, required = true,
        },
        {
            type = 'textarea', label = 'NPC response before action',
            description = 'Optional. The NPC can say this before the selected action happens.',
            default = old.response or '', max = 500, autosize = true,
        },
        {
            type = 'select', label = 'What should this reply do?',
            description = 'Choose the result without needing to know Lua.',
            options = {
                { label = 'Continue to another dialogue step', value = 'branch' },
                { label = 'Trigger a client event', value = 'client_event' },
                { label = 'Trigger a server event', value = 'server_event' },
                { label = 'Run a command', value = 'command' },
                { label = 'Return to this conversation', value = 'back' },
                { label = 'Close conversation', value = 'close' },
            },
            default = replyActionForExisting(old), clearable = false, required = true,
        },
    }, { size = 'md' })
    if not basic then return nil end

    local action = basic[4] or 'close'
    local result = {
        label = basic[1] or '', icon = basic[2] or 'fa-solid fa-reply', response = basic[3] or '',
        action = action, event = '', command = '', nextStep = nil, close = action ~= 'back' and action ~= 'branch',
    }

    if action == 'branch' then
        if stepCount < 1 then
            NPCManager.Notify('Add at least one extra dialogue step before using Continue to another dialogue step.', 'error')
            return editDialogueReply(old, replyNumber, stepCount)
        end
        local stepOptions = {}
        for i = 1, stepCount do stepOptions[#stepOptions + 1] = { label = ('Dialogue Step %s'):format(i), value = i } end
        local branch = lib.inputDialog('Continue Conversation', {
            { type = 'select', label = 'Go to dialogue step', options = stepOptions, default = tonumber(old.nextStep) or 1, clearable = false, required = true },
        })
        if not branch then return nil end
        result.nextStep = tonumber(branch[1]) or 1
    elseif action == 'client_event' or action == 'server_event' then
        local hook = lib.inputDialog(action == 'server_event' and 'Server Event' or 'Client Event', {
            {
                type = 'input', label = action == 'server_event' and 'Server event name' or 'Client event name',
                description = 'Example: myresource:server:openSomething',
                default = old.event or '', required = true, max = 120,
            },
        })
        if not hook then return nil end
        result.event = hook[1] or ''
    elseif action == 'command' then
        local command = lib.inputDialog('Run Command', {
            {
                type = 'input', label = 'Command',
                description = 'Enter the command without the leading slash. Example: jobs',
                default = old.command or '', required = true, max = 120,
            },
        })
        if not command then return nil end
        result.command = (command[1] or ''):gsub('^/', '')
    end

    local condition = editReplyCondition(old)
    if not condition then return nil end
    result.condition = condition

    return result
end

local function editDialogueStep(old, stepNumber, stepCount)
    old = old or {}
    local oldReplies = old.replies or {}
    local setup = lib.inputDialog(('Dialogue Step %s'):format(stepNumber), {
        {
            type = 'textarea', label = 'NPC line',
            description = 'What the NPC says when the conversation reaches this step.',
            default = old.text or '', required = true, min = 1, max = 500, autosize = true,
        },
        {
            type = 'number', label = 'Number of player replies',
            default = math.max(1, math.min(4, #oldReplies > 0 and #oldReplies or 1)), min = 1, max = 4, required = true,
        },
    }, { size = 'md' })
    if not setup then return nil end

    local step = { text = setup[1] or '', replies = {} }
    local count = math.floor(tonumber(setup[2]) or 1)
    for i = 1, count do
        local reply = editDialogueReply(oldReplies[i], i, stepCount)
        if not reply then return nil end
        step.replies[#step.replies + 1] = reply
    end
    return step
end

local function buildDialogue(existing)
    existing = existing or {}
    local dialogue = existing.dialogue or {}
    local replies = dialogue.replies or {}
    local oldSteps = dialogue.steps or {}

    local basic = lib.inputDialog('Talk to NPC', {
        {
            type = 'textarea', label = 'NPC opening line',
            description = 'What the NPC says when a player first chooses Talk.',
            default = dialogue.text or ('Hello, I am %s. How can I help?'):format(existing.name or 'there'),
            required = true, min = 1, max = 500, autosize = true,
        },
        {
            type = 'number', label = 'Number of opening replies',
            description = 'Reply buttons shown under the opening line.',
            default = math.max(1, math.min(4, #replies > 0 and #replies or 1)), min = 1, max = 4, required = true,
        },
        {
            type = 'number', label = 'Extra dialogue steps',
            description = 'Optional follow-up screens for branching conversations. You can add up to four.',
            default = math.min(4, #oldSteps), min = 0, max = 4, required = true,
        },
    }, { size = 'md' })
    if not basic then return nil end

    local extraCount = math.floor(tonumber(basic[3]) or 0)
    local result = { enabled = true, text = basic[1] or '', replies = {}, steps = {} }

    local openingCount = math.floor(tonumber(basic[2]) or 1)
    for i = 1, openingCount do
        local reply = editDialogueReply(replies[i], i, extraCount)
        if not reply then return nil end
        result.replies[#result.replies + 1] = reply
    end

    for i = 1, extraCount do
        local step = editDialogueStep(oldSteps[i], i, extraCount)
        if not step then return nil end
        result.steps[#result.steps + 1] = step
    end

    return result
end

local function getBehavior(existing, npcName)
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
        { type = 'checkbox', label = 'Invincible', checked = boolDefault(existing.invincible, Config.Defaults.invincible) },
        { type = 'checkbox', label = 'Frozen in place', checked = boolDefault(existing.frozen, Config.Defaults.frozen) },
        { type = 'checkbox', label = 'Ignore nearby events / stay calm', checked = boolDefault(existing.blockEvents, Config.Defaults.blockEvents) },
        { type = 'checkbox', label = 'Can ragdoll', checked = boolDefault(existing.canRagdoll, Config.Defaults.canRagdoll) },
        { type = 'checkbox', label = 'Collision enabled', checked = boolDefault(existing.collision, Config.Defaults.collision) },
        {
            type = 'number',
            label = 'Spawn distance',
            description = 'How close a player should be before this NPC is streamed in.',
            default = existing.spawnDistance or Config.Defaults.spawnDistance,
            min = 25,
            max = 500,
        },
        {
            type = 'select',
            label = 'Player Interaction',
            description = 'None, a built-in Talk to NPC conversation, or an advanced direct client event.',
            options = {
                { label = 'None', value = 'none' },
                { label = 'Talk to NPC', value = 'talk' },
                { label = 'Direct Client Event (Advanced)', value = 'event' },
            },
            default = interactionModeForExisting(existing),
            clearable = false,
            required = true,
        },
        {
            type = 'input',
            label = 'Interaction label',
            description = 'Example: Talk to Receptionist',
            default = existing.target and existing.target.label or Config.Defaults.targetLabel,
            max = 80,
        },
        {
            type = 'select',
            label = 'Interaction icon',
            description = 'Pick an icon by name. The symbol is shown beside each option so you do not need to know Font Awesome names.',
            options = interactionIconOptions(existing.target and existing.target.icon or Config.Defaults.targetIcon),
            default = existing.target and existing.target.icon or Config.Defaults.targetIcon,
            searchable = true,
            clearable = false,
            required = true,
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
            { type = 'input', label = 'Animation dictionary', description = 'Only use this if you know the GTA/FiveM animation dictionary.', default = existing.animDict or '', required = true },
            { type = 'input', label = 'Animation name', description = 'The clip/name inside that animation dictionary.', default = existing.animName or '', required = true },
            { type = 'number', label = 'Animation flag', description = 'Normally 1 for looping stationary animations, or 49 for some upper-body/prop animations.', default = existing.animFlag or Config.Defaults.animFlag, min = 0, max = 51 },
        })
        if not advanced then return nil end
        animDict = advanced[1] or ''
        animName = advanced[2] or ''
        animFlag = tonumber(advanced[3]) or Config.Defaults.animFlag
    end

    local mode = input[8] or 'none'
    local targetEvent = ''
    local dialogue = { enabled = false, text = '', replies = {} }

    if mode == 'talk' then
        local dialogueExisting = {}
        for k, v in pairs(existing) do dialogueExisting[k] = v end
        dialogueExisting.name = npcName or existing.name
        dialogue = buildDialogue(dialogueExisting)
        if not dialogue then return nil end
    elseif mode == 'event' then
        local direct = lib.inputDialog('Direct Client Event', {
            {
                type = 'input',
                label = 'Client event to trigger',
                description = 'Example: myresource:client:openShop',
                default = existing.target and existing.target.event or '',
                required = true,
                max = 120,
            },
        })
        if not direct then return nil end
        targetEvent = direct[1] or ''
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
            enabled = mode ~= 'none',
            mode = mode,
            label = input[9] ~= '' and input[9] or (mode == 'talk' and 'Talk' or Config.Defaults.targetLabel),
            icon = input[10] ~= '' and input[10] or Config.Defaults.targetIcon,
            event = targetEvent,
        },
        dialogue = dialogue,
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
    -- Keep the searchable select before the normal text input. ox_lib's searchable
    -- select can take focus as the dialog mounts; placing the NPC name last leaves
    -- the normal text field as the active field instead of opening the model list.
    local initial = lib.inputDialog(existing and 'Edit NPC' or 'Create NPC', {
        {
            type = 'select',
            label = 'Ped model',
            description = 'Click the box to open the Cfx.re/FiveM ped list, then type to filter it.',
            options = pedModelOptions(existing and existing.model or nil),
            default = existing and existing.model or nil,
            searchable = true,
            placeholder = 'Click to choose or type to search...',
            clearable = false,
            required = true,
        },
        {
            type = 'input',
            label = 'NPC name',
            description = 'Friendly name used in the manager.',
            default = existing and existing.name or '',
            placeholder = 'Enter an NPC name...',
            required = true,
            min = 2,
            max = 100,
        },
    })

    if not initial then return nil end

    local model = initial[1]
    local name = initial[2]

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

    local behavior = getBehavior(existing, name)
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
        dialogue = behavior.dialogue,
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

local function manageNpcs(query)
    local list = lib.callback.await('hf1_npcs:server:getNpcs', false) or {}
    if #list == 0 then
        NPCManager.Notify('There are no saved NPCs yet.', 'inform')
        return
    end

    query = tostring(query or ''):lower()
    local filtered = {}

    for i = 1, #list do
        local npc = list[i]
        local haystack = ('%s %s %s'):format(npc.id, npc.name, npc.model):lower()
        if query == '' or haystack:find(query, 1, true) then
            filtered[#filtered + 1] = npc
        end
    end

    local options = {
        {
            title = query == '' and 'Search / Filter NPCs' or ('Search / Filter NPCs — "%s"'):format(query),
            description = 'Search the list below by NPC name, ped model or ID.',
            icon = 'magnifying-glass',
            onSelect = function()
                local search = lib.inputDialog('Search NPCs', {
                    {
                        type = 'input',
                        label = 'Search',
                        description = 'Type part of a name, model or NPC ID.',
                        placeholder = 'e.g. receptionist, cop, 12',
                        default = query ~= '' and query or '',
                    }
                })

                if not search then
                    manageNpcs(query)
                    return
                end

                manageNpcs(search[1] or '')
            end,
        }
    }

    if query ~= '' then
        options[#options + 1] = {
            title = 'Clear Search',
            description = ('Show all %s saved NPCs again.'):format(#list),
            icon = 'filter-circle-xmark',
            onSelect = function()
                manageNpcs('')
            end,
        }
    end

    if #filtered == 0 then
        options[#options + 1] = {
            title = 'No NPCs matched this search',
            description = 'Try another name, model or ID, or clear the search.',
            icon = 'circle-info',
            disabled = true,
        }
    else
        for i = 1, #filtered do
            local npc = filtered[i]
            options[#options + 1] = {
                title = ('#%s - %s'):format(npc.id, npc.name),
                description = ('%s  |  %.1f, %.1f, %.1f'):format(npc.model, npc.coords.x, npc.coords.y, npc.coords.z),
                icon = 'person',
                onSelect = function()
                    openNpcActions(npc)
                end,
            }
        end
    end

    lib.registerContext({
        id = 'hf1_npcs_manage',
        title = query == ''
            and ('Manage NPCs (%s)'):format(#list)
            or ('Manage NPCs (%s of %s)'):format(#filtered, #list),
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
