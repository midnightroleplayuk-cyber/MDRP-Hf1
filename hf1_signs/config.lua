```lua
Config = {}

-- Permission groups accepted by /sign.
-- These remain enabled alongside the optional license allowlist below.
Config.AdminGroups = {
    'admin',
    'god'
}

-- Optional explicit FiveM license allowlist.
--
-- Add the full identifier exactly as shown by FiveM:
-- license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
-- license2:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--
-- A player is allowed if they have an AdminGroups permission OR
-- their license is listed here.
--
-- Leave empty to disable license-based access.
Config.AllowedLicenses = {
     ['identifier.fivem:17286926'] = true, -- Kapper
     ['identifier.fivem:1059188'] = true, -- Hardy
}

-- Command
Config.Command = 'sign'

-- Performance / streaming
-- Signs outside this distance will not be rendered.
Config.DefaultViewDistance = 50.0

-- Minimum and maximum distance that can be selected per sign.
Config.MinViewDistance = 10.0
Config.MaxViewDistance = 300.0

-- How long an image/DUI remains cached after the player leaves
-- the sign's viewing range.
--
-- This prevents constant loading/unloading when players move
-- around the edge of a sign's view distance.
Config.DuiUnloadGraceMs = 15000

-- Maximum number of active DUI/browser textures per client.
--
-- Important for performance. Even if there are 250 signs on the
-- server, each individual player will only load up to this many
-- image textures at once.
Config.MaxActiveDuis = 12

-- How often nearby signs are calculated.
--
-- 250ms is a good balance between responsiveness and performance.
Config.SpatialUpdateMs = 250

-- How often the world-to-screen projection for signs is recalculated.
--
-- The image is still drawn every frame when visible, but the
-- relatively expensive projection calculations are throttled.
Config.ProjectionUpdateMs = 100

-- Ignore signs that are so small on screen that they would
-- effectively be invisible.
Config.MinScreenSize = 0.003

-- Maximum physical sign dimensions.
Config.MinSignSize = 0.25
Config.MaxSignSize = 25.0

-- Image URL validation
--
-- HTTPS is recommended and enabled by default.
Config.RequireHttps = true

-- Supported image extensions.
--
-- PNG is fully supported.
Config.AllowedImageExtensions = {
    ['.png'] = true,
    ['.jpg'] = true,
    ['.jpeg'] = true,
    ['.webp'] = true,
    ['.gif'] = true
}

-- Purple placement preview.
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

-- Maximum image URL length.
Config.MaxUrlLength = 2048

-- Database table name.
Config.DatabaseTable = 'hf1_signs'

-- Prevent players repeatedly opening /sign extremely quickly.
Config.RequestCooldownMs = 750

-- Ownership system.
--
-- true:
--   Admins can only edit/delete signs they personally created.
--
-- false:
--   Any authorised admin can edit/delete any sign.
Config.OwnershipOnly = true
```
