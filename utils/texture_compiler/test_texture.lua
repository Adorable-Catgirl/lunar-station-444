local blt = require("blt")
local zstd = require("zstd")

local h = io.open(arg[1], "rb")
if (h:read(8) ~= "ls444rsc") then error("bad magic") end
local z = zstd:new()
local data = assert(z:decompress(h:read("*a")))
--io.stderr:write(data)
z:free()
local idat = blt.deserialize(data)
print("ls_spritesheet viewer")
print(string.format("Size: %dx%d (%s)", idat.width, idat.height, idat.color))
if idat.source then
	print("Source: "..idat.source)
end
if idat.version then
	print("Format version: "..idat.version)
end
print("Sprites:")

for k, v in pairs(idat.frames) do
	print("\tSprite: "..k)
	print("\tStates:")
	for j, c in pairs(v.states) do
		print("\t\tState: "..j)
		print("\t\tFrames:")
		for i=1, #c do
			local frame = c[i]
			print(string.format("\t\t\tx: %d y: %d w: %d h: %d dt: %.3fs", frame.x, frame.y, frame.w, frame.h, frame.dt))
		end
	end
	print("")
end