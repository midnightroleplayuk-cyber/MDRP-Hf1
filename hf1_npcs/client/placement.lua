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
    if hit == 1 then return endCoords end
    return nil
end

-- Raycasts can hit slightly below/inside collision. Resolve a clean ground Z at
-- the selected X/Y where possible, but fall back to the ray hit for stairs,
-- interiors and unusual surfaces.
local function resolveSurfacePoint(hit)
    if not hit then return nil end

    local probes = { 1.5, 3.0, 8.0, 20.0 }
    for i = 1, #probes do
        local found, groundZ = GetGroundZFor_3dCoord(hit.x, hit.y, hit.z + probes[i], false)
        if found then
            return vec3(hit.x, hit.y, groundZ)
        end
    end

    return vec3(hit.x, hit.y, hit.z)
end

function NPCManager.PlacePed(model, existingCoords)
    local hash, err = NPCManager.LoadModel(model)
    if not hash then
        NPCManager.Notify(err, 'error')
        return nil
    end

    local playerPed = cache.ped
    local playerCoords = GetEntityCoords(playerPed)
    local start
    local heading

    if existingCoords then
        start = vec3(existingCoords.x, existingCoords.y, existingCoords.z)
        heading = existingCoords.w or GetEntityHeading(playerPed)
    else
        -- Start on the player's ground plane rather than camera pitch, so the
        -- preview always has a sensible initial position.
        local h = GetEntityHeading(playerPed)
        local forward = vec3(-math.sin(math.rad(h)), math.cos(math.rad(h)), 0.0)
        start = playerCoords + (forward * Config.Placement.distanceInFront)
        local found, groundZ = GetGroundZFor_3dCoord(start.x, start.y, playerCoords.z + 3.0, false)
        if found then start = vec3(start.x, start.y, groundZ) end
        heading = h
    end

    -- Spawn once using model bounds as a safe starting point, then calibrate the
    -- real origin-to-ground offset from the ped's actual foot bones. Model bounds
    -- often include invisible geometry below the shoes, which is what caused the
    -- visible hover even when the maths looked correct.
    local minDim, _ = GetModelDimensions(hash)
    local fallbackOffset = math.max(0.0, -minDim.z)
    local preview = CreatePed(4, hash, start.x, start.y, start.z + fallbackOffset, heading, false, false)
    if not preview or preview == 0 then
        SetModelAsNoLongerNeeded(hash)
        NPCManager.Notify('Could not create the placement preview for this ped model.', 'error')
        return nil
    end

    local function calculateFeetOffset(entity)
        local entityZ = GetEntityCoords(entity).z
        local leftFoot = GetPedBoneCoords(entity, 14201, 0.0, 0.0, 0.0) -- SKEL_L_Foot
        local rightFoot = GetPedBoneCoords(entity, 52301, 0.0, 0.0, 0.0) -- SKEL_R_Foot

        if leftFoot and rightFoot then
            local lowestFootZ = math.min(leftFoot.z, rightFoot.z)
            local offset = entityZ - lowestFootZ
            if offset > 0.05 and offset < 3.0 then
                -- Foot bones sit slightly above the visible sole, so add a tiny
                -- sole allowance. This is much more consistent than model bounds.
                return offset + (Config.Placement.soleOffset or 0.025)
            end
        end

        return fallbackOffset + (Config.Placement.groundOffset or 0.0)
    end

    Wait(0)
    local feetOffset = calculateFeetOffset(preview)

    local function placePreviewAtGroundPoint(point)
        RequestCollisionAtCoord(point.x, point.y, point.z)
        SetEntityCoordsNoOffset(preview, point.x, point.y, point.z + feetOffset, false, false, false)
    end

    placePreviewAtGroundPoint(start)
    SetEntityAlpha(preview, 190, false)
    SetEntityCollision(preview, false, false)
    SetEntityInvincible(preview, true)
    FreezeEntityPosition(preview, true)
    SetBlockingOfNonTemporaryEvents(preview, true)

    local coords = start
    local originalPlayerCoords = playerCoords
    local confirmed = false
    local cancelled = false
    local hasChosenPosition = existingCoords ~= nil
    local previewNeedsGroundSnap = false
    local manualHeightOffset = 0.0

    lib.showTextUI(
        '[MOUSE] Aim  [LEFT CLICK] Set Position  [W/S/A/D] Fine Move\n' ..
        '[Q/E] Height  [←/→] Rotate  [SHIFT] Fast  [CTRL] Precision  [ENTER] Save  [BACKSPACE] Cancel',
        { position = 'top-center', icon = 'person' }
    )

    while DoesEntityExist(preview) and not confirmed and not cancelled do
        Wait(0)

        DisableControlAction(0, 30, true)
        DisableControlAction(0, 31, true)
        DisableControlAction(0, 32, true)
        DisableControlAction(0, 33, true)
        DisableControlAction(0, 34, true)
        DisableControlAction(0, 35, true)
        DisableControlAction(0, 44, true)
        DisableControlAction(0, 38, true)
        DisableControlAction(0, 21, true)
        DisableControlAction(0, 36, true)
        DisableControlAction(0, 174, true)
        DisableControlAction(0, 175, true)
        DisableControlAction(0, 191, true)
        DisableControlAction(0, 177, true)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisablePlayerFiring(PlayerId(), true)

        local rawHit = getMouseWorldHit(playerPed)
        local mouseHit = resolveSurfacePoint(rawHit)
        if mouseHit then
            DrawMarker(
                28,
                mouseHit.x, mouseHit.y, mouseHit.z + 0.035,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                0.18, 0.18, 0.18,
                255, 255, 255, 210,
                false, false, 2, false, nil, nil, false
            )

            if IsDisabledControlJustPressed(0, 24) then
                local distanceFromPlayer = #(mouseHit - originalPlayerCoords)
                if distanceFromPlayer <= Config.Placement.maxDistanceFromPlayer then
                    coords = mouseHit
                    manualHeightOffset = 0.0
                    previewNeedsGroundSnap = true
                    hasChosenPosition = true
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
        local moved = false

        if IsDisabledControlPressed(0, 32) then coords = coords + forward * speed; moved = true end
        if IsDisabledControlPressed(0, 33) then coords = coords - forward * speed; moved = true end
        if IsDisabledControlPressed(0, 34) then coords = coords - right * speed; moved = true end
        if IsDisabledControlPressed(0, 35) then coords = coords + right * speed; moved = true end

        if IsDisabledControlPressed(0, 44) then
            manualHeightOffset = manualHeightOffset - Config.Placement.verticalSpeed
            moved = true
        end
        if IsDisabledControlPressed(0, 38) then
            manualHeightOffset = manualHeightOffset + Config.Placement.verticalSpeed
            moved = true
        end

        if moved then
            previewNeedsGroundSnap = true
            hasChosenPosition = true
        end

        if IsDisabledControlPressed(0, 174) then
            SetEntityHeading(preview, h + Config.Placement.rotateSpeed)
        elseif IsDisabledControlPressed(0, 175) then
            SetEntityHeading(preview, h - Config.Placement.rotateSpeed)
        end

        local dist = #(coords - originalPlayerCoords)
        if dist > Config.Placement.maxDistanceFromPlayer and dist > 0.001 then
            local direction = coords - originalPlayerCoords
            coords = originalPlayerCoords + (direction / dist) * Config.Placement.maxDistanceFromPlayer
        end

        if previewNeedsGroundSnap then
            -- Resolve the visual preview against real collision, matching the
            -- final streamed spawn. Horizontal nudges stay grounded; Q/E adds
            -- an intentional visual height offset on top.
            placePreviewAtGroundPoint(coords)
            if math.abs(manualHeightOffset) > 0.0001 then
                local grounded = GetEntityCoords(preview)
                SetEntityCoordsNoOffset(preview, grounded.x, grounded.y, grounded.z + manualHeightOffset, false, false, false)
            end
            previewNeedsGroundSnap = false
        end

        if IsDisabledControlJustPressed(0, 191) then
            if hasChosenPosition then
                confirmed = true
            else
                NPCManager.Notify('Left-click a surface to choose where the NPC should stand first.', 'error')
            end
        elseif IsDisabledControlJustPressed(0, 177) then
            cancelled = true
        end
    end

    lib.hideTextUI()

    local result
    if confirmed and DoesEntityExist(preview) then
        result = {
            x = coords.x,
            y = coords.y,
            z = coords.z + manualHeightOffset,
            w = GetEntityHeading(preview)
        }
    end

    if DoesEntityExist(preview) then DeleteEntity(preview) end
    SetModelAsNoLongerNeeded(hash)

    return result
end
