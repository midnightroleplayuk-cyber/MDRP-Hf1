local function getIdentifier(src)
    local player = exports.qbx_core:GetPlayer(src)

    if not player then
        return nil
    end

    return player.PlayerData.citizenid
end

local function hasAdmin(src)
    -- Qbox group permissions
    if Config.AdminGroups then
        for _, group in ipairs(Config.AdminGroups) do
            if exports.qbx_core:HasGroup(src, group) then
                return true
            end
        end
    end

    -- FiveM identifier allowlist
    -- Supports:
    -- identifier.fivem:
    -- license:
    -- license2:
    if Config.AllowedLicenses then
        for _, identifier in ipairs(GetPlayerIdentifiers(src)) do
            if Config.AllowedLicenses[identifier] == true then
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

    -- Require HTTPS if enabled.
    if Config.RequireHttps then
        if not lower:find('^https://', 1, true) then
            return false
        end
    end

    -- Check image extension.
    local extension = lower:match('(%.[%w]+)') or ''

    if not Config.AllowedImageExtensions[extension] then
        return false
    end

    return true
end

local function sanitizeNumber(value, fallback)
    value = tonumber(value)

    if not value then
        return fallback
    end

    return value
end

local function getAllSigns()
    return MySQL.query.await(
        ('SELECT id, owner, label, image_url, x, y, z, width, height, heading, view_distance FROM `%s` ORDER BY id DESC'):format(
            Config.DatabaseTable
        )
    ) or {}
end

local function syncAll()
    local rows = getAllSigns()

    TriggerClientEvent(
        'qbox_signs:sync',
        -1,
        rows
    )
end

-- =========================================================
-- OPEN SIGN MENU
-- =========================================================

RegisterNetEvent('qbox_signs:requestOpen', function()
    local src = source

    if not hasAdmin(src) then
        TriggerClientEvent(
            'qbox_signs:notify',
            src,
            'You do not have permission to use /sign.',
            'error'
        )

        return
    end

    TriggerClientEvent(
        'qbox_signs:open',
        src
    )
end)

-- =========================================================
-- INITIAL SIGN SYNC
-- =========================================================

RegisterNetEvent('qbox_signs:requestSync', function()
    local src = source

    local rows = getAllSigns()

    TriggerClientEvent(
        'qbox_signs:sync',
        src,
        rows
    )
end)

-- =========================================================
-- CREATE SIGN
-- =========================================================

RegisterNetEvent('qbox_signs:create', function(data)
    local src = source

    -- Always perform permission validation server-side.
    if not hasAdmin(src) then
        TriggerClientEvent(
            'qbox_signs:notify',
            src,
            'You do not have permission to create signs.',
            'error'
        )

        return
    end

    if type(data) ~= 'table' then
        TriggerClientEvent(
            'qbox_signs:notify',
            src,
            'Invalid sign data.',
            'error'
        )

        return
    end

    -- Validate image URL.
    if not validUrl(data.image_url) then
        TriggerClientEvent(
            'qbox_signs:notify',
            src,
            'Invalid image URL. Use a direct HTTPS image URL such as a .png.',
            'error'
        )

        return
    end

    local owner = getIdentifier(src)

    if not owner then
        TriggerClientEvent(
            'qbox_signs:notify',
            src,
            'Could not identify your Qbox character.',
            'error'
        )

        return
    end

    -- =====================================================
    -- POSITION
    -- =====================================================

    local x = sanitizeNumber(data.x)
    local y = sanitizeNumber(data.y)
    local z = sanitizeNumber(data.z)

    -- =====================================================
    -- DIMENSIONS
    -- =====================================================

    local width = sanitizeNumber(data.width)
    local height = sanitizeNumber(data.height)

    -- =====================================================
    -- HEADING
    -- =====================================================

    local heading = sanitizeNumber(
        data.heading,
        0.0
    )

    -- =====================================================
    -- VIEW DISTANCE
    -- =====================================================

    local distance = sanitizeNumber(
        data.view_distance,
        Config.DefaultViewDistance
    )

    if not x or not y or not z then
        TriggerClientEvent(
            'qbox_signs:notify',
            src,
            'Invalid sign position.',
            'error'
        )

        return
    end

    if not width or not height then
        TriggerClientEvent(
            'qbox_signs:notify',
            src,
            'Invalid sign dimensions.',
            'error'
        )

        return
    end

    -- Clamp dimensions.
    width = math.max(
        Config.MinSignSize,
        math.min(
            Config.MaxSignSize,
            width
        )
    )

    height = math.max(
        Config.MinSignSize,
        math.min(
            Config.MaxSignSize,
            height
        )
    )

    -- Clamp viewing distance.
    distance = math.max(
        Config.MinViewDistance,
        math.min(
            Config.MaxViewDistance,
            distance
        )
    )

    local label = tostring(
        data.label or 'Custom Sign'
    ):sub(1, 100)

    -- =====================================================
    -- DATABASE INSERT
    -- =====================================================

    local id = MySQL.insert.await(
        ('INSERT INTO `%s` (owner, label, image_url, x, y, z, width, height, heading, view_distance) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'):format(
            Config.DatabaseTable
        ),
        {
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
        }
    )

    if not id then
        TriggerClientEvent(
            'qbox_signs:notify',
            src,
            'Failed to save the sign to the database.',
            'error'
        )

        return
    end

    TriggerClientEvent(
        'qbox_signs:notify',
        src,
        'Sign created successfully.',
        'success'
    )

    -- Update every player.
    syncAll()
end)

