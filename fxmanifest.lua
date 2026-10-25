fx_version 'cerulean'
lua54 'yes'
game 'gta5'

name         'pickle_consumables'
version      '1.0.4'
description  'A free alternative for consumable items.'
author       'Pickle Mods'

ui_page "nui/index.html"

files {
    "nui/index.html",
    "nui/assets/**/*.*",
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'core/shared.lua',
    "locales/*.lua",
    'modules/**/shared.lua',
    'bridge/**/shared.lua',
}

server_scripts {
    'bridge/**/server.lua',
    'modules/**/server.lua',
}

client_scripts {
    'core/client.lua',
    'bridge/**/client.lua',
    'modules/**/client.lua',
}
