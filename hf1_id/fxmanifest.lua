fx_version 'cerulean'
game 'gta5'

name 'HF1 Player IDS'
description 'Shows player ID above head on keypress'
author 'HardyF1'
version '1.0.0'

fx_version 'cerulean'
game 'gta5'

lua54 'yes'

shared_script '@ox_lib/init.lua'

client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'ox_lib',
    'qbx_core'
}