Config = {}

-- Permission groups accepted by /sign.
Config.AdminGroups = {
    'admin',
    'god'
}

Config.Command = 'sign'

-- Performance / streaming
-- Signs outside this distance are not rendered or kept as active DUI textures.
Config.DefaultViewDistance = 50.0
Config.MinViewDistance = 10.0
Config.MaxViewDistance = 300.0

-- How long an image texture stays cached after leaving its range.
-- A small grace period avoids repeated browser creation when moving around.
Config.DuiUnloadGraceMs = 15000

-- Hard cap on simultaneously active DUI browser textures per client.
-- If exceeded, the farthest/least-recently-used signs are not given a DUI.
Config.MaxActiveDuis = 12

-- How often the client refreshes the nearby-sign candidate list.
-- Lower = more responsive streaming; higher = less client work.
Config.SpatialUpdateMs = 250

-- How often projected screen rectangles are recalculated.
-- The texture itself is still drawn every frame when visible.
Config.ProjectionUpdateMs = 100

-- Don't render tiny signs that are effectively sub-pixel on screen.
Config.MinScreenSize = 0.003

-- Placement limits
Config.MinSignSize = 0.25
Config.MaxSignSize = 25.0

-- Image URL validation
Config.RequireHttps = true
Config.AllowedImageExtensions = {
    ['.png'] = true,
    ['.jpg'] = true,
    ['.jpeg'] = true,
    ['.webp'] = true,
    ['.gif'] = true
}

Config.SelectionColor = { r = 160, g = 80, b = 255, a = 180 }
Config.SelectionLineColor = { r = 190, g = 110, b = 255, a = 255 }

Config.MaxUrlLength = 2048
Config.DatabaseTable = 'hf1_signs'

-- Small server-side cooldown for opening the menu.
Config.RequestCooldownMs = 750

-- If true, an admin can only edit/delete signs they created.
-- This matches the "your custom signs" management behaviour.
Config.OwnershipOnly = true
