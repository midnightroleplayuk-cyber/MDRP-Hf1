local function getIdentifier(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return nil end

    return player.PlayerData.citizenid
end

local function hasAdmin(src)
    for _, group in ipairs(Config.AdminGroups) do
        if exports.qbx_core:HasGroup(src, group) then
            return true
        end
    end

    return false
end

local function validUrl(url)
    if type(url) ~= 'string' or #url < 8 or #url > Config.MaxUrlLength then
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
    if not value then return fallback end
    return value
end

local function syncAll()
    local rows = MySQL.query.await(
        ('SELECT id, owner, label, image_url, x, y, z, width, height, heading, view_distance FROM `%s` ORDER BY id DESC'):format(Config.DatabaseTable)
    )

    TriggerClientEvent('qbox_signs:sync', -1, rows or {})
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

    local rows = MySQL.query.await(
        ('SELECT id, owner, label, image_url, x, y, z, width, height, heading, view_distance FROM `%s` ORDER BY id DESC'):format(Config.DatabaseTable)
    )

    TriggerClientEvent('qbox_signs:sync', src, rows or {})
end)

RegisterNetEvent('qbox_signs:create', function(data)
    local src = source

    if not hasAdmin(src) then return end
    if type(data) ~= 'table' or not validUrl(data.image_url) then
        TriggerClientEvent('qbox_signs:notify', src, 'Invalid image URL.', 'error')
        return
    end

    local owner = getIdentifier(src)
    if not owner then return end

    local x = sanitizeNumber(data.x)
    local y = sanitizeNumber(data.y)
    local z = sanitizeNumber(data.z)
    local width = sanitizeNumber(data.width)
    local height = sanitizeNumber(data.height)
    local heading = sanitizeNumber(data.heading, 0)
    local distance = sanitizeNumber(data.view_distance, Config.DefaultViewDistance)

    if not x or not y or not z or not width or not height then return end

    width = math.max(Config.MinSignSize, math.min(Config.MaxSignSize, width))
    height = math.max(Config.MinSignSize, math.min(Config.MaxSignSize, height))
    distance = math.max(Config.MinViewDistance, math.min(Config.MaxViewDistance, distance))

    MySQL.insert.await(
        ('INSERT INTO `%s` (owner,label,image_url,x,y,z,width,height,heading,view_distance) VALUES (?,?,?,?,?,?,?,?,?,?)'):format(Config.DatabaseTable),
        {
            owner,
            tostring(data.label or 'Custom Sign'):sub(1, 100),
            data.image_url,
            x, y, z,
            width, height,
            heading,
            distance
        }
    )

    TriggerClientEvent('qbox_signs:notify', src, 'Sign created.', 'success')
    syncAll()
end)

RegisterNetEvent('qbox_signs:update', function(id, data)
    local src = source

    if not hasAdmin(src) then return end
    if type(data) ~= 'table' or not validUrl(data.image_url) then
        TriggerClientEvent('qbox_signs:notify', src, 'Invalid image URL.', 'error')
        return
    end

    local owner = getIdentifier(src)
    if not owner then return end

    local distance = math.max(
        Config.MinViewDistance,
        math.min(
            Config.MaxViewDistance,
            sanitizeNumber(data.view_distance, Config.DefaultViewDistance)
        )
    )

    local where = 'id = ?'
    local params = {
        tostring(data.label or 'Custom Sign'):sub(1, 100),
        data.image_url,
        distance,
        tonumber(id)
    }

    if Config.OwnershipOnly then
        where = where .. ' AND owner = ?'
        params[#params + 1] = owner
    end

    local affected = MySQL.update.await(
        ('UPDATE `%s` SET label=?, image_url=?, view_distance=? WHERE %s'):format(
            Config.DatabaseTable,
            where
        ),
        params
    )

    if affected and affected > 0 then
        TriggerClientEvent('qbox_signs:notify', src, 'Sign updated.', 'success')
        syncAll()
    else
        TriggerClientEvent('qbox_signs:notify', src, 'That sign could not be updated.', 'error')
    end
end)

RegisterNetEvent('qbox_signs:delete', function(id)
    local src = source

    if not hasAdmin(src) then return end

    local owner = getIdentifier(src)
    if not owner then return end

    local where = 'id = ?'
    local params = { tonumber(id) }

    if Config.OwnershipOnly then
        where = where .. ' AND owner = ?'
        params[#params + 1] = owner
    end

    local affected = MySQL.update.await(
        ('DELETE FROM `%s` WHERE %s'):format(Config.DatabaseTable, where),
        params
    )

    if affected and affected > 0 then
        TriggerClientEvent('qbox_signs:notify', src, 'Sign deleted.', 'success')
        syncAll()
    else
        TriggerClientEvent('qbox_signs:notify', src, 'That sign could not be deleted.', 'error')
    end
end)
