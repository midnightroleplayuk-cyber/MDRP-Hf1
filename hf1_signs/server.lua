-- =========================================================
-- HF1 SIGNS - SERVER
-- =========================================================

local function getIdentifier(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return nil end
    return player.PlayerData.citizenid
end

local function hasAdmin(src)
    if not Config.AllowedLicenses then return false end

    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if Config.AllowedLicenses[identifier] == true then
            return true
        end

        if identifier:sub(1, 6) == 'fivem:' then
            if Config.AllowedLicenses['identifier.' .. identifier] == true then
                return true
            end
        elseif identifier:sub(1, 17) == 'identifier.fivem:' then
            if Config.AllowedLicenses[identifier:gsub('^identifier%.', '')] == true then
                return true
            end
        end
    end

    return false
end

local function validUrl(url)
    if type(url) ~= 'string' then return false end
    if #url < 8 or #url > Config.MaxUrlLength then return false end

    local lower = url:lower()

    if Config.RequireHttps and not lower:find('^https://') then
        return false
    end

    local cleanUrl = lower:match('^[^?#]+') or lower
    local extension = cleanUrl:match('(%.[%w]+)$') or ''

    return Config.AllowedImageExtensions[extension] == true
end

local function getAllSigns()
    local query = ([[
        SELECT id, owner, label, image_url,
               x, y, z, width, height, heading,
               normal_x, normal_y, normal_z,
               view_distance
        FROM `%s`
        ORDER BY id DESC
    ]]):format(Config.DatabaseTable)

    return MySQL.query.await(query) or {}
end

local function syncAll()
    TriggerClientEvent('hf1_signs:sync', -1, getAllSigns())
end

RegisterNetEvent('hf1_signs:requestOpen', function()
    local src = source

    if not hasAdmin(src) then
        TriggerClientEvent('hf1_signs:notify', src, 'You do not have permission to use /sign.', 'error')
        return
    end

    TriggerClientEvent('hf1_signs:open', src)
end)

RegisterNetEvent('hf1_signs:requestSync', function()
    local src = source
    TriggerClientEvent('hf1_signs:sync', src, getAllSigns())
end)

RegisterNetEvent('hf1_signs:create', function(data)
    local src = source

    if not hasAdmin(src) then
        TriggerClientEvent('hf1_signs:notify', src, 'You do not have permission to create signs.', 'error')
        return
    end

    if type(data) ~= 'table' or not validUrl(data.image_url) then
        TriggerClientEvent('hf1_signs:notify', src, 'Invalid image URL. Use a direct HTTPS image URL such as a .png.', 'error')
        return
    end

    local owner = getIdentifier(src)
    if not owner then return end

    local x, y, z = tonumber(data.x), tonumber(data.y), tonumber(data.z)
    local width, height = tonumber(data.width), tonumber(data.height)

    if not x or not y or not z or not width or not height then
        TriggerClientEvent('hf1_signs:notify', src, 'Invalid sign position or dimensions.', 'error')
        return
    end

    width = math.max(Config.MinSignSize, math.min(Config.MaxSignSize, width))
    height = math.max(Config.MinSignSize, math.min(Config.MaxSignSize, height))

    local heading = tonumber(data.heading) or 0.0
    local distance = tonumber(data.view_distance) or Config.DefaultViewDistance
    distance = math.max(Config.MinViewDistance, math.min(Config.MaxViewDistance, distance))

    local label = tostring(data.label or 'Custom Sign'):sub(1, 100)

    local query = ([[
        INSERT INTO `%s`
        (owner, label, image_url, x, y, z, width, height, heading,
         normal_x, normal_y, normal_z, view_distance)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]]):format(Config.DatabaseTable)

    local id = MySQL.insert.await(query, {
        owner, label, data.image_url, x, y, z, width, height, heading,
        tonumber(data.normal_x) or 0.0,
        tonumber(data.normal_y) or 1.0,
        tonumber(data.normal_z) or 0.0,
        distance
    })

    if not id then
        TriggerClientEvent('hf1_signs:notify', src, 'Failed to save the sign to the database.', 'error')
        return
    end

    TriggerClientEvent('hf1_signs:notify', src, 'Sign created successfully.', 'success')
    syncAll()
end)

RegisterNetEvent('hf1_signs:update', function(id, data)
    local src = source

    if not hasAdmin(src) then
        TriggerClientEvent('hf1_signs:notify', src, 'You do not have permission to edit signs.', 'error')
        return
    end

    if type(data) ~= 'table' or not validUrl(data.image_url) then
        TriggerClientEvent('hf1_signs:notify', src, 'Invalid image URL. Use a direct HTTPS image URL such as a .png.', 'error')
        return
    end

    local owner = getIdentifier(src)
    id = tonumber(id)
    if not owner or not id then return end

    local distance = tonumber(data.view_distance) or Config.DefaultViewDistance
    distance = math.max(Config.MinViewDistance, math.min(Config.MaxViewDistance, distance))

    local label = tostring(data.label or 'Custom Sign'):sub(1, 100)

    local where = 'id = ?'
    local params = { label, data.image_url, distance, id }

    if Config.OwnershipOnly then
        where = where .. ' AND owner = ?'
        params[#params + 1] = owner
    end

    local query = ([[
        UPDATE `%s`
        SET label = ?, image_url = ?, view_distance = ?
        WHERE %s
    ]]):format(Config.DatabaseTable, where)

    local affected = MySQL.update.await(query, params)

    if affected and affected > 0 then
        TriggerClientEvent('hf1_signs:notify', src, 'Sign updated successfully.', 'success')
        syncAll()
    else
        TriggerClientEvent('hf1_signs:notify', src, 'That sign could not be updated.', 'error')
    end
end)

RegisterNetEvent('hf1_signs:delete', function(id)
    local src = source

    if not hasAdmin(src) then
        TriggerClientEvent('hf1_signs:notify', src, 'You do not have permission to delete signs.', 'error')
        return
    end

    local owner = getIdentifier(src)
    id = tonumber(id)
    if not owner or not id then return end

    local where = 'id = ?'
    local params = { id }

    if Config.OwnershipOnly then
        where = where .. ' AND owner = ?'
        params[#params + 1] = owner
    end

    local query = ([[
        DELETE FROM `%s`
        WHERE %s
    ]]):format(Config.DatabaseTable, where)

    local affected = MySQL.update.await(query, params)

    if affected and affected > 0 then
        TriggerClientEvent('hf1_signs:notify', src, 'Sign deleted successfully.', 'success')
        syncAll()
    else
        TriggerClientEvent('hf1_signs:notify', src, 'That sign could not be deleted.', 'error')
    end
end)


-- =========================================================
-- IMAGE FETCH / CACHE
-- =========================================================
-- The client renderer intentionally does not use DUI. The server fetches the
-- remote image and transfers a base64 data URL only when a nearby client asks.

local remoteImageCache = {}
local pendingImageFetches = {}

local base64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local function base64Encode(data)
    local out = {}
    local len = #data
    local n = 0

    for i = 1, len, 3 do
        local a = data:byte(i) or 0
        local b = data:byte(i + 1) or 0
        local c = data:byte(i + 2) or 0
        local triple = (a << 16) | (b << 8) | c

        n += 1
        out[n] = base64Chars:sub(((triple >> 18) & 63) + 1, ((triple >> 18) & 63) + 1)
        n += 1
        out[n] = base64Chars:sub(((triple >> 12) & 63) + 1, ((triple >> 12) & 63) + 1)
        n += 1
        out[n] = (i + 1 <= len) and base64Chars:sub(((triple >> 6) & 63) + 1, ((triple >> 6) & 63) + 1) or '='
        n += 1
        out[n] = (i + 2 <= len) and base64Chars:sub((triple & 63) + 1, (triple & 63) + 1) or '='
    end

    return table.concat(out)
end

local function guessMime(url, headers)
    if type(headers) == 'table' then
        for key, value in pairs(headers) do
            if tostring(key):lower() == 'content-type' then
                local mime = tostring(value):match('^([^;]+)')
                if mime and mime:find('^image/') then return mime end
            end
        end
    end

    local ext = tostring(url):lower():match('%.([%w]+)[^/]*$')
    if ext == 'jpg' or ext == 'jpeg' then return 'image/jpeg' end
    if ext == 'webp' then return 'image/webp' end
    if ext == 'gif' then return 'image/gif' end
    return 'image/png'
end

local function sendImagePayload(src, id, url, payload)
    -- Latent transfer prevents a larger PNG from choking the normal event channel.
    TriggerLatentClientEvent('hf1_signs:imageData', src, 750000, id, url, payload)
end

RegisterNetEvent('hf1_signs:requestImageData', function(id, url)
    local src = source
    id = tonumber(id)

    if not id or not validUrl(url) then
        TriggerClientEvent('hf1_signs:imageError', src, id, 'invalid image URL')
        return
    end

    local row = MySQL.single.await(([[
        SELECT image_url FROM `%s` WHERE id = ? LIMIT 1
    ]]):format(Config.DatabaseTable), { id })

    if not row or row.image_url ~= url then
        TriggerClientEvent('hf1_signs:imageError', src, id, 'sign URL no longer matches database')
        return
    end

    local cached = remoteImageCache[url]
    if cached then
        sendImagePayload(src, id, url, cached)
        return
    end

    if pendingImageFetches[url] then
        pendingImageFetches[url][#pendingImageFetches[url] + 1] = { src = src, id = id }
        return
    end

    pendingImageFetches[url] = { { src = src, id = id } }

    PerformHttpRequest(url, function(status, body, headers)
        local waiting = pendingImageFetches[url] or {}
        pendingImageFetches[url] = nil

        if status < 200 or status >= 300 or type(body) ~= 'string' or #body == 0 then
            for _, req in ipairs(waiting) do
                TriggerClientEvent('hf1_signs:imageError', req.src, req.id, ('HTTP %s'):format(tostring(status)))
            end
            return
        end

        -- Keep accidental enormous files from becoming multi-megabyte net events.
        if #body > 5 * 1024 * 1024 then
            for _, req in ipairs(waiting) do
                TriggerClientEvent('hf1_signs:imageError', req.src, req.id, 'image is larger than 5 MB')
            end
            return
        end

        local mime = guessMime(url, headers)
        local payload = ('data:%s;base64,%s'):format(mime, base64Encode(body))
        remoteImageCache[url] = payload

        for _, req in ipairs(waiting) do
            sendImagePayload(req.src, req.id, url, payload)
        end
    end, 'GET', '', {
        ['User-Agent'] = 'hf1_signs/1.2.8',
        ['Accept'] = 'image/png,image/jpeg,image/webp,image/gif,*/*;q=0.8'
    })
end)
