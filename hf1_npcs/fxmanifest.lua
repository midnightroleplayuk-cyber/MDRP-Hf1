fx_version 'cerulean'
game 'gta5'

author 'HF1'
description 'NPC Creator & Interaction Script for QBOX framework.'
version '1.4.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/peds.lua',
    'shared/animations.lua'
}

client_scripts {
    'client/main.lua',
    'client/placement.lua',
    'client/menu.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/permissions.lua',
    'server/database.lua',
    'server/main.lua'
}

dependencies {
    'hf1_npc_sounds',
    'qbx_core',
    'ox_lib',
    'oxmysql'
}
