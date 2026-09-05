local targetCoords = vector3(447.835, -990.599, 35.93)
local triggerDistance = 1.3
local saluteDuration = 6333 -- 6.3 seconds in milliseconds
local allowedJob = "police" -- Allowed job name
local isSaluting = false

CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()

        if not isSaluting then
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - targetCoords)

            if distance <= triggerDistance then
                -- Qbox native group check: verify if the player has the required job
                local isPolice = exports.qbx_core:HasGroup(allowedJob)

                if isPolice then
                    sleep = 0
                    
                    -- Display standard GTA top-left help notification
                    DisplayHelpText("Press ~INPUT_CONTEXT~ to Pay Respect.")

                    -- Check if player presses 'E' (Control Key 38 / INPUT_CONTEXT)
                    if IsControlJustPressed(0, 38) then
                        TriggerSalute()
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

function TriggerSalute()
    isSaluting = true

    -- Trigger the emote via command
    ExecuteCommand("e salute")

    -- Play audio via NUI
    SendNUIMessage({
        action = "playMusic",
        volume = 0.3
    })

    -- Wait for 7 seconds
    SetTimeout(saluteDuration, function()
        -- Cancel emote
        ExecuteCommand("e c")

        -- Stop audio
        SendNUIMessage({
            action = "stopMusic"
        })

        isSaluting = false
    end)
end

-- Function to render default GTA native help text in the top-left corner
function DisplayHelpText(text)
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end