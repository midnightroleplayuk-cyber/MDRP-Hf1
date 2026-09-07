local signs = {}
local signById = {}
local duiCache = {}
local nearbyIds = {}
local lastProjection = {}
local lastSpatialUpdate = 0
local lastFrameCoords = nil
local requestBusy = false

local function notify(description, type)
    lib.notify({
        title = 'Signs',
        description = description,
        type = type or 'inform'
    })
end

local function validClientUrl(url)
    if type(url) ~= 'string' then return false end
    local lower = url:lower()

    if Config.RequireHttps and not lower:find('^https://', 1, true) then
        return false
    end

    local extension = lower:match('(%.[%w]+)') or ''
    return Config.AllowedImageExtensions[extension] == true
end

local function drawText3D(coords, text)
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    SetTextScale(0.28, 0.28)
    SetTextFont(4)
    SetTextCentre(true)
    SetTextColour(255, 255, 255, 230)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

local function rotationToDirection(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local cosX = math.abs(math.cos(x))
    return vector3(-math.sin(z) * cosX, math.cos(z) * cosX, math.sin(x))
end

local function raycastFromCamera(distance)
    local camRot = GetGameplayCamRot(2)
    local camCoord = GetGameplayCamCoord()
    local direction = rotationToDirection(camRot)
    local dest = camCoord + direction * distance

    local ray = StartShapeTestRay(
        camCoord.x, camCoord.y, camCoord.z,
        dest.x, dest.y, dest.z,
        511, PlayerPedId(), 0
    )
    local _, hit, endCoords = GetShapeTestResult(ray)

    return hit == 1, endCoords
end

local function drawSelection(a, b)
    local minX, maxX = math.min(a.x, b.x), math.max(a.x, b.x)
    local minY, maxY = math.min(a.y, b.y), math.max(a.y, b.y)
    local minZ, maxZ = math.min(a.z, b.z), math.max(a.z, b.z)

    local points = {
        vector3(minX, minY, minZ), vector3(maxX, minY, minZ),
        vector3(maxX, maxY, minZ), vector3(minX, maxY, minZ),
        vector3(minX, minY, maxZ), vector3(maxX, minY, maxZ),
        vector3(maxX, maxY, maxZ), vector3(minX, maxY, maxZ)
    }

    local edges = {
        {1,2},{2,3},{3,4},{4,1},
        {5,6},{6,7},{7,8},{8,5},
        {1,5},{2,6},{3,7},{4,8}
    }

    for _, edge in ipairs(edges) do
        local p1, p2 = points[edge[1]], points[edge[2]]
        DrawLine(
            p1.x,p1.y,p1.z,
            p2.x,p2.y,p2.z,
            Config.SelectionLineColor.r,
            Config.SelectionLineColor.g,
            Config.SelectionLineColor.b,
            Config.SelectionLineColor.a
        )
    end

    local center = vector3(
        (minX + maxX) / 2,
        (minY + maxY) / 2,
        (minZ + maxZ) / 2
    )

    DrawMarker(28, center.x, center.y, center.z, 0,0,0, 0,0,0,
        maxX-minX, maxY-minY, maxZ-minZ,
        Config.SelectionColor.r, Config.SelectionColor.g, Config.SelectionColor.b, 70,
        false, false, 2, false, nil, nil, false)
end

local function selectTwoCorners()
    notify('Aim at the top-left corner and press E.', 'inform')
    local first

    while not first do
        Wait(0)
        local hit, coords = raycastFromCamera(50.0)

        if hit then
            DrawMarker(28, coords.x, coords.y, coords.z, 0,0,0,0,0,0,
                0.08,0.08,0.08, 190,90,255,220, false,false,2,false,nil,nil,false)
            drawText3D(coords + vector3(0,0,0.15), 'TOP LEFT - press E')
        end

        if IsControlJustReleased(0, 38) and hit then
            first = coords
        end

        if IsControlJustReleased(0, 177) then
            return nil
        end
    end

    notify('Aim at the bottom-right corner and press E.', 'inform')
    local second

    while not second do
        Wait(0)
        local hit, coords = raycastFromCamera(50.0)

        if hit then
            drawSelection(first, coords)
            drawText3D(coords + vector3(0,0,0.15), 'BOTTOM RIGHT - press E')
        end

        if IsControlJustReleased(0, 38) and hit then
            second = coords
        end

        if IsControlJustReleased(0, 177) then
            return nil
        end
    end

    local width = math.abs(second.x - first.x)
    local height = math.abs(second.z - first.z)

    if width < Config.MinSignSize or height < Config.MinSignSize then
        notify('The sign is too small.', 'error')
        return nil
    end

    if width > Config.MaxSignSize or height > Config.MaxSignSize then
        notify('That sign is larger than the configured maximum.', 'error')
        return nil
    end

    return {
        x = (first.x + second.x) / 2,
        y = (first.y + second.y) / 2,
        z = (first.z + second.z) / 2,
        width = width,
        height = height,
        heading = GetEntityHeading(PlayerPedId())
    }
end

local function imageUrlDialog()
    local input = lib.inputDialog('New Sign', {
        {
            type = 'input',
            label = 'Sign label',
            description = 'A name for the management menu',
            required = true,
            default = 'Custom Sign',
            max = 100
        },
        {
            type = 'input',
            label = 'PNG / image URL',
            description = 'Direct HTTPS image URL (.png supported)',
            required = true,
            max = Config.MaxUrlLength
        },
        {
            type = 'number',
            label = 'View distance',
            description = 'Maximum distance players can see this sign',
            default = Config.DefaultViewDistance,
            min = Config.MinViewDistance,
            max = Config.MaxViewDistance,
            precision = 1
        }
    })

    if not input then return nil end

    return {
        label = input[1],
        image_url = input[2],
        view_distance = input[3]
    }
end

local function destroyDui(id)
    local cached = duiCache[id]
    if not cached then return end

    if cached.dui then
        DestroyDui(cached.dui)
    end

    duiCache[id] = nil
    lastProjection[id] = nil
end

local function getActiveDuiCount()
    local count = 0
    for _ in pairs(duiCache) do
        count += 1
    end
    return count
end

local function getOrCreateDui(sign)
    if not validClientUrl(sign.image_url) then
        return nil
    end

    local cached = duiCache[sign.id]
    if cached and cached.url == sign.image_url then
        cached.lastUsed = GetGameTimer()
        return cached
    end

    if cached then
        destroyDui(sign.id)
    end

    if getActiveDuiCount() >= Config.MaxActiveDuis then
        return nil
    end

    local dui = CreateDui(sign.image_url, 1024, 1024)
    if not dui then return nil end

    local handle = GetDuiHandle(dui)
    local txdName = ('qbox_sign_txd_%s'):format(sign.id)
    local txnName = ('qbox_sign_txn_%s'):format(sign.id)

    local txd = CreateRuntimeTxd(txdName)
    CreateRuntimeTextureFromDuiHandle(txd, txnName, handle)

    cached = {
        dui = dui,
        txd = txdName,
        txn = txnName,
        url = sign.image_url,
        lastUsed = GetGameTimer()
    }

    duiCache[sign.id] = cached
    return cached
end

local function destroyAllDuis()
    for id in pairs(duiCache) do
        destroyDui(id)
    end
end

local function projectWorldPoint(coords)
    local ok, sx, sy = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    if not ok then return nil end
    return sx, sy
end

local function calculateProjection(sign)
    local center = vector3(sign.x, sign.y, sign.z)
    local halfW = sign.width / 2.0
    local halfH = sign.height / 2.0

    local tlx, tly = projectWorldPoint(center + vector3(-halfW, 0.0, halfH))
    local trx, try = projectWorldPoint(center + vector3(halfW, 0.0, halfH))
    local blx, bly = projectWorldPoint(center + vector3(-halfW, 0.0, -halfH))
    local brx, bry = projectWorldPoint(center + vector3(halfW, 0.0, -halfH))

    if not (tlx and trx and blx and brx) then
        return nil
    end

    local minX = math.min(tlx, trx, blx, brx)
    local maxX = math.max(tlx, trx, blx, brx)
    local minY = math.min(tly, try, bly, bry)
    local maxY = math.max(tly, try, bly, bry)

    local width = maxX - minX
    local height = maxY - minY

    if width < Config.MinScreenSize or height < Config.MinScreenSize then
        return nil
    end

    return {
        x = (minX + maxX) / 2.0,
        y = (minY + maxY) / 2.0,
        width = width,
        height = height
    }
end

local function rebuildNearby()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local candidates = {}

    for _, sign in pairs(signs) do
        local maxDistance = tonumber(sign.view_distance) or Config.DefaultViewDistance
        local dx = coords.x - sign.x
        local dy = coords.y - sign.y
        local dz = coords.z - sign.z

        if (dx * dx + dy * dy + dz * dz) <= (maxDistance * maxDistance) then
            candidates[#candidates + 1] = {
                id = sign.id,
                distanceSq = dx * dx + dy * dy + dz * dz
            }
        end
    end

    table.sort(candidates, function(a, b)
        return a.distanceSq < b.distanceSq
    end)

    nearbyIds = {}
    for i = 1, math.min(#candidates, Config.MaxActiveDuis) do
        nearbyIds[i] = candidates[i].id
    end
end

local function openCreate()
    local placement = selectTwoCorners()
    if not placement then return end

    local data = imageUrlDialog()
    if not data then return end

    if not validClientUrl(data.image_url) then
        notify('Use a direct HTTPS image URL with a configured extension such as .png.', 'error')
        return
    end

    TriggerServerEvent('qbox_signs:create', {
        label = data.label,
        image_url = data.image_url,
        view_distance = data.view_distance,
        x = placement.x, y = placement.y, z = placement.z,
        width = placement.width, height = placement.height,
        heading = placement.heading
    })
end

local function openManage()
    local options = {}

    for _, sign in pairs(signs) do
        options[#options + 1] = {
            title = sign.label,
            description = ('ID %s • %.1fm view distance'):format(sign.id, sign.view_distance),
            icon = 'image',
            onSelect = function()
                local input = lib.inputDialog('Edit Sign', {
                    { type = 'input', label = 'Label', default = sign.label, required = true, max = 100 },
                    { type = 'input', label = 'Image URL', default = sign.image_url, required = true, max = Config.MaxUrlLength },
                    { type = 'number', label = 'View distance', default = sign.view_distance, min = Config.MinViewDistance, max = Config.MaxViewDistance, precision = 1 }
                })

                if input then
                    TriggerServerEvent('qbox_signs:update', sign.id, {
                        label = input[1],
                        image_url = input[2],
                        view_distance = input[3]
                    })
                end
            end
        }
    end

    if #options == 0 then
        options[1] = { title = 'No signs found', disabled = true }
    end

    lib.registerContext({
        id = 'qbox_signs_manage',
        title = 'Manage Signs',
        menu = 'qbox_signs_main',
        options = options
    })
    lib.showContext('qbox_signs_manage')
end

local function openDelete()
    local options = {}

    for _, sign in pairs(signs) do
        options[#options + 1] = {
            title = sign.label,
            description = ('Delete sign ID %s'):format(sign.id),
            icon = 'trash',
            iconColor = 'red',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Delete sign?',
                    content = ('Delete "%s" permanently?'):format(sign.label),
                    centered = true,
                    cancel = true
                })

                if confirm == 'confirm' then
                    TriggerServerEvent('qbox_signs:delete', sign.id)
                end
            end
        }
    end

    if #options == 0 then
        options[1] = { title = 'No signs found', disabled = true }
    end

    lib.registerContext({
        id = 'qbox_signs_delete',
        title = 'Delete Sign',
        menu = 'qbox_signs_main',
        options = options
    })
    lib.showContext('qbox_signs_delete')
