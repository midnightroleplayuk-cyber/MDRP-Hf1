# hf1_npcs

Persistent in-game NPC creator / placer for Qbox.

## Features

- `/createnpc` command
- INSERT keybind by default (rebindable in FiveM key settings)
- ACE permission support
- Optional license / identifier whitelist
- ox_lib menus, dialogs, alerts, notifications and keybind
- Searchable curated ped catalog + direct entry of any valid GTA/FiveM ped model
- Physical placement mode with movement, vertical adjustment and rotation
- SQL persistence with oxmysql
- Server-created OneSync peds
- Create, edit, move, duplicate, teleport to and delete NPCs
- Scenario presets
- Animation presets + custom anim dict/name/flag
- Invincible, frozen, block events ("stoic"), ragdoll and collision toggles
- Optional ox_target integration
- Automatic restoration after resource/server restart

## Dependencies

Required:
- qbx_core
- ox_lib
- oxmysql

Optional:
- ox_target (only required if you enable target interactions on an NPC)

## Installation

1. Put `hf1_npcs` in your resources folder.
2. Import `sql/install.sql` into your database.
3. Ensure dependencies start first:

```cfg
ensure oxmysql
ensure ox_lib
ensure qbx_core
ensure ox_target
ensure hf1_npcs
```

`ox_target` can be omitted if you do not use it.

4. Grant your Qbox admin ACE access:

```cfg
add_ace group.admin hf1_npcs.admin allow
```

If your server uses another admin principal, grant that principal instead.

You can also whitelist identifiers in `config.lua`:

```lua
Config.AllowedIdentifiers = {
    ['license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'] = true,
}
```

Either ACE permission OR a listed identifier grants access.

## Usage

- `/createnpc`
- Press `INSERT` (default keybind)

### Placement controls

- W / S: forward / backward
- A / D: left / right
- Q / E: down / up
- Left / Right Arrow: rotate
- Shift: faster movement
- Ctrl: precision movement
- Enter: confirm
- Backspace: cancel

## NPC creation flow

1. Open NPC Manager.
2. Create NPC.
3. Give it a friendly name.
4. Enter an exact model or use the catalog search.
5. Position the transparent preview.
6. Configure scenario / animation and behaviour.
7. Save.
8. Server writes it to SQL and creates the persistent networked ped.

## ox_target integration

If `ox_target` is running, each NPC can optionally expose one target option.

Set:
- target enabled
- label
- icon
- client event

Example target event:

```lua
RegisterNetEvent('myresource:client:openShop', function(data)
    print('NPC ID:', data.npcId)
    print('Entity:', data.entity)
end)
```

The callback receives:

```lua
{
    npcId = 12,
    entity = 12345,
    npc = { ...full cached NPC data... }
}
```

## Notes

- The resource accepts any valid local GTA/FiveM ped model typed directly.
- The bundled catalog is intentionally a useful common-ped list rather than every model in GTA V.
- Server-side ped creation requires OneSync, which Qbox servers normally use.
- Animation/scenario application is performed client-side when the server-created ped enters scope.
- Do not expose the manager permission to ordinary players; CRUD callbacks are also permission checked server-side.
- If you rename the SQL table, update the statements in `server/database.lua`.

## Troubleshooting

### "You do not have permission"
Make sure this exists in server.cfg and that your admin system places you in `group.admin`:

```cfg
add_ace group.admin hf1_npcs.admin allow
```

Or add your license identifier to `Config.AllowedIdentifiers`.

### Ped saves but does not appear
Check:
- OneSync is enabled.
- The ped model is valid.
- `hf1_npcs` starts after `oxmysql`, `ox_lib`, and `qbx_core`.
- Server console for a `Failed to create ped` message.

### Animation does not play
Scenarios override animations. Set Scenario to None if using a custom animation.

### ox_target does not show
Make sure `ox_target` is started before `hf1_npcs` and the NPC has target enabled with a non-empty event name.


## Talk to NPC conditions

Dialogue replies can optionally require:
- a Qbox job/group and minimum grade
- an ox_inventory item count
- the absence of an ox_inventory item
- a minimum cash balance
- a minimum bank balance

Failed requirements can either be hidden or shown as locked replies. These checks are performed server-side when the dialogue is opened.

The dialogue context also inserts a short close/open delay between ox_lib context transitions to reduce NUI `ResizeObserver loop limit exceeded` warnings during NPC conversations.
