fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'

client_script '@mythic-base/components/cl_error.lua'
client_script '@mythic-pwnzor/client/check.lua'

client_scripts {
    'config.lua',
    'client/**/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
	'config.lua',
    'server/**/*.lua',
}

ui_page 'ui/dist/index.html'

files {
    'ui/dist/index.html',
    'ui/dist/*.png',
    'ui/dist/*.js',
}