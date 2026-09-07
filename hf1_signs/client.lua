-- =========================================================
-- HF1 SIGNS - CLIENT
-- =========================================================

local signs = {}
local signById = {}
local duiCache = {}
local nearbyIds = {}
local lastSpatialUpdate = 0
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

    if Config.RequireHttps and not lower:find('^https://') then
        return false
    end

    local cleanUrl = lower:match('^[^?#]+') or lower
    local extension = cleanUrl:match('(%.[%w]+)$') or ''
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

    return vector3(
        -math.sin(z) * cosX,
        math.cos(z) * cosX,
        math.sin(x)
    )
end

local function raycastFromCamera(distance)
    local camRot = GetGameplayCamRot(2)
    local camCoord = GetGameplayCamCoord()
    local direction = rotationToDirection(camRot)
    local dest = camCoord + direction * distance

    local ray = StartShapeTestRay(
        camCoord.x, camCoord.y, camCoord.z,
        dest.x, dest.y, dest.z,
        511,
        PlayerPedId(),
        0
    )

    local _, hit, endCoords, surfaceNormal = GetShapeTestResult(ray)

    return hit == 1, endCoords, surfaceNormal
end

local function dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

local function length(v)
    return math.sqrt(dot(v, v))
end

local function normalize(v)
    local l = length(v)
    if l < 0.0001 then
        return vector3(0.0, 0.0, 0.0)
    end

    return vector3(v.x / l, v.y / l, v.z / l)
end

local function cross(a, b)
    return vector3(
        a.y * b.z - a.z * b.y,
        a.z * b.x - a.x * b.z,
        a.x * b.y - a.y * b.x
    )
end

-- Builds a stable 2D coordinate system directly on the hit surface.
-- This is what makes the sign a flat plane rather than a 3D box.
local function getSurfaceBasis(normal)
    normal = normalize(normal)

    if length(normal) < 0.0001 then
        normal = vector3(0.0, 1.0, 0.0)
    end

    -- Prefer world-up for walls so signs remain upright.
    local worldUp = vector3(0.0, 0.0, 1.0)
    local up = worldUp - normal * dot(worldUp, normal)

    -- Floors/ceilings don't have a useful world-up projected onto them.
    if length(up) < 0.05 then
        local cameraRot = GetGameplayCamRot(2)
        local cameraForward = rotationToDirection(cameraRot)
        up = cameraForward - normal * dot(cameraForward, normal)
    end

    up = normalize(up)

    -- Right vector lies on the same surface plane.
    local right = normalize(cross(up, normal))

    if length(right) < 0.05 then
        right = vector3(1.0, 0.0, 0.0)
    end

    -- Re-orthogonalise up for numerical stability.
    up = normalize(cross(normal, right))

    return right, up, normal
end

local function planeCorners(center, width, height, right, up, normal)
    local halfW = width / 2.0
    local halfH = height / 2.0
    local offset = normal * Config.SurfaceOffset

    return {
        center + (-right * halfW) + (up * halfH) + offset,
        center + ( right * halfW) + (up * halfH) + offset,
        center + (-right * halfW) + (-up * halfH) + offset,
        center + ( right * halfW) + (-up * halfH) + offset
    }
end

local function drawLine(a, b)
    DrawLine(
        a.x, a.y, a.z,
        b.x, b.y, b.z,
        Config.SelectionLineColor.r,
        Config.SelectionLineColor.g,
        Config.SelectionLineColor.b,
        Config.SelectionLineColor.a
    )
end

local function drawFlatSelection(center, width, height, right, up, normal)
    local corners = planeCorners(center, width, height, right, up, normal)

    drawLine(corners[1], corners[2])
    drawLine(corners[2], corners[4])
    drawLine(corners[4], corners[3])
    drawLine(corners[3], corners[1])

    -- Crosshair through the centre makes the surface orientation obvious.
    local markerSize = math.min(width, height) * 0.08
    local markerA = center - right * markerSize
    local markerB = center + right * markerSize
    local markerC = center - up * markerSize
    local markerD = center + up * markerSize

    drawLine(markerA, markerB)
    drawLine(markerC, markerD)

    DrawMarker(
        28,
        center.x, center.y, center.z,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        markerSize, markerSize, markerSize,
        Config.SelectionColor.r,
        Config.SelectionColor.g,
        Config.SelectionColor.b,
        90,
        false, false, 2, false, nil, nil, false
    )
end

-- =========================================================
-- 2D SURFACE PLACEMENT
-- =========================================================
--
-- The first click establishes the surface and its top-left point.
-- The second point is projected onto the same surface plane.
-- Width/height are therefore measured ON THE WALL, not through
-- 3D world XYZ axes.
-- =========================================================

