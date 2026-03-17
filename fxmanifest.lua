fx_version 'cerulean'
game 'gta5'

name 'crash_tackle'
description 'ESX tackle script - Shift+E while sprinting to tackle (ragdoll)'
author 'crash_tackle'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua',
}

client_scripts {
    'client.lua',
}

server_scripts {
    'server.lua',
}

dependencies {
    'es_extended',
}
