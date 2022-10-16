fx_version 'cerulean'
game 'gta5'

description 'qb-fuel'
version '2.0'
author 'github.com/Project-Sloth and github.com/krrm1'

client_scripts {
    '@PolyZone/client.lua',
	'client/client.lua',
	'client/utils.lua'
}

server_scripts {
	'server/server.lua'
}

shared_scripts {
	'@qb-core/shared/locale.lua',
	'locales/en.lua',
	-- 'locales/de.lua',
	'shared/config.lua',
}

exports {
	'GetFuel',
	'SetFuel'
}

lua54 'yes'
