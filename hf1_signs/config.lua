Config = {}

-- =========================================================
-- PERMISSIONS
-- =========================================================

-- Only these two identifiers can use /sign.
-- The server also accepts the equivalent runtime FiveM format
-- (fivem:XXXXXXXX) automatically.
Config.AllowedLicenses = {
    ['identifier.fivem:17286926'] = true, -- Kapper
    ['identifier.fivem:1059188'] = true,  -- Hardy
}

Config.Command = 'sign'

-- =========================================================
-- PERFORMANCE / STREAMING
-- =========================================================

Config.DefaultViewDistance = 50.0
Config.MinViewDistance = 10.0
Config.MaxViewDistance = 250.0

Config.DuiUnloadGraceMs = 15000
Config.MaxActiveDuis = 12
Config.SpatialUpdateMs = 250
Config.ProjectionUpdateMs = 100
Config.MinScreenSize = 0.003

-- =========================================================
-- SIGN SIZE
-- =========================================================

Config.MinSignSize = 0.25
Config.MaxSignSize = 25.0

-- Small offset away from the hit surface to prevent z-fighting.
Config.SurfaceOffset = 0.01

-- Maximum distance used while placing a sign.
Config.PlacementRayDistance = 50.0

-- =========================================================
-- IMAGE URL VALIDATION
-- =========================================================

Config.RequireHttps = true

Config.AllowedImageExtensions = {
    ['.png'] = true,
    ['.jpg'] = true,
    ['.jpeg'] = true,
    ['.webp'] = true,
    ['.gif'] = true
}

Config.MaxUrlLength = 2048

-- =========================================================
-- PURPLE PLACEMENT PREVIEW
-- =========================================================

Config.SelectionColor = {
    r = 160,
    g = 80,
    b = 255,
    a = 180
}

Config.SelectionLineColor = {
    r = 190,
    g = 110,
    b = 255,
    a = 255
}

-- =========================================================
-- DATABASE
-- =========================================================

Config.DatabaseTable = 'hf1_signs'

-- =========================================================
-- COMMAND COOLDOWN
-- =========================================================

Config.RequestCooldownMs = 750

-- Both authorised users can edit/delete any sign.
Config.OwnershipOnly = false
