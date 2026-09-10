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
        '[W/S] Forward/Back  [A/D] Left/Right  [Q/E] Down/Up\n' ..
        '[←/→] Rotate  [SHIFT] Fast  [CTRL] Precision  [ENTER] Save Position  [BACKSPACE] Cancel',
        { position = 'top-center', icon = 'person' }
    )

    while DoesEntityExist(preview) and not confirmed and not cancelled do
        Wait(0)

        DisableControlAction(0, 30, true)
        DisableControlAction(0, 31, true)
        DisableControlAction(0, 21, true)
        DisableControlAction(0, 36, true)
        DisableControlAction(0, 191, true)
        DisableControlAction(0, 177, true)

        local speed = Config.Placement.moveSpeed
        if IsDisabledControlPressed(0, 21) then speed = speed * Config.Placement.fastMultiplier end
        if IsDisabledControlPressed(0, 36) then speed = speed * Config.Placement.precisionMultiplier end

        local h = GetEntityHeading(preview)
        local forward = vec3(-math.sin(math.rad(h)), math.cos(math.rad(h)), 0.0)
        local right = rightVectorFromHeading(h)

        if IsControlPressed(0, 32) then coords = coords + forward * speed end -- W
        if IsControlPressed(0, 33) then coords = coords - forward * speed end -- S
        if IsControlPressed(0, 34) then coords = coords - right * speed end -- A
        if IsControlPressed(0, 35) then coords = coords + right * speed end -- D
        if IsControlPressed(0, 44) then coords = coords - vec3(0.0, 0.0, Config.Placement.verticalSpeed) end -- Q
        if IsControlPressed(0, 38) then coords = coords + vec3(0.0, 0.0, Config.Placement.verticalSpeed) end -- E

        if IsControlPressed(0, 174) then
            SetEntityHeading(preview, h + Config.Placement.rotateSpeed)
        elseif IsControlPressed(0, 175) then
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
