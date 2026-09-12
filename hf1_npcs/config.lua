Config = {}

Config.Command = 'createnpc'
Config.Keybind = 'INSERT'

-- Grant this ACE to your admin principal, for example:
-- add_ace group.admin hf1_npcs.admin allow
Config.AcePermission = 'hf1_npcs.admin'

-- Optional identifier whitelist. Either ACE permission OR a matching identifier grants access.
-- Supports license:, license2:, discord:, fivem:, etc.
Config.AllowedIdentifiers = {
    -- ['license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'] = true,
       ['fivem:1059188'] = true, --HARDY
}

Config.Defaults = {
    invincible = true,
    frozen = true,
    blockEvents = true,
    canRagdoll = false,
    collision = true,
    scenario = '',
    animDict = '',
    animName = '',
    animFlag = 1,
    spawnDistance = 150.0,
    targetEnabled = false,
    targetLabel = 'Interact',
    targetIcon = 'fa-solid fa-user',
    targetEvent = '',
    targetMode = 'event',
}

Config.Placement = {
    distanceInFront = 2.0,
    moveSpeed = 0.035,
    fastMultiplier = 4.0,
    precisionMultiplier = 0.25,
    rotateSpeed = 1.25,
    verticalSpeed = 0.025,
    maxDistanceFromPlayer = 30.0,
    -- Fallback correction used only if a ped has no usable foot bones.
    groundOffset = 0.0,
    -- Foot bones are a little above the visible bottom of the shoe. This small
    -- clearance keeps the visible sole just above the collision plane to avoid
    -- shoe clipping while keeping preview and final spawn perfectly matched.
    soleOffset = 0.090,
}

Config.Sync = {
    applyDistance = 200.0,
    refreshInterval = 1500,
}


-- Optional dialogue response sounds.
-- Put .ogg files in html/sounds/ and add them here so admins can select them.
-- Example:
-- { label = 'Gang - Deal accepted', value = 'gang_accept.ogg' },
-- { label = 'Dealer - Thanks', value = 'dealer_thanks.ogg' },
Config.DialogueSounds = {
    { label = 'Weekend', value = 'weekend.ogg' },
}

-- Local volume for dialogue response sounds (0.0 - 1.0).
Config.DialogueSoundVolume = 0.65

Config.Debug = false
