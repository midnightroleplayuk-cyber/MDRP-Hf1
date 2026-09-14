HF1PropPermissions = {}

local function hasWhitelistedIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    for i = 1, #identifiers do
        if Config.AllowedIdentifiers[identifiers[i]] then
            return true
        end
    end
    return false
end

function HF1PropPermissions.HasAccess(source)
    if source == 0 then return true end

    if Config.AcePermission and Config.AcePermission ~= '' and IsPlayerAceAllowed(source, Config.AcePermission) then
        return true
    end

    return hasWhitelistedIdentifier(source)
end

function HF1PropPermissions.GetCreatorIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    for i = 1, #identifiers do
        if identifiers[i]:sub(1, 8) == 'license:' then
            return identifiers[i]
        end
    end
    return identifiers[1] or ('source:%s'):format(source)
end
