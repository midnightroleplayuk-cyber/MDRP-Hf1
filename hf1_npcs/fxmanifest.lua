fx_version 'cerulean'
game 'gta5'

author 'OpenAI / ChatGPT'
description 'Persistent NPC creator and manager for Qbox using ox_lib and oxmysql'
version '1.3.0-dialogue-sounds'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/peds.lua',
    'shared/animations.lua'
}

client_scripts {
    'client/bridges/osp_ambulance.lua',
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
