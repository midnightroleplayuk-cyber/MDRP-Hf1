Config = {}

-- The GTA V coffee vending machine model.
Config.MachineModel = `prop_vend_coffe_01`

-- What ox_target displays.
Config.TargetLabel = 'Grab a Coffee.'
Config.TargetIcon = 'fa-solid fa-mug-hot'
Config.TargetDistance = 2.0

-- Inventory item to give the player.
Config.CoffeeItem = 'coffee'
Config.CoffeeLabel = 'Coffee'

-- Set to 0 for free coffee. Change to e.g. 5 if you want it to cost money.
Config.Price = 100
Config.MoneyType = 'cash' -- cash, bank, or crypto

-- Anti-spam / reservation settings.
Config.Cooldown = 10 -- seconds between successful coffees per player
Config.ReservationTimeout = 15 -- seconds before an unfinished reservation expires

-- Machine sequence.
Config.FaceMachineTime = 650
Config.ButtonAnimation = {
    dict = 'mini@sprunk',
    clip = 'plyr_buy_drink_pt1',
    duration = 1700,
    flag = 0
}
Config.GrabAnimation = {
    dict = 'mini@sprunk',
    clip = 'plyr_buy_drink_pt3',
    duration = 1800,
    flag = 0
}

-- Where the disposable cup appears relative to the vending machine.
-- If it is slightly off on your server/map, these are the only values you need to tune.
Config.Cup = {
    model = `p_amb_coffeecup_01`,
    offset = vec3(0.0, -0.46, -0.72),
    rotation = vec3(0.0, 0.0, 0.0),
    popDistance = 0.16,
    popHeight = 0.05,
    popTime = 650
}

-- Custom NUI audio is included with this resource.
Config.Sound = {
    enabled = true,
    file = 'coffee_machine.wav',
    volume = 0.45
}

-- Drinking settings.
Config.Drink = {
    duration = 3500,
    label = 'Drinking coffee...',
    anim = {
        dict = 'amb@world_human_drinking@coffee@male@idle_a',
        clip = 'idle_c',
        flag = 49
    },
    -- This prop is attached by ox_lib while the item is consumed.
    prop = {
        model = `p_amb_coffeecup_01`,
        bone = 28422,
        pos = vec3(0.0, 0.0, 0.0),
        rot = vec3(0.0, 0.0, 0.0)
    }
}

-- If your server has a custom coffee-drinking animation, change the above dict/clip.
-- The vending-machine purchase animation uses Rockstar's mini@sprunk vending sequence.
