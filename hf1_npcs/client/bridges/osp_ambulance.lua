-- OSP Ambulance V2 compatibility bridge.
--
-- hf1_npcs dialogue client events receive the NPC interaction payload, while
-- OSP's check-in event expects: { hospitalID = <number> }.
-- This bridge translates between the two without modifying OSP Ambulance.

RegisterNetEvent('hf1_npcs:client:ospCheckIn', function(data)
    local integration = Config.Integrations
        and Config.Integrations.OSPAmbulance
        or {}

    local resourceName = integration.resource or 'osp_ambulance'
    if GetResourceState(resourceName) ~= 'started' then
        lib.notify({
            title = 'Hospital',
            description = 'Hospital treatment is currently unavailable.',
            type = 'error'
        })
        return
    end

    -- Allows a future/custom caller to override the configured hospital ID,
    -- while normal hf1_npcs dialogue usage falls back to Config.
    local hospitalID = type(data) == 'table' and tonumber(data.hospitalID) or nil
    hospitalID = hospitalID or tonumber(integration.hospitalID) or 1

    TriggerEvent('osp_ambulance:checkin', {
        hospitalID = hospitalID
    })
end)
