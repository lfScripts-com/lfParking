fx_version 'cerulean'
game 'gta5'
author 'lfScripts, xLaugh, Firgyy'
lua54 'yes'
version '0.0.1'

shared_scripts {
    '@es_extended/imports.lua',
    'config.lua'
}

client_scripts {
    '@es_extended/locale.lua',
    'RageUI/RMenu.lua',
    'RageUI/menu/RageUI.lua',
    'RageUI/menu/Menu.lua',
    'RageUI/menu/MenuController.lua',
    'RageUI/components/*.lua',
    'RageUI/menu/elements/*.lua',
    'RageUI/menu/items/*.lua',
    'RageUI/menu/panels/*.lua',
    'RageUI/menu/windows/*.lua',
    'client.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}