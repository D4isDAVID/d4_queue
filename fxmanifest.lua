fx_version 'cerulean'
game 'common'

version '0.1.0-dev'
description 'Connection queue for FXServer.'
author 'David Malchin <malchin459@gmail.com>'
repository 'https://github.com/D4isDAVID/d4_queue'

server_only 'yes'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

server_scripts {
    'server/init.lua',
    'server/convars.lua',
    'server/utils/*.lua',
    'server/api/*.lua',
    'server/hardcap.lua',
    'server/connecting.lua',
}
