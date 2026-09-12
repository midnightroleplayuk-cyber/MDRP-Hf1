RegisterNetEvent('hf1_atms:server:useATM', function(atmCoords)
    local src = source
    local playerPed = GetPlayerPed(src)
    
    if not playerPed or playerPed == 0 then return end

    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(playerCoords - atmCoords)

    -- Enforce distance check (5.0 units + slight latency buffer)
    if distance <= 5.0 then
        -- Triggers the command on the client side
        TriggerClientEvent('hf1_atms:client:openATM', src)
        return
    end
end)