Config = {}

-- =========================================================
-- PERMISSIONS
-- =========================================================
-- ONLY these two identifiers can use /sign.
Config.AllowedLicenses = {
    ['identifier.fivem:17286926'] = true, -- Kapper
    ['identifier.fivem:1059188'] = true,  -- Hardy
}

Config.Command = 'sign'

-- =========================================================
-- PERFORMANCE
-- =========================================================
Config.DefaultViewDistance = 50.0
Config.MinViewDistance = 10.0
Config.MaxViewDistance = 300.0
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
Config.SurfaceOffset = 0.008
Config.PlacementRayDistance = 1000.0

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
-- PLACEMENT PREVIEW
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
-- REQUEST COOLDOWN
-- =========================================================
Config.RequestCooldownMs = 750

-- Either authorised person can manage any sign.
Config.OwnershipOnly = false
