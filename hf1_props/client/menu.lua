local function notify(message, kind)
    lib.notify({ title = 'Prop Admin', description = message, type = kind or 'inform' })
end

local function trim(value)
    if type(value) ~= 'string' then return '' end
    return value:match('^%s*(.-)%s*$') or ''
end

local function copyDefinition(def)
    return {
        id = def.id,
        name = def.name,
        model = def.model,
        coords = { x = def.coords.x, y = def.coords.y, z = def.coords.z },
        rotation = { x = def.rotation.x, y = def.rotation.y, z = def.rotation.z },
        frozen = def.frozen ~= false,
        collision = def.collision ~= false,
    }
end

local function chooseFromResults(result, title)
    if not result or not result.items or #result.items == 0 then
        notify('No matching prop models found.', 'warning')
        return nil
    end

    local options = {}
    for i = 1, #result.items do
        local model = result.items[i]
        options[#options + 1] = { label = model, value = model }
    end

    local description = ('%d match%s'):format(result.total or #options, (result.total or #options) == 1 and '' or 'es')
    if result.truncated then
        description = description .. ('. Showing first %d — refine your search for more.'):format(#options)
    end

    local selected = lib.inputDialog(title or 'Choose Prop Model', {
        {
            type = 'select',
            label = 'Prop model',
            description = description,
            searchable = true,
            required = true,
            options = options,
        }
    })

    return selected and selected[1] or nil
end

local function chooseModel()
    local method = lib.inputDialog('Prop Model', {
        {
            type = 'select',
            label = 'How do you want to find the prop?',
            required = true,
            options = {
                { label = 'Search all props', value = 'search', icon = 'fa-solid fa-magnifying-glass' },
                { label = 'Browse by category', value = 'category', icon = 'fa-solid fa-layer-group' },
                { label = 'Custom / Streamed prop model', value = 'custom', icon = 'fa-solid fa-plus' },
            },
        }
    })
    if not method then return nil end

    if method[1] == 'custom' then
        local custom = lib.inputDialog('Custom / Streamed Prop', {
            {
                type = 'input',
                label = 'Prop model name',
                description = 'Enter the exact spawn/model name from the streamed prop resource.',
                placeholder = 'example_custom_prop',
                required = true,
            }
        })
        return custom and trim(custom[1]) or nil
    end

    if method[1] == 'search' then
        local search = lib.inputDialog('Search All Props', {
            {
                type = 'input',
                label = 'Search',
                description = ('Type at least %d characters. Example: vend, bench, laptop, barrier.'):format(Config.Catalogue.MinimumSearchLength or 2),
                required = true,
            }
        })
        if not search then return nil end
        local query = trim(search[1]):lower()
        if #query < (Config.Catalogue.MinimumSearchLength or 2) then
            notify(('Please type at least %d characters.'):format(Config.Catalogue.MinimumSearchLength or 2), 'warning')
            return nil
        end
        local result = lib.callback.await('hf1_props:server:searchModels', false, query, nil)
        return chooseFromResults(result, ('Results for "%s"'):format(query))
    end

    local categoryOptions = {}
    for i = 1, #Config.PropCategories do
        local cat = Config.PropCategories[i]
        categoryOptions[#categoryOptions + 1] = { label = cat.label, value = i, icon = cat.icon }
    end

    local category = lib.inputDialog('Browse Prop Categories', {
        { type = 'select', label = 'Category', required = true, options = categoryOptions },
        {
            type = 'input',
            label = 'Optional filter',
            description = 'Narrow this category further, e.g. small, wood, red, table.',
            required = false,
        }
    })
    if not category then return nil end

    local result = lib.callback.await('hf1_props:server:searchModels', false, trim(category[2] or ''), tonumber(category[1]))
    return chooseFromResults(result, Config.PropCategories[tonumber(category[1])].label)
end

local function ensureValidModel(model)
    local valid, reason = HF1Props.ValidateModel(model)
    if not valid then
        notify(reason, 'error')
        return false
    end
    return true
end

local function createNewProp()
    local input = lib.inputDialog('New Prop', {
        {
            type = 'input',
            label = 'Prop name',
            description = 'Friendly admin name, e.g. Pillbox Lobby Vending Machine.',
            required = true,
            min = 1,
            max = 100,
        },
        {
            type = 'checkbox',
            label = 'Freeze in place',
            checked = true,
        },
        {
            type = 'checkbox',
            label = 'Collision enabled',
            checked = true,
        }
    })
    if not input then return end

    local name = trim(input[1])
    if name == '' then return end

    local model = chooseModel()
    if not model or model == '' then return end
    if not ensureValidModel(model) then return end

    notify('Place the prop. Left-click locks the mouse position; Enter saves.', 'inform')
    local placement = HF1PropPlacement.Place(model)
    if not placement then
        notify('Prop placement cancelled.', 'warning')
        return
    end

    TriggerServerEvent('hf1_props:server:create', {
        name = name,
        model = model,
        coords = placement.coords,
        rotation = placement.rotation,
        frozen = input[2] == true,
        collision = input[3] == true,
    })
end

local openManageProp
local openManageList

local function saveDefinition(def)
    TriggerServerEvent('hf1_props:server:update', def.id, def)
end

openManageProp = function(id)
    local original = HF1Props.GetDefinition(id)
    if not original then
        notify('That prop no longer exists.', 'warning')
        return
    end
    local def = copyDefinition(original)

    lib.registerContext({
        id = 'hf1_props_manage_one',
        title = def.name,
        menu = 'hf1_props_manage_list',
        options = {
            {
                title = 'Reposition / Rotate',
                description = 'Move this prop using the placement controls.',
                icon = 'fa-solid fa-up-down-left-right',
                onSelect = function()
                    if not ensureValidModel(def.model) then return end
                    local placement = HF1PropPlacement.Place(def.model, def)
                    if not placement then return end
                    def.coords = placement.coords
                    def.rotation = placement.rotation
                    saveDefinition(def)
                end,
            },
            {
                title = 'Rename',
                description = def.name,
                icon = 'fa-solid fa-pen',
                onSelect = function()
                    local result = lib.inputDialog('Rename Prop', {
                        { type = 'input', label = 'Name', default = def.name, required = true, max = 100 }
                    })
                    if not result then return end
                    def.name = trim(result[1])
                    if def.name ~= '' then saveDefinition(def) end
                end,
            },
            {
                title = 'Change Model',
                description = def.model,
                icon = 'fa-solid fa-cube',
                onSelect = function()
                    local model = chooseModel()
                    if not model or not ensureValidModel(model) then return end
                    def.model = model
                    saveDefinition(def)
                end,
            },
            {
                title = def.frozen and 'Frozen: ON' or 'Frozen: OFF',
                description = 'Toggle whether physics can move this prop.',
                icon = def.frozen and 'fa-solid fa-lock' or 'fa-solid fa-lock-open',
                onSelect = function()
                    def.frozen = not def.frozen
                    saveDefinition(def)
                end,
            },
            {
                title = def.collision and 'Collision: ON' or 'Collision: OFF',
                description = 'Toggle collision for this prop.',
                icon = 'fa-solid fa-object-group',
                onSelect = function()
                    def.collision = not def.collision
                    saveDefinition(def)
                end,
            },
            {
                title = 'Teleport To Prop',
                description = ('%.2f, %.2f, %.2f'):format(def.coords.x, def.coords.y, def.coords.z),
                icon = 'fa-solid fa-location-dot',
                onSelect = function()
                    SetEntityCoords(PlayerPedId(), def.coords.x, def.coords.y, def.coords.z + 1.0, false, false, false, false)
                end,
            },
            {
                title = 'Delete Prop',
                description = 'Permanently remove this prop from the database.',
                icon = 'fa-solid fa-trash',
                iconColor = '#ef4444',
                onSelect = function()
                    local confirm = lib.alertDialog({
                        header = 'Delete Prop?',
                        content = ('Delete **%s** (`%s`)?\n\nThis removes it for everyone.'):format(def.name, def.model),
                        centered = true,
                        cancel = true,
                        labels = { confirm = 'Delete', cancel = 'Cancel' },
                    })
                    if confirm == 'confirm' then
                        TriggerServerEvent('hf1_props:server:delete', def.id)
                    end
                end,
            },
        }
    })
    lib.showContext('hf1_props_manage_one')
end

openManageList = function(filter)
    filter = trim(filter or ''):lower()
    local list = {}
    for _, def in pairs(HF1Props.GetDefinitions()) do
        if filter == '' or def.name:lower():find(filter, 1, true) or def.model:lower():find(filter, 1, true) then
            list[#list + 1] = def
        end
    end
    table.sort(list, function(a, b) return a.name:lower() < b.name:lower() end)

    local options = {
        {
            title = filter == '' and 'Search / Filter' or ('Filter: ' .. filter),
            description = 'Search by saved prop name or model.',
            icon = 'fa-solid fa-magnifying-glass',
            onSelect = function()
                local result = lib.inputDialog('Search Saved Props', {
                    { type = 'input', label = 'Search', default = filter, required = false }
                })
                if result then openManageList(result[1] or '') end
            end,
        },
        {
            title = 'Clear Search',
            icon = 'fa-solid fa-xmark',
            disabled = filter == '',
            onSelect = function() openManageList('') end,
        }
    }

    local limit = math.min(#list, 150)
    for i = 1, limit do
        local def = list[i]
        local id = def.id
        options[#options + 1] = {
            title = def.name,
            description = ('%s  •  ID %s'):format(def.model, def.id),
            icon = 'fa-solid fa-cube',
            onSelect = function() openManageProp(id) end,
        }
    end

    if #list > limit then
        options[#options + 1] = {
            title = ('%d more props not shown'):format(#list - limit),
            description = 'Use Search / Filter to narrow the list.',
            icon = 'fa-solid fa-circle-info',
            disabled = true,
        }
    elseif #list == 0 then
        options[#options + 1] = {
            title = 'No matching props',
            description = filter == '' and 'No persistent props have been created yet.' or 'Try another search.',
            icon = 'fa-solid fa-circle-info',
            disabled = true,
        }
    end

    lib.registerContext({
        id = 'hf1_props_manage_list',
        title = ('Manage Props (%d)'):format(#list),
        menu = 'hf1_props_admin',
        options = options,
    })
    lib.showContext('hf1_props_manage_list')
end

local function openAdminMenu()
    local allowed = lib.callback.await('hf1_props:server:hasAccess', false)
    if not allowed then
        notify('You do not have permission to use Prop Admin.', 'error')
        return
    end

    local status = lib.callback.await('hf1_props:server:catalogueStatus', false) or {}
    local count = status.count or 0
    local statusText = count > 0 and (('%s models available'):format(count)) or 'Catalogue loading...'

    lib.registerContext({
        id = 'hf1_props_admin',
        title = 'Prop Admin',
        options = {
            {
                title = 'New Prop',
                description = 'Choose a model, place it precisely, and save it for everyone.',
                icon = 'fa-solid fa-plus',
                onSelect = createNewProp,
            },
            {
                title = 'Manage Props',
                description = 'Search, edit, reposition, teleport to, or delete saved props.',
                icon = 'fa-solid fa-cubes',
                onSelect = function() openManageList('') end,
            },
            {
                title = 'Reload Props',
                description = 'Reload all prop definitions from the database and resync clients.',
                icon = 'fa-solid fa-rotate',
                onSelect = function()
                    TriggerServerEvent('hf1_props:server:reload')
                end,
            },
            {
                title = 'Prop Catalogue',
                description = statusText,
                icon = 'fa-solid fa-database',
                disabled = true,
            },
        }
    })
    lib.showContext('hf1_props_admin')
end

RegisterCommand(Config.Command, function()
    openAdminMenu()
end, false)
