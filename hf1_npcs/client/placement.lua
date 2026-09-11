NPCManager = NPCManager or {}

local function rotationToDirection(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vec3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

local function rightVectorFromHeading(heading)
    local r = math.rad(heading + 90.0)
    return vec3(-math.sin(r), math.cos(r), 0.0)
end

-- Cast a ray straight through the centre of the gameplay camera. The mouse still
-- controls the camera during placement, so this behaves like a simple point-and-click
-- world picker without needing NUI cursor focus.
local function getMouseWorldHit(ignoreEntity)
    local camCoords = GetGameplayCamCoord()
    local direction = rotationToDirection(GetGameplayCamRot(2))
    local destination = camCoords + (direction * 1000.0)

    local ray = StartShapeTestRay(
        camCoords.x, camCoords.y, camCoords.z,
        destination.x, destination.y, destination.z,
        -1,
        ignoreEntity or 0,
        7
    )

    local _, hit, endCoords = GetShapeTestResult(ray)
    if hit == 1 then
        return endCoords
    end

    return nil
end

function NPCManager.PlacePed(model, existingCoords)
    local hash, err = NPCManager.LoadModel(model)
    if not hash then
        NPCManager.Notify(err, 'error')
        return nil
    end

    local playerPed = cache.ped
    local start
    local heading

    if existingCoords then
        start = vec3(existingCoords.x, existingCoords.y, existingCoords.z)
        heading = existingCoords.w or GetEntityHeading(playerPed)
    else
        local pcoords = GetEntityCoords(playerPed)
        local forward = rotationToDirection(GetGameplayCamRot(2))
        start = pcoords + (forward * Config.Placement.distanceInFront)
        heading = GetEntityHeading(playerPed)
    end

    local preview = CreatePed(4, hash, start.x, start.y, start.z, heading, false, false)
    if not preview or preview == 0 then
        SetModelAsNoLongerNeeded(hash)
        NPCManager.Notify('Could not create placement preview.', 'error')
        return nil
    end

    SetEntityAlpha(preview, 190, false)
    SetEntityCollision(preview, false, false)
    SetEntityInvincible(preview, true)
    FreezeEntityPosition(preview, true)
    SetBlockingOfNonTemporaryEvents(preview, true)

    local coords = start
    local originalPlayerCoords = GetEntityCoords(playerPed)
    local confirmed = false
    local cancelled = false

    lib.showTextUI(
        '[MOUSE] Aim  [LEFT CLICK] Place Ped  [W/S] Forward/Back  [A/D] Left/Right\n' ..
        '[Q/E] Down/Up  [←/→] Rotate  [SHIFT] Fast  [CTRL] Precision  [ENTER] Save  [BACKSPACE] Cancel',
        { position = 'top-center', icon = 'person' }
    )

    while DoesEntityExist(preview) and not confirmed and not cancelled do
        Wait(0)

        -- Freeze normal player actions but deliberately leave mouse-look enabled.
        DisableControlAction(0, 30, true) -- move left/right axis
        DisableControlAction(0, 31, true) -- move forward/back axis
        DisableControlAction(0, 32, true) -- W
        DisableControlAction(0, 33, true) -- S
        DisableControlAction(0, 34, true) -- A
        DisableControlAction(0, 35, true) -- D
        DisableControlAction(0, 44, true) -- Q
        DisableControlAction(0, 38, true) -- E
        DisableControlAction(0, 21, true) -- SHIFT
        DisableControlAction(0, 36, true) -- CTRL
        DisableControlAction(0, 174, true) -- left arrow
        DisableControlAction(0, 175, true) -- right arrow
        DisableControlAction(0, 191, true) -- ENTER
        DisableControlAction(0, 177, true) -- BACKSPACE
        DisableControlAction(0, 24, true) -- LEFT CLICK / attack
        DisableControlAction(0, 25, true) -- aim weapon
        DisablePlayerFiring(PlayerId(), true)

        -- Mouse placement: aim the camera at a surface and left-click to snap the
        -- preview there. A marker indicates the exact point that will be used.
        local mouseHit = getMouseWorldHit(playerPed)
        if mouseHit then
            DrawMarker(
                28,
                mouseHit.x, mouseHit.y, mouseHit.z + 0.03,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                0.18, 0.18, 0.18,
                255, 255, 255, 210,
                false, false, 2, false, nil, nil, false
            )

            if IsDisabledControlJustPressed(0, 24) then
                local distanceFromPlayer = #(mouseHit - originalPlayerCoords)
                if distanceFromPlayer <= Config.Placement.maxDistanceFromPlayer then
                    coords = vec3(mouseHit.x, mouseHit.y, mouseHit.z)
                else
                    NPCManager.Notify(('Placement is limited to %.0f metres from you.'):format(Config.Placement.maxDistanceFromPlayer), 'error')
                end
            end
        end

        local speed = Config.Placement.moveSpeed
        if IsDisabledControlPressed(0, 21) then speed = speed * Config.Placement.fastMultiplier end
        if IsDisabledControlPressed(0, 36) then speed = speed * Config.Placement.precisionMultiplier end

        local h = GetEntityHeading(preview)
        local forward = vec3(-math.sin(math.rad(h)), math.cos(math.rad(h)), 0.0)
        local right = rightVectorFromHeading(h)

        if IsDisabledControlPressed(0, 32) then coords = coords + forward * speed end -- W
        if IsDisabledControlPressed(0, 33) then coords = coords - forward * speed end -- S
        if IsDisabledControlPressed(0, 34) then coords = coords - right * speed end -- A
        if IsDisabledControlPressed(0, 35) then coords = coords + right * speed end -- D
        if IsDisabledControlPressed(0, 44) then coords = coords - vec3(0.0, 0.0, Config.Placement.verticalSpeed) end -- Q
        if IsDisabledControlPressed(0, 38) then coords = coords + vec3(0.0, 0.0, Config.Placement.verticalSpeed) end -- E

        if IsDisabledControlPressed(0, 174) then
            SetEntityHeading(preview, h + Config.Placement.rotateSpeed)
        elseif IsDisabledControlPressed(0, 175) then
            SetEntityHeading(preview, h - Config.Placement.rotateSpeed)
        end

        if #(coords - originalPlayerCoords) > Config.Placement.maxDistanceFromPlayer then
            local direction = coords - originalPlayerCoords
            coords = originalPlayerCoords + (direction / #direction) * Config.Placement.maxDistanceFromPlayer
        end

        SetEntityCoordsNoOffset(preview, coords.x, coords.y, coords.z, false, false, false)

        if IsDisabledControlJustPressed(0, 191) then
            confirmed = true
        elseif IsDisabledControlJustPressed(0, 177) then
            cancelled = true
        end
    end

    lib.hideTextUI()

    local result
    if confirmed and DoesEntityExist(preview) then
        local finalCoords = GetEntityCoords(preview)
        result = {
            x = finalCoords.x,
            y = finalCoords.y,
            z = finalCoords.z,
            w = GetEntityHeading(preview)
        }
    end

    if DoesEntityExist(preview) then DeleteEntity(preview) end
    SetModelAsNoLongerNeeded(hash)

    return result
end
