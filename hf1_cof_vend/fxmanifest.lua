fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'qbox-coffee-machine'
author 'OpenAI'
description 'Immersive prop_vend_coffe_01 coffee machine for Qbox + ox_target + ox_inventory'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/app.js',
    'html/sounds/coffee_machine.wav'
}

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_target',
    'ox_inventory'
}
