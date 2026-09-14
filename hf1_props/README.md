# hf1_props

Persistent, performance-minded prop placement and management for FiveM/Qbox servers.

## Features

- `/propadmin` ox_lib menu with **New Prop**, **Manage Props**, and **Reload Props**.
- Persistent MySQL storage via oxmysql. The table is created automatically on first start.
- Props are definitions in the database, not permanent network entities.
- Every client locally streams only nearby props. Distant props are deleted locally and respawn when needed.
- Server-side searchable GTA object catalogue. Clients receive only the matching results, never the whole 20k+ model list.
- Search all props: type `vend`, `bench`, `laptop`, etc.
- Keyword-based categories which continue to work as new GTA models are added.
- Custom / streamed prop model support.
- Precision placement with position + pitch/yaw/roll adjustment.
- Manage saved props: reposition, rename, change model, freeze/unfreeze, collision, teleport, delete.
- ACE permission support plus optional identifier whitelist.

## Dependencies

- ox_lib
- oxmysql

Qbox is fine, but there is no hard qbx_core dependency; permissions use ACE so the resource remains simple and portable.

## Install

1. Put `hf1_props` in your resources folder.
2. Ensure dependencies start before it:

```cfg
ensure ox_lib
ensure oxmysql
ensure hf1_props
```

3. Grant admins access in `server.cfg`:

```cfg
add_ace group.admin hf1_props.admin allow
```

The SQL table is created automatically. `sql/install.sql` is included if you prefer manual SQL installation.

## Prop catalogue

The bundled file is only a starter/fallback list so the resource still works if the web is unavailable.

On start, the **server** (not every client) downloads the maintained DurtyFree GTA V `ObjectList.ini`, parses it, and caches it to `data/objectlist.txt`. This currently provides 20,000+ GTA object names. Search is performed server-side and capped to `Config.Catalogue.MaxResults`, so opening the menu does not create an enormous ox_lib dropdown or push the whole catalogue to every client.

Set `Config.Catalogue.AutoUpdate = false` if you want to keep the last cached list and never perform the startup update.

Custom streamed objects do not need to exist in the catalogue. Choose **Custom / Streamed prop model** and enter the exact model name.

## Placement controls

- Aim with camera/mouse: preview follows the raycast until locked
- Left Mouse: lock initial position
- W/A/S/D: fine movement
- Q/E: down/up
- Left/Right arrows: yaw
- Up/Down arrows: pitch
- Z/X: roll
- G: place on ground properly
- Shift: faster movement/rotation
- Ctrl: precision movement/rotation
- Enter: save
- Backspace: cancel

For wall/ceiling props, do not press G; use the camera raycast and manual rotation/offset instead.

## Performance design

Normal gameplay has no per-frame loop. The only continuous loop runs while an admin is actively placing a prop. During normal play, each client checks prop streaming every `Config.Streaming.refreshInterval` (default 1500 ms), using squared distance checks. Objects are local static entities, so OneSync does not have to own/synchronize thousands of network objects.

Model search is done only when an admin requests it and returns at most the configured result limit.

## Notes

Some entries in Rockstar's object catalogue are map/LOD/internal objects and may not be useful as ordinary placeable props. The client validates selected models before placement, and custom streamed props must be loaded by their own resource first.
