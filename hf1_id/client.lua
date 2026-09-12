local showingIds = false

-- Helper function to draw 3D text
local function DrawText3D(coords, text)
    local onScreen, _x, _y = World3dToScreen2d(coords.x, coords.y, coords.z + 1.0)
    
    if onScreen then
        SetTextScale(1.0, 0.5)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(179, 83, 253, 255) -- Purple RGB Color
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

-- Keybind Registration (Ox Lib)
lib.addKeybind({
    name = 'show_overhead_id',
    description = 'Toggle Overhead ID Display',
    defaultKey = 'F11',
    onPressed = function()
        if showingIds then return end

        TriggerServerEvent('qbx_overheadid:server:requestIds')
    end
})

-- Handle receiving nearby player data
RegisterNetEvent('qbx_overheadid:client:displayIds', function(playerData)
    if showingIds then return end
    showingIds = true

    local endTime = GetGameTimer() + 5000 -- 5 Seconds

    CreateThread(function()
        while GetGameTimer() < endTime do
            local myPed = PlayerPedId()
            local myCoords = GetEntityCoords(myPed)

            for _, player in ipairs(playerData) do
                local targetPed = GetPlayerPed(GetPlayerFromServerId(player.id))
                
                if DoesEntityExist(targetPed) then
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(myCoords - targetCoords)

                    -- Render distance limit (15.0 meters)
                    if distance <= 15.0 then
                        DrawText3D(targetCoords, tostring(player.id))
                    end
                end
            end
            Wait(0)
        end
        showingIds = false
    end)
end)