local zlib = require("zlib")
local png = require("png")()
local blt = require("blt")
local zstd = require("zstd")

local keyword = "Description"

-- pain
local function parse_value(v)
	if v:sub(1,1) == "\"" then -- i highly doubt we'll see multiple values per line
		return v:sub(2, #v-1)
	elseif (v == "true") then
		return true
	elseif (v == "false") then
		return false
	else
		return tonumber(v)
	end
end

png:add_decoder("zTXt", function(chunk, istate)
	local dat = chunk.data
	local start, dstart = dat:find(keyword)
	if not start then return end
	if (dat:byte(dstart+1) ~= 0) then
		error("unknown compression method")
	end
	local rdat = dat:sub(dstart+3)
	local decode_dat = zlib.inflate()(rdat)
	--io.stderr:write(decode_dat)
	local current_entry = {}
	local state = {}
	for line in decode_dat:gmatch("[^\r\n]+") do
		if (line:sub(1,1) == "#") then goto continue end
		local lfilter, tab_level = line:gsub("\t", "")
		local k, v = lfilter:match("(.+) = (.+)")
		v = parse_value(v)
		if (tab_level == 0) then -- start of a new entry
			if (k == "version") then
				if (v ~= 4) then
					error("bad version "..v)
				end
			end
			current_entry = {}
			state[#state+1] = {key=k, value=v, subkeys=current_entry}
		else
			current_entry[k] = v
		end
		::continue::
	end
	istate.dmi_dat = state
end)

local f = io.open(arg[1], "rb")
local state, chunks = png:decode(f)
f:close()

local function sprite_xy(w, h, offset)
	local s_w = state.w/w
	local s_h = state.h/h
	local s_x = offset % s_w
	local s_y = math.floor(offset/s_h)
	return s_x*w, s_y*h
end

local directions = {"south", "north", "east", "west"} -- what
local spritemap = {}
local dmi_dat = state.dmi_dat
local w, h = 0, 0
local offset = 0
for i=1, #dmi_dat do
	local ent = dmi_dat[i]
	if (ent.key == "version") then
		w = ent.subkeys.width
		h = ent.subkeys.height
	elseif (ent.key == "state") then
		local sk = ent.subkeys
		local frames = {{}, {}, {}, {}}
		for frame=1, sk.frames do
			for dir=1, sk.dirs do
				local x, y = sprite_xy(w, h, dir+frame+offset-2)
				frames[dir][#frames[dir]+1] = {x=x,y=y,w=w,h=h, dt=1/20}
			end
		end
		for dir=1, sk.dirs do
			spritemap[ent.value.."_"..directions[dir]] = frames[dir]
		end
	end
end

--[[for i=1, #dmi_dat do
	print(dmi_dat[i].key, dmi_dat[i].value)
	for k, v in pairs(dmi_dat[i].subkeys) do
		print("", k, v)
	end
end]]

--[[ process idat
local function get_px(x, y)

end
local raw_idat = ""
for i=0, state.h-1 do
	local sl_size = (state.w*4)+1
	local scanline = state.idat:sub((i*sl_size)+1, ((i+1)*sl_size))
	--print((i*sl_size)+1, ((i+1)*sl_size))
	local sl_dat = scanline:sub(2)
	if scanline:byte(1) ~= 0 then error("fuck "..scanline:byte(1)) end
	print(#sl_dat)
	raw_idat = raw_idat .. sl_dat
end]]

print(#state.idat, state.w*state.h*4)

local image = {
	source=arg[1],
	type="spritesheet",
	frames = spritemap,
	width = state.w,
	height = state.h,
	color = "rgba8888",
	data = state.idat
}

--require("pl.pretty").dump(image)

do
	local z = zstd:new()
	local f = io.open(arg[2], "wb")
	local start = os.clock()
	local rdat = blt.serialize(image)
	print(string.format("Serialized in %.3fs", os.clock()-start))
	start=os.clock()
	local dat = assert(z:compress(rdat, 22))
	print(string.format("Compressed in %.3fs", os.clock()-start))
	print(string.format("Compressed %d -> %d (%d%%)", #rdat, #dat, math.ceil((#dat/#rdat)*100)))
	f:write("ls444rsc"..dat)
	f:close()
end