local function selectTwoCorners()
    notify('Aim at the top-left corner of the wall and press E.', 'inform')

    local first = nil
    local surfaceNormal = nil
    local right = nil
    local up = nil

    while not first do
        Wait(0)

        local hit, coords, normal = raycastFromCamera(Config.PlacementRayDistance)

        if hit then
            local r, u, n = getSurfaceBasis(normal)
            right, up, surfaceNormal = r, u, n

            DrawMarker(
                28,
                coords.x, coords.y, coords.z,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                0.08, 0.08, 0.08,
                Config.SelectionColor.r,
                Config.SelectionColor.g,
                Config.SelectionColor.b,
                220,
                false, false, 2, false, nil, nil, false
            )

            drawText3D(coords + surfaceNormal * 0.15, 'TOP LEFT - press E')
        end

        if IsControlJustReleased(0, 38) and hit then
            first = coords
        end

        if IsControlJustReleased(0, 177) then
            return nil
        end
    end

    notify('Aim at the bottom-right corner and press E. The preview stays flat on the same surface.', 'inform')

    local second = nil

    while not second do
        Wait(0)

        local hit, coords = raycastFromCamera(Config.PlacementRayDistance)

        if hit then
            -- Project the current hit point onto the original surface.
            local relative = coords - first
            local horizontal = dot(relative, right)
            local vertical = dot(relative, up)

            -- Keep the second point on the original surface plane.
            local projected = first + right * horizontal + up * vertical
            local center = first + right * (horizontal / 2.0) + up * (vertical / 2.0)

            local width = math.abs(horizontal)
            local height = math.abs(vertical)

            if width >= Config.MinSignSize and height >= Config.MinSignSize then
                drawFlatSelection(
                    center,
                    width,
                    height,
                    right,
                    up,
                    surfaceNormal
                )
            end

            drawText3D(projected + surfaceNormal * 0.15, 'BOTTOM RIGHT - press E')

            if IsControlJustReleased(0, 38) then
                if width < Config.MinSignSize or height < Config.MinSignSize then
                    notify('The sign is too small.', 'error')
                elseif width > Config.MaxSignSize or height > Config.MaxSignSize then
                    notify('That sign is larger than the configured maximum.', 'error')
                else
                    second = projected
                end
            end
        end

        if IsControlJustReleased(0, 177) then
            return nil
        end
    end

    local relative = second - first
    local horizontal = dot(relative, right)
    local vertical = dot(relative, up)
    local width = math.abs(horizontal)
    local height = math.abs(vertical)

    local center = first + right * (horizontal / 2.0) + up * (vertical / 2.0)

    -- Face the player by default. The stored normal is authoritative
    -- for the actual surface orientation.
    local heading = math.deg(math.atan2(surfaceNormal.y, surfaceNormal.x)) - 90.0

    return {
        x = center.x,
        y = center.y,
        z = center.z,
        width = width,
        height = height,
        heading = heading,
        normal_x = surfaceNormal.x,
        normal_y = surfaceNormal.y,
        normal_z = surfaceNormal.z
    }
end

-- =========================================================
-- IMAGE DIALOG
-- =========================================================

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

-- =========================================================
-- DUI MANAGEMENT
-- =========================================================

local function destroyDui(id)
    local cached = duiCache[id]
    if not cached then return end

    if cached.dui then
        DestroyDui(cached.dui)
    end

    duiCache[id] = nil
end

local function destroyAllDuis()
    for id in pairs(duiCache) do
        destroyDui(id)
    end
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

    local now = GetGameTimer()
    local cached = duiCache[sign.id]

    if cached and cached.url == sign.image_url then
        cached.lastUsed = now

        -- The browser can take a moment to become available. Do not attempt
        -- to create the runtime texture until the DUI is ready.
        if cached.ready and cached.textureCreated then
            return cached
        end

        if cached.dui and IsDuiAvailable(cached.dui) then
            local handle = GetDuiHandle(cached.dui)

            if handle and not cached.textureCreated then
                local textureHandle = CreateRuntimeTextureFromDuiHandle(
                    cached.txd,
                    cached.txn,
                    handle
                )
                if textureHandle then
                    cached.textureCreated = true
                    cached.ready = true
                end
            end
        end

        return cached.ready and cached.textureCreated and cached or nil
    end

    if cached then
        destroyDui(sign.id)
    end

    if getActiveDuiCount() >= Config.MaxActiveDuis then
        return nil
    end

    local dui = CreateDui(sign.image_url, 1024, 1024)
    if not dui then return nil end

    local txdName = ('hf1_sign_txd_%s'):format(sign.id)
    local txnName = ('hf1_sign_txn_%s'):format(sign.id)
    local txd = CreateRuntimeTxd(txdName)

    cached = {
        dui = dui,
        txd = txdName,
        txn = txnName,
        url = sign.image_url,
        ready = false,
        textureCreated = false,
        lastUsed = now
    }

    duiCache[sign.id] = cached

    -- Give CEF one frame to initialise before the availability check.
    -- This avoids the silent DUI -> runtime-texture race on clients where
    -- CreateRuntimeTextureFromDuiHandle is called too early.
    CreateThread(function()
        local timeout = GetGameTimer() + 5000

        while duiCache[sign.id] == cached and not cached.ready do
            if IsDuiAvailable(dui) then
                local handle = GetDuiHandle(dui)

                if handle then
                    local textureHandle = CreateRuntimeTextureFromDuiHandle(
                        txd,
                        txnName,
                        handle
                    )
                    if textureHandle then
                        cached.textureCreated = true
                        cached.ready = true
                    end
                end

                break
            end

            if GetGameTimer() >= timeout then
                break
            end

            Wait(50)
        end
    end)

    return nil
