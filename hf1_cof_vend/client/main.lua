local busy = false

local function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) do
        Wait(10)
        if GetGameTimer() > timeout then return false end
    end
    return true
end

local function loadModel(model)
    if HasModelLoaded(model) then return true end
    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) do
        Wait(10)
        if GetGameTimer() > timeout then return false end
    end
    return true
end

local function notify(description, type)
    lib.notify({ title = 'Coffee Machine', description = description, type = type or 'inform' })
end

local function playCoffeeSound()
    if not Config.Sound.enabled then return end
    SendNUIMessage({ action = 'play', file = Config.Sound.file, volume = Config.Sound.volume })
end

local function createCup(machine)
    if not DoesEntityExist(machine) or not loadModel(Config.Cup.model) then return nil end
    local pos = GetOffsetFromEntityInWorldCoords(machine, Config.Cup.offset.x, Config.Cup.offset.y, Config.Cup.offset.z)
    local cup = CreateObjectNoOffset(Config.Cup.model, pos.x, pos.y, pos.z, false, false, false)
    if not DoesEntityExist(cup) then
        SetModelAsNoLongerNeeded(Config.Cup.model)
        return nil
    end
    SetEntityRotation(cup, Config.Cup.rotation.x, Config.Cup.rotation.y, Config.Cup.rotation.z, 2, true)
    FreezeEntityPosition(cup, true)
    SetEntityCollision(cup, false, false)
    SetModelAsNoLongerNeeded(Config.Cup.model)
    return cup
end

local function popCup(cup, machine)
    if not DoesEntityExist(cup) or not DoesEntityExist(machine) then return end
    local start = GetOffsetFromEntityInWorldCoords(machine, Config.Cup.offset.x, Config.Cup.offset.y, Config.Cup.offset.z)
    local finish = GetOffsetFromEntityInWorldCoords(machine, Config.Cup.offset.x, Config.Cup.offset.y - Config.Cup.popDistance, Config.Cup.offset.z + Config.Cup.popHeight)
    local started = GetGameTimer()
    while DoesEntityExist(cup) do
        local p = math.min((GetGameTimer() - started) / Config.Cup.popTime, 1.0)
        local e = 1.0 - ((1.0 - p) ^ 3)
        SetEntityCoordsNoOffset(cup,
            start.x + (finish.x - start.x) * e,
            start.y + (finish.y - start.y) * e,
            start.z + (finish.z - start.z) * e,
            false, false, false)
        if p >= 1.0 then break end
        Wait(0)
    end
end

local function deleteCup(cup)
    if cup and DoesEntityExist(cup) then DeleteEntity(cup) end
end

local function playAnim(ped, anim)
    if not loadAnimDict(anim.dict) then return false end
    TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, -8.0, anim.duration, anim.flag, 0.0, false, false, false)
    return true
end

local function stopAnimations(ped)
    StopAnimTask(ped, Config.ButtonAnimation.dict, Config.ButtonAnimation.clip, 3.0)
    StopAnimTask(ped, Config.GrabAnimation.dict, Config.GrabAnimation.clip, 3.0)
    ClearPedTasks(ped)
end

local function startCoffee(machine)
    if busy or not DoesEntityExist(machine) then return end
    local ped = cache.ped
    if IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) then return end
    if #(GetEntityCoords(ped) - GetEntityCoords(machine)) > Config.TargetDistance + 0.75 then return end

    busy = true
    local token = lib.callback.await('qbox-coffee-machine:server:reserve', false)
    if not token then busy = false return end

    TaskTurnPedToFaceEntity(ped, machine, Config.FaceMachineTime)
    Wait(Config.FaceMachineTime)

    if IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) then
        TriggerServerEvent('qbox-coffee-machine:server:cancel', token)
        busy = false
        return
    end

    playAnim(ped, Config.ButtonAnimation)
    Wait(450)
    playCoffeeSound()
    Wait(900)

    local cup = createCup(machine)
    if cup then popCup(cup, machine) end

    playAnim(ped, Config.GrabAnimation)
    Wait(550)

    if cup and DoesEntityExist(cup) then
        DetachEntity(cup, true, true)
        FreezeEntityPosition(cup, false)
        SetEntityCollision(cup, false, false)
        AttachEntityToEntity(cup, ped, GetPedBoneIndex(ped, 57005), 0.12, 0.02, -0.02, -85.0, 0.0, 0.0, true, true, false, true, 2, true)
    end

    Wait(650)
    local added = lib.callback.await('qbox-coffee-machine:server:finish', false, token)
    if cup and DoesEntityExist(cup) then Wait(250) deleteCup(cup) end
    stopAnimations(ped)
    busy = false

    if not added then notify('You could not carry the coffee.', 'error') end
end

exports.ox_target:addModel(Config.MachineModel, {
    {
        name = 'qbox_coffee_machine:grab',
        icon = Config.TargetIcon,
        label = Config.TargetLabel,
        distance = Config.TargetDistance,
        canInteract = function(entity)
            return not busy and DoesEntityExist(entity) and not IsEntityDead(cache.ped) and not IsPedInAnyVehicle(cache.ped, false)
        end,
        onSelect = function(data)
            CreateThread(function() startCoffee(data.entity) end)
        end
    }
})

exports('coffee', function(data)
    exports.ox_inventory:useItem(data, function(used)
        if not used then return end
        local finished = lib.progressCircle({
            duration = Config.Drink.duration,
            label = Config.Drink.label,
            position = 'bottom',
            useWhileDead = false,
            canCancel = true,
            disable = { move = true, car = true, combat = true },
            anim = Config.Drink.anim,
            prop = Config.Drink.prop,
        })
        lib.notify({
            title = 'Coffee',
            description = finished and 'That hit the spot.' or 'You stopped drinking the coffee.',
            type = finished and 'success' or 'inform'
        })
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and busy then ClearPedTasks(cache.ped) end
end)
