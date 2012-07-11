--[[

	Configuration for Falcon Scripting Plugin
	by Ozzypig
	
]]

config = {}

--Enable sounds
config.sounds = true

--Add --! to new scripts
config.tagprefix = true

--Add boilerplate code to new scirpts
config.boilerplate = true

--Add timestamp to new scripts
config.timestamp = true

--Enable commands in scripts
config.commands = true

--Enable automatic syntax error checking
config.syntax = true

--Enable GUI for syntax error checking
config.errorgui = true

while not _G.fsp do wait() end
_G.fsp.config = config