end

-- =========================================================
-- PROJECTION
-- =========================================================

-- =========================================================
-- TRUE 3D SURFACE RENDERING
-- =========================================================
--
-- Do NOT use DrawSprite for the sign itself.
-- DrawSprite is a screen-space/camera-facing primitive, which makes
-- a sign appear to move/rotate around the camera when the player moves.
--
-- Instead we draw the runtime texture directly onto two world-space
-- triangles using DrawTexturedPoly. The four vertices are calculated
-- from the stored surface normal + surface basis, so the image remains
-- physically flat against the wall/surface.
-- =========================================================

local function drawTexturedTriangle(a, b, c, uvA, uvB, uvC, txd, txn)
    DrawTexturedPoly(
        a.x, a.y, a.z,
        b.x, b.y, b.z,
        c.x, c.y, c.z,
        255, 255, 255, 255,
        txd, txn,
        uvA.x, uvA.y, 1.0,
        uvB.x, uvB.y, 1.0,
        uvC.x, uvC.y, 1.0
    )
end

local function drawSign3D(sign, cached)
    local center = vector3(
        tonumber(sign.x) or 0.0,
        tonumber(sign.y) or 0.0,
        tonumber(sign.z) or 0.0
    )

    local width = tonumber(sign.width) or 1.0
    local height = tonumber(sign.height) or 1.0

    local right, up, normal = getSurfaceBasis(vector3(
        tonumber(sign.normal_x) or 0.0,
        tonumber(sign.normal_y) or 1.0,
        tonumber(sign.normal_z) or 0.0
    ))

    local corners = planeCorners(
        center,
        width,
        height,
        right,
        up,
        normal
    )

    -- Front face.
    drawTexturedTriangle(
        corners[1],
        corners[2],
        corners[4],
        vector2(0.0, 0.0),
        vector2(1.0, 0.0),
        vector2(1.0, 1.0),
        cached.txd,
        cached.txn
    )

    drawTexturedTriangle(
        corners[1],
        corners[4],
        corners[3],
        vector2(0.0, 0.0),
        vector2(1.0, 1.0),
        vector2(0.0, 1.0),
        cached.txd,
        cached.txn
    )

    -- Back face as well, so the sign is visible from either side.
    drawTexturedTriangle(
        corners[1],
        corners[4],
        corners[2],
        vector2(0.0, 0.0),
        vector2(1.0, 1.0),
        vector2(1.0, 0.0),
        cached.txd,
        cached.txn
    )

    drawTexturedTriangle(
        corners[1],
        corners[3],
        corners[4],
        vector2(0.0, 0.0),
        vector2(0.0, 1.0),
        vector2(1.0, 1.0),
        cached.txd,
        cached.txn
    )
end

-- =========================================================
-- SPATIAL FILTER
-- =========================================================

