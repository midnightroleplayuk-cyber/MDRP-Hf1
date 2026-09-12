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