end

local function openMain()
    lib.registerContext({
        id = 'qbox_signs_main',
        title = 'Sign Management',
        options = {
            { title = 'New Sign', description = 'Place a new image sign in the world', icon = 'plus', onSelect = openCreate },
            { title = 'Manage Signs', description = 'Edit your custom signs', icon = 'list', onSelect = openManage },
            { title = 'Delete Sign', description = 'Permanently remove a sign', icon = 'trash', onSelect = openDelete }
        }
    })
    lib.showContext('qbox_signs_main')
end

RegisterCommand(Config.Command, function()
    if requestBusy then return end

    requestBusy = true
    TriggerServerEvent('qbox_signs:requestOpen')

    SetTimeout(Config.RequestCooldownMs, function()
        requestBusy = false
    end)
end, false)

RegisterNetEvent('qbox_signs:open', openMain)

RegisterNetEvent('qbox_signs:sync', function(serverSigns)
    signs = serverSigns or {}
    signById = {}

    for _, sign in pairs(signs) do
        signById[sign.id] = sign
    end

    -- Drop cached textures for deleted signs or changed URLs.
    for id, cached in pairs(duiCache) do
        local sign = signById[id]
        if not sign or sign.image_url ~= cached.url then
            destroyDui(id)
        end
    end

    nearbyIds = {}
    lastSpatialUpdate = 0
end)

