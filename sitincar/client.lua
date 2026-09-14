local MAX_DISTANCE = 8.0

local function getClosestVehicle(coords)
    local vehicles = GetGamePool('CVehicle')
    local closestVehicle = nil
    local closestDistance = MAX_DISTANCE + 0.01

    for i = 1, #vehicles do
        local vehicle = vehicles[i]

        if DoesEntityExist(vehicle) then
            local vehicleCoords = GetEntityCoords(vehicle)
            local distance = #(coords - vehicleCoords)

            if distance < closestDistance then
                closestDistance = distance
                closestVehicle = vehicle
            end
        end
    end

    return closestVehicle
end

RegisterCommand('sitincar', function()
    local ped = PlayerPedId()

    if IsPedInAnyVehicle(ped, false) then
        return
    end

    local coords = GetEntityCoords(ped)
    local vehicle = getClosestVehicle(coords)

    if not vehicle or vehicle == 0 then
        TriggerEvent('chat:addMessage', {
            color = { 255, 80, 80 },
            args = { 'SITINCAR', 'No vehicle found nearby.' }
        })
        return
    end

    local driver = GetPedInVehicleSeat(vehicle, -1)

    -- Remove an NPC driver if one is occupying the seat.
    -- Player drivers are left alone.
    if driver ~= 0 and DoesEntityExist(driver) then
        if not IsPedAPlayer(driver) then
            SetEntityAsMissionEntity(driver, true, true)
            DeleteEntity(driver)

            if DoesEntityExist(driver) then
                TaskLeaveVehicle(driver, vehicle, 16)
                Wait(250)
                DeleteEntity(driver)
            end
        else
            TriggerEvent('chat:addMessage', {
                color = { 255, 80, 80 },
                args = { 'SITINCAR', 'A player is already in the driver seat.' }
            })
            return
        end
    end

    -- Instantly place the player into the driver seat.
    SetPedIntoVehicle(ped, vehicle, -1)
end, false)
