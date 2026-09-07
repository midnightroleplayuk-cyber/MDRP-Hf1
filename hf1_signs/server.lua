-- =========================================================
-- HF1 SIGNS - SERVER
-- =========================================================

local function getIdentifier(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return nil end
    return player.PlayerData.citizenid
end

-- Strict allowlist. No Qbox admin/god group can grant access.
-- Config uses identifier.fivem:XXXXXXXX, while FiveM may return
-- fivem:XXXXXXXX at runtime. Both forms are supported.
local function hasPermission(src)
    if not Config.AllowedLicenses then return false end

    for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
        if Config.AllowedLicenses[identifier] == true then
            return true
        end

        if identifier:sub(1, 6) == 'fivem:' then
            if Config.AllowedLicenses['identifier.' .. identifier] == true then
                return true
            end
        elseif identifier:sub(1, 18) == 'identifier.fivem:' then
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
    if Config.RequireHttps and not lower:find('^https://', 1, true) then
        return false
    end

    local extension = lower:match('(%.[%w]+)') or ''
    return Config.AllowedImageExtensions[extension] == true
end

local function number(value, fallback)
    value = tonumber(value)
    if value == nil then return fallback end
    return value
end

local function clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

local function getAllSigns()
    local query = ([=[
        SELECT id, owner, label, image_url, x, y, z, width, height,
               heading, normal_x, normal_y, normal_z, view_distance
        FROM `%s`
        ORDER BY id DESC
    ]=]):format(Config.DatabaseTable)

    return MySQL.query.await(query) or {}
end

local function syncAll()
    TriggerClientEvent('hf1_signs:sync', -1, getAllSigns())
end

RegisterNetEvent('hf1_signs:requestOpen', function()
    local src = source

    if not hasPermission(src) then
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

    if not hasPermission(src) then
        TriggerClientEvent('hf1_signs:notify', src, 'You do not have permission to create signs.', 'error')
        return
    end

    if type(data) ~= 'table' or not validUrl(data.image_url) then
        TriggerClientEvent('hf1_signs:notify', src, 'Invalid image URL. Use a direct HTTPS image URL such as a .png.', 'error')
        return
    end

    local owner = getIdentifier(src)
    if not owner then
        TriggerClientEvent('hf1_signs:notify', src, 'Could not identify your Qbox character.', 'error')
        return
    end

    local x, y, z = number(data.x), number(data.y), number(data.z)
    local width, height = number(data.width), number(data.height)
    local nx = number(data.normal_x, 0.0)
    local ny = number(data.normal_y, 1.0)
    local nz = number(data.normal_z, 0.0)
    local heading = number(data.heading, 0.0)

    if not x or not y or not z or not width or not height then
        TriggerClientEvent('hf1_signs:notify', src, 'Invalid sign position or dimensions.', 'error')
        return
    end

    width = clamp(width, Config.MinSignSize, Config.MaxSignSize)
    height = clamp(height, Config.MinSignSize, Config.MaxSignSize)

    local normalLength = math.sqrt(nx * nx + ny * ny + nz * nz)
    if normalLength < 0.001 then
        nx, ny, nz = 0.0, 1.0, 0.0
        normalLength = 1.0
    end
    nx, ny, nz = nx / normalLength, ny / normalLength, nz / normalLength

    local distance = clamp(
        number(data.view_distance, Config.DefaultViewDistance),
        Config.MinViewDistance,
        Config.MaxViewDistance
    )

    local label = tostring(data.label or 'Custom Sign'):sub(1, 100)

    local query = ([=[
        INSERT INTO `%s`
        (owner, label, image_url, x, y, z, width, height, heading,
         normal_x, normal_y, normal_z, view_distance)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]=]):format(Config.DatabaseTable)

    local id = MySQL.insert.await(query, {
        owner, label, data.image_url,
        x, y, z, width, height, heading,
        nx, ny, nz, distance
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

    if not hasPermission(src) then
        TriggerClientEvent('hf1_signs:notify', src, 'You do not have permission to edit signs.', 'error')
        return
    end

    if type(data) ~= 'table' or not validUrl(data.image_url) then
        TriggerClientEvent('hf1_signs:notify', src, 'Invalid image URL. Use a direct HTTPS image URL such as a .png.', 'error')
        return
    end

    local owner = getIdentifier(src)
    id = tonumber(id)
    if not owner or not id then
        TriggerClientEvent('hf1_signs:notify', src, 'Invalid sign ID.', 'error')
        return
    end

    local distance = clamp(
        number(data.view_distance, Config.DefaultViewDistance),
        Config.MinViewDistance,
        Config.MaxViewDistance
    )

    local label = tostring(data.label or 'Custom Sign'):sub(1, 100)
    local where = 'id = ?'
    local params = { label, data.image_url, distance, id }

    if Config.OwnershipOnly then
        where = where .. ' AND owner = ?'
        params[#params + 1] = owner
    end

    local query = ([=[
        UPDATE `%s`
        SET label = ?, image_url = ?, view_distance = ?
        WHERE %s
    ]=]):format(Config.DatabaseTable, where)

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

    if not hasPermission(src) then
        TriggerClientEvent('hf1_signs:notify', src, 'You do not have permission to delete signs.', 'error')
        return
    end

    local owner = getIdentifier(src)
    id = tonumber(id)
    if not owner or not id then
        TriggerClientEvent('hf1_signs:notify', src, 'Invalid sign ID.', 'error')
        return
    end

    local where = 'id = ?'
    local params = { id }

    if Config.OwnershipOnly then
        where = where .. ' AND owner = ?'
        params[#params + 1] = owner
    end

    local query = ([=[DELETE FROM `%s` WHERE %s]=]):format(Config.DatabaseTable, where)
    local affected = MySQL.update.await(query, params)

    if affected and affected > 0 then
        TriggerClientEvent('hf1_signs:notify', src, 'Sign deleted successfully.', 'success')
        syncAll()
    else
        TriggerClientEvent('hf1_signs:notify', src, 'That sign could not be deleted.', 'error')
    end
end)