local function rebuildNearby()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local candidates = {}

    for _, sign in pairs(signs) do
        local maxDistance = tonumber(sign.view_distance) or Config.DefaultViewDistance
        local dx = coords.x - sign.x
        local dy = coords.y - sign.y
        local dz = coords.z - sign.z
        local distanceSq = dx * dx + dy * dy + dz * dz

        if distanceSq <= maxDistance * maxDistance then
            candidates[#candidates + 1] = {
                id = sign.id,
                distanceSq = distanceSq
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

-- =========================================================
-- CREATE
-- =========================================================

local function openCreate()
    local placement = selectTwoCorners()
    if not placement then return end

    local data = imageUrlDialog()
    if not data then return end

    if not validClientUrl(data.image_url) then
        notify('Use a direct HTTPS image URL with a configured extension such as .png.', 'error')
        return
    end

    TriggerServerEvent('hf1_signs:create', {
        label = data.label,
        image_url = data.image_url,
        view_distance = data.view_distance,
        x = placement.x,
        y = placement.y,
        z = placement.z,
        width = placement.width,
        height = placement.height,
        heading = placement.heading,
        normal_x = placement.normal_x,
        normal_y = placement.normal_y,
        normal_z = placement.normal_z
    })
end

-- =========================================================
-- MANAGEMENT MENU
-- =========================================================

local function openManage()
    local options = {}

    for _, sign in pairs(signs) do
        options[#options + 1] = {
            title = sign.label,
            description = ('ID %s • %.1fm view distance'):format(
                sign.id,
                tonumber(sign.view_distance) or Config.DefaultViewDistance
            ),
            icon = 'image',
            onSelect = function()
                local input = lib.inputDialog('Edit Sign', {
                    {
                        type = 'input',
                        label = 'Label',
                        default = sign.label,
                        required = true,
                        max = 100
                    },
                    {
                        type = 'input',
                        label = 'Image URL',
                        default = sign.image_url,
                        required = true,
                        max = Config.MaxUrlLength
                    },
                    {
                        type = 'number',
                        label = 'View distance',
                        default = sign.view_distance,
                        min = Config.MinViewDistance,
                        max = Config.MaxViewDistance,
                        precision = 1
                    }
                })

                if input then
                    TriggerServerEvent('hf1_signs:update', sign.id, {
                        label = input[1],
                        image_url = input[2],
                        view_distance = input[3]
                    })
                end
            end
        }
    end

    if #options == 0 then
        options[1] = {
            title = 'No signs found',
            disabled = true
        }
    end

    lib.registerContext({
        id = 'hf1_signs_manage',
        title = 'Manage Signs',
        menu = 'hf1_signs_main',
        options = options
    })

    lib.showContext('hf1_signs_manage')
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
                    TriggerServerEvent('hf1_signs:delete', sign.id)
                end
            end
        }
    end

    if #options == 0 then
        options[1] = {
            title = 'No signs found',
            disabled = true
        }
    end

    lib.registerContext({
        id = 'hf1_signs_delete',
        title = 'Delete Sign',
        menu = 'hf1_signs_main',
        options = options
    })

    lib.showContext('hf1_signs_delete')
end

local function openMain()
    lib.registerContext({
        id = 'hf1_signs_main',
        title = 'Sign Management',
        options = {
            {
                title = 'New Sign',
                description = 'Place a flat image sign on a wall or other surface',
                icon = 'plus',
                onSelect = openCreate
            },
            {
                title = 'Manage Signs',
                description = 'Edit your custom signs',
                icon = 'list',
                onSelect = openManage
            },
            {
                title = 'Delete Sign',
                description = 'Permanently remove a sign',
                icon = 'trash',
                onSelect = openDelete
            }
        }
    })

    lib.showContext('hf1_signs_main')
end

-- =========================================================
-- COMMAND
-- =========================================================

RegisterCommand(Config.Command, function()
    if requestBusy then return end

    requestBusy = true
    TriggerServerEvent('hf1_signs:requestOpen')

    SetTimeout(Config.RequestCooldownMs, function()
        requestBusy = false
    end)
end, false)

-- =========================================================
-- EVENTS
-- =========================================================

RegisterNetEvent('hf1_signs:open', openMain)

RegisterNetEvent('hf1_signs:sync', function(serverSigns)
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

RegisterNetEvent('hf1_signs:notify', function(msg, type)
    notify(msg, type)
end)

-- =========================================================
-- INITIAL SYNC
-- =========================================================

CreateThread(function()
    Wait(1000)
    TriggerServerEvent('hf1_signs:requestSync')
end)

-- =========================================================
-- SPATIAL UPDATE LOOP
-- =========================================================

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

-- =========================================================
-- RENDER LOOP
-- =========================================================

CreateThread(function()
    while true do
        local sleep = 500
        local now = GetGameTimer()

        for _, id in ipairs(nearbyIds) do
            local sign = signById[id]

            if sign then
                local cached = getOrCreateDui(sign)

                if cached then
                    sleep = 0
                    cached.lastUsed = now

                    -- Only draw once the DUI runtime texture is actually ready.
                    -- This prevents a blank/solid-colour quad from being shown.
                    if cached.ready and cached.textureCreated then
                        drawSign3D(sign, cached)
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

-- =========================================================
-- CLEANUP
-- =========================================================

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        destroyAllDuis()
    end
end)
