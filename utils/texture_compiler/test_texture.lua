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
print("States:")

for k, v in pairs(idat.frames) do
	print("\tState: "..k)
	print("\tFrames:")
	for i=1, #v do
		local frame = v[i]
		print(string.format("\t\tx: %d y: %d w: %d h: %d dt: %.3fs", frame.x, frame.y, frame.w, frame.h, frame.dt))
	end
	print("")
end