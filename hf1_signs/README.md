# HF1 Signs

Qbox/FiveM admin-managed image signs using ox_lib, DUI textures and persistent MySQL storage.

## Features

- `/sign` command
- Strict identifier allowlist for Kapper and Hardy
- ox_lib management menu
- New Sign / Manage Signs / Delete Sign
- Wall/surface-based 2D placement
- Purple flat rectangle placement preview
- Two-corner sizing directly on the hit surface
- Direct HTTPS PNG/JPG/JPEG/WEBP/GIF image URLs
- Persistent MySQL storage
- Configurable view distance
- DUI caching and a hard per-client active-DUI limit
- Throttled spatial/projection calculations
- Automatic cleanup when signs are deleted or images change

## Installation

1. Put `hf1_signs` into your resources folder.
2. Import `sql/hf1_signs.sql` into your database.
3. Ensure dependencies are started first:

```cfg
ensure ox_lib
ensure oxmysql
ensure qbx_core
ensure hf1_signs
```

4. Restart the resource/server.

## Permissions

`config.lua` contains only the two authorised identifiers:

```lua
Config.AllowedLicenses = {
    ['identifier.fivem:17286926'] = true, -- Kapper
    ['identifier.fivem:1059188'] = true,  -- Hardy
}
```

The server checks exact identifiers returned by FiveM and automatically handles the runtime `fivem:` form as well.

No Qbox `admin`/`god` group is required for this resource.

## Placement

Use `/sign` -> `New Sign`.

1. Aim at the top-left point of the wall/surface and press **E**.
2. Aim at the bottom-right point and press **E**.
3. The preview is constrained to the original surface, so the rectangle remains flat against the wall rather than forming a 3D box.
4. Enter the label, image URL and view distance.
5. The sign is saved to MySQL and synchronised to all players.

The resource stores the surface normal (`normal_x`, `normal_y`, `normal_z`) so the sign can retain its wall orientation after a restart.

## Existing database warning

If you already have signs in an older `qbox_signs` table, back up the database before migrating. The included SQL contains commented migration statements, but new installations should simply import `hf1_signs.sql`.

## Performance defaults

- Default view distance: 50.0m
- Maximum active DUI textures per client: 12
- Spatial update: 250ms
- Projection update: 100ms
- DUI unload grace period: 15 seconds

The database can contain many signs, while clients only activate nearby signs up to the configured DUI limit.
