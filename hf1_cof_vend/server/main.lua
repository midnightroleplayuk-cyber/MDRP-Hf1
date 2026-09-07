local reservations, cooldowns = {}, {}

local function tokenFor(source)
    return ('%s:%s:%s'):format(source, GetGameTimer(), math.random(100000, 999999))
end

lib.callback.register('qbox-coffee-machine:server:reserve', function(source)
    local now = os.time()
    if cooldowns[source] and cooldowns[source] > now then
        exports.qbx_core:Notify(source, ('Please wait %ss before making another coffee.'):format(cooldowns[source] - now), 'error')
        return false
    end
    if not exports.ox_inventory:CanCarryItem(source, Config.CoffeeItem, 1) then
        exports.qbx_core:Notify(source, 'You do not have enough inventory space for a coffee.', 'error')
        return false
    end
    if Config.Price > 0 then
        local balance = exports.qbx_core:GetMoney(source, Config.MoneyType)
        if not balance or balance < Config.Price then
            exports.qbx_core:Notify(source, ('You need $%s for a coffee.'):format(Config.Price), 'error')
            return false
        end
        if not exports.qbx_core:RemoveMoney(source, Config.MoneyType, Config.Price, 'coffee-machine') then
            exports.qbx_core:Notify(source, 'The payment could not be processed.', 'error')
            return false
        end
    end
    local token = tokenFor(source)
    reservations[token] = { source = source, expires = now + Config.ReservationTimeout, item = Config.CoffeeItem }
    return token
end)

lib.callback.register('qbox-coffee-machine:server:finish', function(source, token)
    local reservation = reservations[token]
    reservations[token] = nil
    if not reservation or reservation.source ~= source or reservation.expires < os.time() then return false end
    if not exports.ox_inventory:CanCarryItem(source, reservation.item, 1) then return false end
    local success = exports.ox_inventory:AddItem(source, reservation.item, 1)
    if not success then return false end
    cooldowns[source] = os.time() + Config.Cooldown
    return true
end)

RegisterNetEvent('qbox-coffee-machine:server:cancel', function(token)
    local source, reservation = source, reservations[token]
    if reservation and reservation.source == source then reservations[token] = nil end
end)

AddEventHandler('playerDropped', function()
    local source = source
    cooldowns[source] = nil
    for token, reservation in pairs(reservations) do
        if reservation.source == source then reservations[token] = nil end
    end
end)

CreateThread(function()
    while true do
        Wait(30000)
        local now = os.time()
        for token, reservation in pairs(reservations) do
            if reservation.expires < now then reservations[token] = nil end
        end
    end
end)
