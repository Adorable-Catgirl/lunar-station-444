-- for love2d

local blt = require("blt")
local zstd = require("zstd")

local img
local rimg

local w, h = 0, 0

local function load_lsrsc(path)
	print(path)
	local h = io.open(path, "rb")
	local mgk = h:read(8)
	if (mgk ~= "ls444rsc") then error("bad magic "..mgk) end
	local z = zstd:new()
	local data = assert(z:decompress(h:read("*a")))
	--io.stderr:write(data)
	print("decompressed")
	z:free()
	local idat = blt.deserialize(data)
	print("deserialized")
	print(idat.width*idat.height*4, #idat.data)
	return (love.image.newImageData(idat.width, idat.height, "rgba8", idat.data:sub(1, idat.width*idat.height*4))), idat
end

local function create_quad(name, frame)
	local fdat = assert(rimg.frames[name], "state named "..name.." not found")[frame]
	print(string.format("%d %d %d %d", fdat.x, fdat.y, fdat.w, fdat.h))
	return love.graphics.newQuad(fdat.x, fdat.y, fdat.w, fdat.h, img)
end

local q1, q2

function love.load(_, args)
	local id
	id, rimg = load_lsrsc(args[2])
	img = love.graphics.newImage(id)
	q1 = create_quad("electrocuted_base_east", 1)
	q2 = create_quad("electrocuted_base_east", 2)
end

function love.draw()
	love.graphics.draw(img, q1, 0, 0)
	love.graphics.draw(img, q2, 50, 20)
end