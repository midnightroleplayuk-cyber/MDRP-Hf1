fx_version 'cerulean'
game 'gta5'

name 'hf1_props'
author 'HF1'
description 'Persistent, streamed prop placement and management for Qbox/FiveM'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/placement.lua',
    'client/main.lua',
    'client/menu.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/permissions.lua',
    'server/catalogue.lua',
    'server/database.lua',
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'oxmysql'
}
