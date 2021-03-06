local blt = require("blt2")
local zstd = require("zstd")
local lfs = require("lfs")

local function compress(data)
	local z = zstd:new()
	local dat = assert(z:compress(data), 22)
	z:free()
	return dat
end

local function decompress(data)
	local z = zstd:new()
	local dat = assert(z:decompress(data))
	z:free()
	return dat
end

local files = {type="rsc_root"}
local function get_file_table(fp)
	local tbl = files
	for match in fp:gmatch("(.+)/") do
		tbl[match] = tbl[match] or {type="dir"}
		tbl = tbl[match]
	end
	return tbl, (fp:match("/(.+)$"))
end
local function scan_file(f)
	local h = io.open(f, "rb")
	local data = h:read(8)
	if (data ~= "ls444rsc") then
		h:close()
		return
	end
	print("Adding "..f)
	data = h:read("*a")
	local tbl = blt.deserialize(decompress(data))
	local t, k = get_file_table(f)
	t[k] = {
		type = "resource",
		data = tbl
	}
end
local function scan_dir(dir)
	for ent in lfs.dir(dir) do
		if (lfs.attributes(dir.."/"..ent, "mode") == "directory") then
			scan_dir(dir.."/"..ent)
		else
			scan_file(dir.."/"..ent)
		end
	end
end

scan_dir(arg[1])

local f = io.open(arg[2], "wb")
f:write("ls444rsc")
f:write((compress(blt.serialize(files))))
f:close()
print("Resource compilation complete")