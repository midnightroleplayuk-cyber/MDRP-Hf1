CreateThread(function()
    SetUserRadioControlEnabled(false)

    while true do
        Wait(500)

        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)

            SetVehicleRadioEnabled(vehicle, false)
            SetVehRadioStation(vehicle, 'OFF')
        end
    end
end)