-- =========================================================
-- UPDATE SIGN
-- =========================================================

RegisterNetEvent('qbox_signs:update', function(id, data)
    local src = source

    if not hasAdmin(src) then
        TriggerClientEvent(
            'qbox_signs:notify',
            src,
            'You do not have permission to edit signs.',
            'error'
        )

        return
    end

    if type(data) ~= 'table' then
        return
    end

    -- Validate URL.
    if not validUrl(data.image_url) then
        TriggerClientEvent(
            'qbox_signs:notify',
            src,
            'Invalid image URL. Use a direct HTTPS image URL such as a .png.',
            'error'
        )

        return
    end

    local owner = getIdentifier(src)

    if not owner then
        return
    end

    id = tonumber(id)

    if not id then
        TriggerClientEvent(
            'qbox_signs:notify',
            src,
            'Invalid sign ID.',
            'error'
        )

        return
    end

    local distance = sanitizeNumber(
        data.view_distance,
        Config.DefaultViewDistance
    )

    distance = math.max(
        Config.MinViewDistance,
        math.min(
            Config.MaxViewDistance,
            distance
        )
    )

    local label = tostring(
        data.label or 'Custom Sign'
    ):sub(1, 100)

    local where = 'id = ?'

    local params = {
        label,
        data.image_url,
        distance,
        id
    }

    -- If enabled, only the original creator can edit it.
    if Config.OwnershipOnly then
        where = where .. ' AND owner = ?'
        params[#params + 1] = owner
    end

    local affected = MySQL.update.await(
        ('UPDATE `%s` SET label = ?, image_url = ?, view_distance = ? WHERE %s'):format(
            Config.DatabaseTable,
            where
        ),
        params
    )

    if affected and affected > 0 then
        TriggerClientEvent(
            'qbox_signs:notify',
            src,
            'Sign updated successfully.',
            'success'
        )

        syncAll()
    else
        TriggerClientEvent(
            'qbox_signs:notify',
            src,
            'That sign could not be updated.',
            'error'
        )
    end
end)

-- =========================================================
-- DELETE SIGN
-- =========================================================

RegisterNetEvent('qbox_signs:delete', function(id)
    local src = source

    if not hasAdmin(src) then
        TriggerClientEvent(
            'qbox_signs:notify',
            src,
            'You do not have permission to delete signs.',
            'error'
        )

        return
    end

    local owner = getIdentifier(src)

    if not owner then
        return
    end

    id = tonumber(id)

    if not id then
        TriggerClientEvent(
            'qbox_signs:notify',
            src,
            'Invalid sign ID.',
            'error'
        )

        return
    end

    local where = 'id = ?'

    local params = {
        id
    }

    -- If enabled, only the original creator can delete it.
    if Config.OwnershipOnly then
        where = where .. ' AND owner = ?'
        params[#params + 1] = owner
    end

    local affected = MySQL.update.await(
        ('DELETE FROM `%s` WHERE %s'):format(
            Config.DatabaseTable,
            where
        ),
        params
    )

    if affected and affected > 0 then
        TriggerClientEvent(
            'qbox_signs:notify',
            src,
            'Sign deleted successfully.',
            'success'
        )

        syncAll()
    else
        TriggerClientEvent(
            'qbox_signs:notify',
            src,
            'That sign could not be deleted.',
            'error'
        )
    end
end)