RegisterNetEvent('qbox_signs:notify', function(msg, type)
    notify(msg, type)
end)

CreateThread(function()
    Wait(1000)
    TriggerServerEvent('qbox_signs:requestSync')
end)

CreateThread(function()
    while true do
        Wait(Config.SpatialUpdateMs)

        if #signs > 0 then
            rebuildNearby()
        else
            nearbyIds = {}
        end
    end
end)

CreateThread(function()
    while true do
        local sleep = 500
        local now = GetGameTimer()

        for _, id in ipairs(nearbyIds) do
            local sign = signById[id]

            if sign then
                local dui = getOrCreateDui(sign)

                if dui then
                    sleep = 0
                    dui.lastUsed = now

                    local projection = lastProjection[id]

                    if not projection or (now - projection.time) >= Config.ProjectionUpdateMs then
                        local calculated = calculateProjection(sign)
                        if calculated then
                            calculated.time = now
                            lastProjection[id] = calculated
                            projection = calculated
                        else
                            projection = nil
                        end
                    end

                    if projection then
                        DrawSprite(
                            dui.txd,
                            dui.txn,
                            projection.x,
                            projection.y,
                            projection.width,
                            projection.height,
                            0.0,
                            255,255,255,255
                        )
                    end
                end
            end
        end

        -- Gracefully unload inactive browser textures.
        for id, cached in pairs(duiCache) do
            if (now - cached.lastUsed) >= Config.DuiUnloadGraceMs then
                destroyDui(id)
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        destroyAllDuis()
    end
end)
