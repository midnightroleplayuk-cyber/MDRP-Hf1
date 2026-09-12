RegisterNetEvent('qbx_overheadid:server:requestIds', function()
    local src = source
    local srcPed = GetPlayerPed(src)
    local srcCoords = GetEntityCoords(srcPed)

    local nearbyPlayers = {}
    local players = exports.qbx_core:GetQBPlayers()

    for _, player in pairs(players) do
        local targetSrc = player.PlayerData.source
        local targetPed = GetPlayerPed(targetSrc)

        if DoesEntityExist(targetPed) then
            local targetCoords = GetEntityCoords(targetPed)
            if #(srcCoords - targetCoords) <= 25.0 then
                table.insert(nearbyPlayers, { id = targetSrc })
            end
        end
    end

    TriggerClientEvent('qbx_overheadid:client:displayIds', src, nearbyPlayers)
end)