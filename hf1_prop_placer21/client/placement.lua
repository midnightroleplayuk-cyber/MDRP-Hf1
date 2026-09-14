HF1PropPlacement = {}

local function rotationToDirection(rotation)
    local z = math.rad(rotation.z)
    local x = math.rad(rotation.x)
    local cosX = math.abs(math.cos(x))
    return vector3(-math.sin(z) * cosX, math.cos(z) * cosX, math.sin(x))
end

local function cameraRaycast(distance)
    local camCoord = GetGameplayCamCoord()
    local direction = rotationToDirection(GetGameplayCamRot(2))
    local destination = camCoord + direction * distance
    local ray = StartShapeTestRay(camCoord.x, camCoord.y, camCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 7)
    local _, hit, endCoords = GetShapeTestResult(ray)
    return hit == 1, endCoords
end

local function loadModel(model)
    local hash = joaat(model)
    RequestModel(hash)
    local deadline = GetGameTimer() + (Config.Streaming.modelLoadTimeout or 7000)
    while not HasModelLoaded(hash) and GetGameTimer() < deadline do Wait(10) end
    return HasModelLoaded(hash) and hash or nil
end

local function normalizeAngle(v)
    v = v % 360.0
    if v > 180.0 then v = v - 360.0 end
    return v
end

function HF1PropPlacement.Place(model, existing)
    local hash = loadModel(model)
    if not hash then
        lib.notify({ title = 'Prop Admin', description = 'Could not load that prop model.', type = 'error' })
        return nil
    end

    local playerPed = PlayerPedId()
    local initial = existing and existing.coords or (GetEntityCoords(playerPed) + GetEntityForwardVector(playerPed) * 2.0)
    local rot = existing and existing.rotation or { x = 0.0, y = 0.0, z = GetEntityHeading(playerPed) }
    local entity = CreateObjectNoOffset(hash, initial.x, initial.y, initial.z, false, false, false)
    if entity == 0 then SetModelAsNoLongerNeeded(hash); return nil end

    SetEntityAlpha(entity, 180, false)
    SetEntityCollision(entity, false, false)
    FreezeEntityPosition(entity, true)
    SetEntityRotation(entity, rot.x or 0.0, rot.y or 0.0, rot.z or 0.0, 2, true)

    local cancelled, finished = false, false

    lib.showTextUI('[LMB] Place/re-place  [WASD] Move  [Q/E] Height  [←/→] Yaw  [↑/↓] Pitch  [Z/X] Roll  [G] Ground  [Shift/Ctrl] Speed  [Enter] Save  [Backspace] Cancel', {
        position = 'top-center',
        icon = 'cube',
    })

    while not finished and not cancelled do
        Wait(0)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 44, true)
        DisableControlAction(0, 38, true)
        DisableControlAction(0, 32, true)
        DisableControlAction(0, 33, true)
        DisableControlAction(0, 34, true)
        DisableControlAction(0, 35, true)
        DisableControlAction(0, 172, true)
        DisableControlAction(0, 173, true)
        DisableControlAction(0, 174, true)
        DisableControlAction(0, 175, true)

        -- Keep the camera target active for the whole placement session.
        -- LMB snaps/re-snaps the prop to the current raycast point as many times
        -- as the admin wants; manual adjustments never disable later LMB placement.
        local hit, hitCoords = cameraRaycast(Config.Placement.maxRayDistance or 100.0)
        if hit then
            DrawMarker(28, hitCoords.x, hitCoords.y, hitCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                Config.Placement.markerScale or 0.06, Config.Placement.markerScale or 0.06, Config.Placement.markerScale or 0.06,
                255, 255, 255, 180, false, false, 2, false, nil, nil, false)
            if IsDisabledControlJustPressed(0, 24) then
                SetEntityCoordsNoOffset(entity, hitCoords.x, hitCoords.y, hitCoords.z, false, false, false)
            end
        end

        local multiplier = 1.0
        if IsControlPressed(0, 21) then multiplier = Config.Placement.fastMultiplier or 4.0 end
        if IsControlPressed(0, 36) then multiplier = Config.Placement.precisionMultiplier or 0.25 end
        local move = (Config.Placement.moveSpeed or 0.035) * multiplier
        local vert = (Config.Placement.verticalSpeed or 0.025) * multiplier
        local turn = (Config.Placement.rotateSpeed or 1.0) * multiplier

        local coords = GetEntityCoords(entity)
        local camRot = GetGameplayCamRot(2)
        local forward = rotationToDirection(vector3(0.0, 0.0, camRot.z))
        local right = vector3(forward.y, -forward.x, 0.0)
        local delta = vector3(0.0, 0.0, 0.0)

        if IsDisabledControlPressed(0, 32) then delta = delta + forward * move end
        if IsDisabledControlPressed(0, 33) then delta = delta - forward * move end
        if IsDisabledControlPressed(0, 35) then delta = delta + right * move end
        if IsDisabledControlPressed(0, 34) then delta = delta - right * move end
        if IsDisabledControlPressed(0, 38) then delta = delta + vector3(0.0, 0.0, vert) end
        if IsDisabledControlPressed(0, 44) then delta = delta - vector3(0.0, 0.0, vert) end
        if delta.x ~= 0.0 or delta.y ~= 0.0 or delta.z ~= 0.0 then
            SetEntityCoordsNoOffset(entity, coords.x + delta.x, coords.y + delta.y, coords.z + delta.z, false, false, false)
        end

        local currentRot = GetEntityRotation(entity, 2)
        local rx, ry, rz = currentRot.x, currentRot.y, currentRot.z
        if IsDisabledControlPressed(0, 174) then rz = rz + turn end
        if IsDisabledControlPressed(0, 175) then rz = rz - turn end
        if IsDisabledControlPressed(0, 172) then rx = rx + turn end
        if IsDisabledControlPressed(0, 173) then rx = rx - turn end
        if IsControlPressed(0, 20) then ry = ry + turn end -- Z
        if IsControlPressed(0, 73) then ry = ry - turn end -- X
        SetEntityRotation(entity, normalizeAngle(rx), normalizeAngle(ry), normalizeAngle(rz), 2, true)

        if IsControlJustPressed(0, 47) then -- G
            PlaceObjectOnGroundProperly(entity)
        end

        if IsControlJustPressed(0, 191) then finished = true end
        if IsControlJustPressed(0, 177) then cancelled = true end
    end

    lib.hideTextUI()
    local coords = GetEntityCoords(entity)
    local finalRot = GetEntityRotation(entity, 2)
    local rx, ry, rz = finalRot.x, finalRot.y, finalRot.z
    DeleteEntity(entity)
    SetModelAsNoLongerNeeded(hash)

    if cancelled then return nil end
    return {
        coords = { x = coords.x + 0.0, y = coords.y + 0.0, z = coords.z + 0.0 },
        rotation = { x = rx + 0.0, y = ry + 0.0, z = rz + 0.0 },
    }
end
