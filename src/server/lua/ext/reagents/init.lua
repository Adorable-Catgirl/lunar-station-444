EXT.id = "reagents"
EXT.requires = {}
EXT.license = "MPL 2.0"
EXT.author = "Adorable-Catgirl"
EXT.hotload = true
EXT.unloadable = false
EXT.name = "Reagents"

function EXT.load(reload, hot)
	if reload and hot then
		ls444.warning("Hot reloading reagents...")
	end
	dofile("scripts/reagents/init.lua")
end