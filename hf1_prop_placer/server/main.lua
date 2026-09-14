local propCache = {}
local databaseReady = false

local function sanitizeString(value, maxLength)
    if type(value) ~= 'string' then return '' end
    value = value:match('^%s*(.-)%s*$') or ''
    if #value > maxLength then value = value:sub(1, maxLength) end
    return value
end

local function finiteNumber(value, fallback)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then
        return fallback or 0.0
    end
    return value + 0.0
end

local function sanitizeProp(data)
    if type(data) ~= 'table' then return nil end
    local name = sanitizeString(data.name, 100)
    local model = sanitizeString(data.model, 120)
    local coords = type(data.coords) == 'table' and data.coords or {}
    local rotation = type(data.rotation) == 'table' and data.rotation or {}

    if name == '' or model == '' then return nil end

    return {
        name = name,
        model = model,
        coords = {
            x = finiteNumber(coords.x),
            y = finiteNumber(coords.y),
            z = finiteNumber(coords.z),
        },
        rotation = {
            x = finiteNumber(rotation.x),
            y = finiteNumber(rotation.y),
            z = finiteNumber(rotation.z),
        },
        frozen = data.frozen ~= false,
        collision = data.collision ~= false,
    }
end

local function dbBool(value, default)
    if value == nil then return default == true end
    if type(value) == 'boolean' then return value end
    if type(value) == 'number' then return value ~= 0 end

    if type(value) == 'string' then
        local normalized = value:lower():match('^%s*(.-)%s*$')
        if normalized == '1' or normalized == 'true' or normalized == 'yes' or normalized == 'on' then
            return true
        end
        if normalized == '0' or normalized == 'false' or normalized == 'no' or normalized == 'off' or normalized == '' then
            return false
        end

        local numeric = tonumber(normalized)
        if numeric ~= nil then return numeric ~= 0 end
    end

    return default == true
end

local function rowToDefinition(row)
    return {
        id = tonumber(row.id),
        name = tostring(row.name),
        model = tostring(row.model),
        coords = { x = tonumber(row.x) or 0.0, y = tonumber(row.y) or 0.0, z = tonumber(row.z) or 0.0 },
        rotation = { x = tonumber(row.rot_x) or 0.0, y = tonumber(row.rot_y) or 0.0, z = tonumber(row.rot_z) or 0.0 },
        frozen = dbBool(row.frozen, true),
        collision = dbBool(row.collision, true),
    }
end

local function loadCache()
    local rows = HF1PropDatabase.LoadAll()
    propCache = {}
    for i = 1, #rows do
        local def = rowToDefinition(rows[i])
        propCache[def.id] = def
    end
    print(('[hf1_prop_placer] Loaded %d persistent props from database.'):format(#rows))
end

local function cacheAsArray()
    local out = {}
    for _, def in pairs(propCache) do out[#out + 1] = def end
    table.sort(out, function(a, b) return a.id < b.id end)
    return out
end

MySQL.ready(function()
    HF1PropDatabase.EnsureTable()
    loadCache()
    databaseReady = true
end)

lib.callback.register('hf1_prop_placer:server:hasAccess', function(source)
    return HF1PropPermissions.HasAccess(source)
end)

lib.callback.register('hf1_prop_placer:server:searchModels', function(source, query, categoryIndex)
    if not HF1PropPermissions.HasAccess(source) then return nil end
    query = sanitizeString(query or '', 80)
    if query ~= '' and #query < (Config.Catalogue.MinimumSearchLength or 2) then
        return { items = {}, total = 0, truncated = false, tooShort = true, catalogueSize = HF1PropCatalogue.GetStatus().count }
    end
    return HF1PropCatalogue.Search(query, categoryIndex)
end)

lib.callback.register('hf1_prop_placer:server:catalogueStatus', function(source)
    if not HF1PropPermissions.HasAccess(source) then return nil end
    return HF1PropCatalogue.GetStatus()
end)

RegisterNetEvent('hf1_prop_placer:server:requestCache', function()
    local src = source
    if not databaseReady then
        CreateThread(function()
            local attempts = 0
            while not databaseReady and attempts < 50 do Wait(100); attempts = attempts + 1 end
            TriggerClientEvent('hf1_prop_placer:client:setCache', src, cacheAsArray())
        end)
        return
    end
    TriggerClientEvent('hf1_prop_placer:client:setCache', src, cacheAsArray())
end)

RegisterNetEvent('hf1_prop_placer:server:create', function(data)
    local src = source
    if not HF1PropPermissions.HasAccess(src) then return end
    local clean = sanitizeProp(data)
    if not clean then return end

    local id = HF1PropDatabase.Insert(clean, HF1PropPermissions.GetCreatorIdentifier(src))
    if not id then
        TriggerClientEvent('hf1_prop_placer:client:notify', src, 'Unable to save prop to the database.', 'error')
        return
    end

    clean.id = tonumber(id)
    propCache[clean.id] = clean
    TriggerClientEvent('hf1_prop_placer:client:upsert', -1, clean)
    TriggerClientEvent('hf1_prop_placer:client:notify', src, ('Saved prop "%s".'):format(clean.name), 'success')
end)

RegisterNetEvent('hf1_prop_placer:server:update', function(id, data)
    local src = source
    if not HF1PropPermissions.HasAccess(src) then return end
    id = tonumber(id)
    if not id or not propCache[id] then return end
    local clean = sanitizeProp(data)
    if not clean then return end

    HF1PropDatabase.Update(id, clean)
    clean.id = id
    propCache[id] = clean
    TriggerClientEvent('hf1_prop_placer:client:upsert', -1, clean)
    TriggerClientEvent('hf1_prop_placer:client:notify', src, ('Updated prop "%s".'):format(clean.name), 'success')
end)

RegisterNetEvent('hf1_prop_placer:server:delete', function(id)
    local src = source
    if not HF1PropPermissions.HasAccess(src) then return end
    id = tonumber(id)
    local existing = id and propCache[id]
    if not existing then return end

    HF1PropDatabase.Delete(id)
    propCache[id] = nil
    TriggerClientEvent('hf1_prop_placer:client:remove', -1, id)
    TriggerClientEvent('hf1_prop_placer:client:notify', src, ('Deleted prop "%s".'):format(existing.name), 'success')
end)

RegisterNetEvent('hf1_prop_placer:server:reload', function()
    local src = source
    if not HF1PropPermissions.HasAccess(src) then return end
    loadCache()
    TriggerClientEvent('hf1_prop_placer:client:setCache', -1, cacheAsArray())
    TriggerClientEvent('hf1_prop_placer:client:notify', src, 'Props reloaded from the database.', 'success')
end)
