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
}

Config.Placement = {
    distanceInFront = 2.0,
    moveSpeed = 0.035,
    fastMultiplier = 4.0,
    precisionMultiplier = 0.25,
    rotateSpeed = 1.25,
    verticalSpeed = 0.025,
    maxDistanceFromPlayer = 30.0,
}

Config.Sync = {
    applyDistance = 200.0,
    refreshInterval = 1500,
}

Config.Debug = false
