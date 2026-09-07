-- QBOX SIGNS
-- SERVER

local function getIdentifier(src)
    local player = exports.qbx_core:GetPlayer(src)

    if not player then
        return nil
    end

    return player.PlayerData.citizenid
end

-- Only identifiers in Config.AllowedLicenses are authorised.
-- Supports both identifier.fivem:123 and fivem:123 formats.
local function hasAdmin(src)
    if not Config.AllowedLicenses then
        return false
    end

    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if Config.AllowedLicenses[identifier] == true then
            return true
        end

        if identifier:sub(1, 6) == 'fivem:' then
            local configuredIdentifier = 'identifier.' .. identifier

            if Config.AllowedLicenses[configuredIdentifier] == true then
                return true
            end
        end

        if identifier:sub(1, 18) == 'identifier.fivem:' then
            local configuredIdentifier = identifier:gsub('^identifier%.', '')

            if Config.AllowedLicenses[configuredIdentifier] == true then
                return true
            end
        end
    end

    return false
end

local function validUrl(url)
    if type(url) ~= 'string' then
        return false
    end

    if #url < 8 or #url > Config.MaxUrlLength then
        return false
    end

    local lower = url:lower()

    if Config.RequireHttps and not lower:find('^https://', 1, true) then
        return false
    end

    local extension = lower:match('(%.[%w]+)') or ''

    return Config.AllowedImageExtensions[extension] == true
end

local function sanitizeNumber(value, fallback)
    value = tonumber(value)

    if not value then
        return fallback
    end

    return value
end

local function getAllSigns()
    local query = ([[
        SELECT id, owner, label, image_url, x, y, z, width, height, heading, view_distance
        FROM `%s`
        ORDER BY id DESC
    ]]):format(Config.DatabaseTable)

    return MySQL.query.await(query) or {}
end

local function syncAll()
    TriggerClientEvent('qbox_signs:sync', -1, getAllSigns())
end

RegisterNetEvent('qbox_signs:requestOpen', function()
    local src = source

    if not hasAdmin(src) then
        TriggerClientEvent('qbox_signs:notify', src, 'You do not have permission to use /sign.', 'error')
        return
    end

    TriggerClientEvent('qbox_signs:open', src)
end)

RegisterNetEvent('qbox_signs:requestSync', function()
    local src = source
    TriggerClientEvent('qbox_signs:sync', src, getAllSigns())
end)

RegisterNetEvent('qbox_signs:create', function(data)
    local src = source

    if not hasAdmin(src) then
        TriggerClientEvent('qbox_signs:notify', src, 'You do not have permission to create signs.', 'error')
        return
    end

    if type(data) ~= 'table' or not validUrl(data.image_url) then
        TriggerClientEvent('qbox_signs:notify', src, 'Invalid image URL. Use a direct HTTPS image URL such as a .png.', 'error')
        return
    end

    local owner = getIdentifier(src)
    if not owner then
        TriggerClientEvent('qbox_signs:notify', src, 'Could not identify your Qbox character.', 'error')
        return
    end

    local x = sanitizeNumber(data.x)
    local y = sanitizeNumber(data.y)
    local z = sanitizeNumber(data.z)
    local width = sanitizeNumber(data.width)
    local height = sanitizeNumber(data.height)

    if not x or not y or not z or not width or not height then
        TriggerClientEvent('qbox_signs:notify', src, 'Invalid sign position or dimensions.', 'error')
        return
    end

    width = math.max(Config.MinSignSize, math.min(Config.MaxSignSize, width))
    height = math.max(Config.MinSignSize, math.min(Config.MaxSignSize, height))

    local heading = sanitizeNumber(data.heading, 0.0)
    local distance = sanitizeNumber(data.view_distance, Config.DefaultViewDistance)

    distance = math.max(
        Config.MinViewDistance,
        math.min(Config.MaxViewDistance, distance)
    )

    local label = tostring(data.label or 'Custom Sign'):sub(1, 100)

    local query = ([[
        INSERT INTO `%s`
        (owner, label, image_url, x, y, z, width, height, heading, view_distance)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]]):format(Config.DatabaseTable)

    local id = MySQL.insert.await(query, {
        owner,
        label,
        data.image_url,
        x,
        y,
        z,
        width,
        height,
        heading,
        distance
    })

    if not id then
        TriggerClientEvent('qbox_signs:notify', src, 'Failed to save the sign to the database.', 'error')
        return
    end

    TriggerClientEvent('qbox_signs:notify', src, 'Sign created successfully.', 'success')
    syncAll()
end)

RegisterNetEvent('qbox_signs:update', function(id, data)
    local src = source

    if not hasAdmin(src) then
        TriggerClientEvent('qbox_signs:notify', src, 'You do not have permission to edit signs.', 'error')
        return
    end

    if type(data) ~= 'table' or not validUrl(data.image_url) then
        TriggerClientEvent('qbox_signs:notify', src, 'Invalid image URL. Use a direct HTTPS image URL such as a .png.', 'error')
        return
    end

    local owner = getIdentifier(src)
    id = tonumber(id)

    if not owner or not id then
        TriggerClientEvent('qbox_signs:notify', src, 'Invalid sign ID.', 'error')
        return
    end

    local distance = sanitizeNumber(data.view_distance, Config.DefaultViewDistance)
    distance = math.max(
        Config.MinViewDistance,
        math.min(Config.MaxViewDistance, distance)
    )

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
        TriggerClientEvent('qbox_signs:notify', src, 'Sign updated successfully.', 'success')
        syncAll()
    else
        TriggerClientEvent('qbox_signs:notify', src, 'That sign could not be updated.', 'error')
    end
end)

RegisterNetEvent('qbox_signs:delete', function(id)
    local src = source

    if not hasAdmin(src) then
        TriggerClientEvent('qbox_signs:notify', src, 'You do not have permission to delete signs.', 'error')
        return
    end

    local owner = getIdentifier(src)
    id = tonumber(id)

    if not owner or not id then
        TriggerClientEvent('qbox_signs:notify', src, 'Invalid sign ID.', 'error')
        return
    end

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
        TriggerClientEvent('qbox_signs:notify', src, 'Sign deleted successfully.', 'success')
        syncAll()
    else
        TriggerClientEvent('qbox_signs:notify', src, 'That sign could not be deleted.', 'error')
    end
end)
