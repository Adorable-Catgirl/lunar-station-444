EXT.id = "atmospherics"
EXT.name = "Atmospherics"
EXT.require = {"reagents"}
EXT.license = "MPL 2.0"
EXT.author = "Adorable-Catgirl"
EXT.config = {
	should_tile_compress={"boolean", true}
}

function EXT.load(reload)
	-- Here's where we cry.
	dofile("atmos/init.lua")
end