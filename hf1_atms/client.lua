local atmModels = {
    `prop_atm_01`,
    `prop_atm_02`,
    `prop_atm_03`,
    `prop_fleeca_atm`,
    `prop_atm_01_tube`,
    `prop_atm_02_strap`,
    `prop_atm_03_pole`
}

CreateThread(function()
    exports.ox_target:addModel(atmModels, {
        {
            name = 'use_atm_target',
            icon = 'fa-solid fa-credit-card', -- Fixed FontAwesome icon syntax
            label = 'Use ATM',
            distance = 3.0,
            onSelect = function(data)
                local entityCoords = GetEntityCoords(data.entity)
                TriggerServerEvent('hf1_atms:server:useATM', entityCoords)
            end
        }
    })
end)

-- Listens for server approval and triggers /atm on the player's client
RegisterNetEvent('hf1_atms:client:openATM', function()
    ExecuteCommand('atm')
end)