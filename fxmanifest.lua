fx_version "adamant"
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game "rdr3"

description 'Thrasherrr | qbr-construction | Converted by: Danglr'

client_scripts {
	'config.lua',
	'client.lua',
}

server_scripts {
	'server.lua',
	'config.lua'
}

dependency 'rsg-core' -- https://github.com/qbcore-redm-framework/qbr-core

lua54 'yes'