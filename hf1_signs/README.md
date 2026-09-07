# Qbox Signs — Optimised Edition

Admin-only `/sign` system for Qbox using ox_lib, oxmysql and FiveM DUI/runtime textures.

## Included

- `/sign` command
- Server-side Qbox admin permission checks
- ox_lib menus:
  - New Sign
  - Manage Signs
  - Delete Sign
- Two-corner placement with a purple live selection preview
- Direct remote image URLs with `.png` support
- Persistent MySQL storage
- World image rendering using DUI/runtime textures
- Distance-based sign streaming
- Candidate refresh throttling
- Projection throttling
- Active DUI/browser texture cap
- DUI cache grace period to reduce create/destroy churn
- Server-side URL, size and distance validation

## Performance target

The client does **not** create a DUI for all 250 signs.

The resource first filters signs by their configured viewing distance every `Config.SpatialUpdateMs`
milliseconds. It then keeps at most `Config.MaxActiveDuis` image/browser textures active for the
client, prioritising the nearest signs.

Screen projection is recalculated at `Config.ProjectionUpdateMs`, rather than doing four world-to-
screen calculations for every sign on every frame. The final texture draw is only performed for
currently nearby/active signs.

For a 100-player server with roughly 250 signs distributed around the map, this keeps the normal
case small because each player only processes signs close enough to their current location.

### Recommended starting values

```lua
Config.DefaultViewDistance = 80.0
Config.MaxActiveDuis = 12
Config.SpatialUpdateMs = 250
Config.ProjectionUpdateMs = 100
Config.DuiUnloadGraceMs = 15000
```

If your server has dense areas with many signs, `MaxActiveDuis` is the main client-side safety cap.

## Image URLs

Use direct image URLs, preferably HTTPS:

- `https://example.com/my-sign.png`

The server stores the URL in MySQL; it does not download or proxy the image. This keeps server
bandwidth and storage use low.

The remote host must allow the image to be loaded by FiveM's embedded browser. An image URL that
requires authentication, cookies, or a short-lived session may not work.

## Installation

1. Put `qbox_signs` in your resources folder.
2. Import `sql/qbox_signs.sql`.
3. Ensure dependencies before this resource:

```cfg
ensure oxmysql
ensure ox_lib
ensure qbx_core
ensure qbox_signs
```

4. Edit `config.lua`.
5. Restart the resource/server.
6. An authorised staff member can use `/sign`.

## Permissions

Edit:

```lua
Config.AdminGroups = {
    'admin',
    'god'
}
```

The resource checks the Qbox group server-side both when opening the menu and when creating,
editing or deleting signs.

## Ownership

By default:

```lua
Config.OwnershipOnly = true
```

An admin can manage signs they created. If you want authorised admins to manage every sign:

```lua
Config.OwnershipOnly = false
```

## Persistence

Signs survive server restarts because their position, size, image URL, owner and view distance
are stored in `qbox_signs`.

The actual image file is not stored in SQL. Only the URL is stored, which is considerably cheaper
for a server than downloading and serving up to 250 external images itself.

## Notes

The current placement workflow is designed around a horizontal/vertical world rectangle and uses
the selected world X/Z dimensions. The image renderer is intentionally client-side so the server
does not need to stream image bytes to 100 players.

If you later want arbitrary wall angles/orientation, the placement model can be extended to store
a plane normal/rotation without changing the database persistence concept.
