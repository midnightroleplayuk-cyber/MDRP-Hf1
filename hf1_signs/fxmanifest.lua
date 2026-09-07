fx_version 'cerulean'
game 'gta5'

author 'HF1'
description 'Qbox flat 2D surface signs'
version '1.2.5'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

-- Required so the direct-rendered DUI can actually load the local wrapper page.
files {
    'html/index.html'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core'
}
