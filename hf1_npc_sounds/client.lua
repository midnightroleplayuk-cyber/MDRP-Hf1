local function validSoundName(name)
    return type(name) == 'string'
        and name ~= ''
        and name:match('^[%w%._%-]+%.ogg$') ~= nil
        and not name:find('%.%.', 1, true)
end

RegisterNetEvent('hf1_npc_sounds:play', function(soundName, volume)
    if not validSoundName(soundName) then return end

    SendNUIMessage({
        action = 'play',
        sound = soundName,
        volume = math.max(0.0, math.min(1.0, tonumber(volume) or 0.65)),
    })
end)

RegisterNetEvent('hf1_npc_sounds:stop', function()
    SendNUIMessage({ action = 'stop' })
end)

RegisterCommand('hf1npctestsound', function(_, args)
    local soundName = args and args[1] or 'weekend.ogg'
    if not validSoundName(soundName) then
        print(('[hf1_npc_sounds] Invalid sound name: %s'):format(tostring(soundName)))
        return
    end

    print(('[hf1_npc_sounds] Playing test sound: %s'):format(soundName))
    TriggerEvent('hf1_npc_sounds:play', soundName, 0.8)
end, false)
