fx_version 'cerulean'
game 'gta5'

name 'tm-persistent_props'
description 'Persistent player-placeable prop system (DB backed)'
author 'themannster'
version '1.0.0'

dependencies {
    'ox_lib',
    'oxmysql',
    'qbx_core',
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/logger.lua',
    'shared/catalogue.lua',
}

client_scripts {
    'client/render.lua',
    'client/placement.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/main.lua',
}

files {
    'sql/install.sql',
}
