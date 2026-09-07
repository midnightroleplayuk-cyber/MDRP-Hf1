# Qbox Coffee Machine

A small immersive FiveM resource for Qbox using ox_target, ox_inventory and ox_lib.

## Flow

- Target `prop_vend_coffe_01` with **Grab a Coffee.**
- Player turns to the machine and plays the Rockstar `mini@sprunk` vending animation.
- Included coffee-machine audio plays.
- A `p_amb_coffeecup_01` disposable cup visibly pops out.
- Player performs the vending-machine grab and the cup is attached briefly to their hand.
- Server adds one `coffee` item to ox_inventory.
- Using `coffee` plays a coffee-drinking animation with a cup prop and consumes the item.

## Install

Start dependencies before this resource:

```cfg
ensure qbx_core
ensure ox_lib
ensure ox_inventory
ensure ox_target
ensure qbox-coffee-machine
```

Qbox recommends ox_inventory after qbx_core.

Then add this item to `ox_inventory/data/items.lua` inside the main items table:

```lua
['coffee'] = {
    label = 'Coffee',
    weight = 250,
    stack = true,
    close = true,
    consume = 1,
    description = 'A disposable cup of freshly made coffee.',
    client = {
        export = 'qbox-coffee-machine.coffee'
    }
},
```

## Config

`Config.Price = 0` makes coffee free. For paid coffee, use for example:

```lua
Config.Price = 5
Config.MoneyType = 'cash'
```

The server checks/removes Qbox money before starting the machine sequence.

If the physical cup is not aligned with the machine's output slot, tune:

```lua
Config.Cup.offset = vec3(0.0, -0.46, -0.72)
```

The included `html/sounds/coffee_machine.wav` is a generated mechanical coffee-machine effect, so no external sound download is required.
