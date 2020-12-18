ls444.module("atmos")

local ffi = require("ffi") -- you know shit's cursed when i whip out FFI.
ffi.cdef [[
	struct atmos_gas {
		uint32_t type;
		double mols;	
	};
	struct atmos_tile {
		double pressure;
		char * type;
	};
]]

dofile("atmos/room.lua")