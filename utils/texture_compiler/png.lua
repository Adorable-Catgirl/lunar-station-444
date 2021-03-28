-- pain
local zlib = require("zlib")
local bit = bit or require("bit")
local ffi = require("ffi")
local bor, band, lshift, rshift = bit.bor, bit.band, bit.lshift, bit.rshift
local png = {}
local decoders = {}

local inflate = zlib.inflate

local magic = string.char(137,80,78,71,13,10,26,10)

local function int(str)
	local n = 0
	for i=1, #str do
		n = lshift(n, 8)
		n = bor(n, str:byte(i))
	end
	return n
end

local function b5_set(...)
	local cs = {...}
	local r = {}
	for i=1, #cs do
		r[i] = (band(cs[i], 32) > 0)
	end
	return unpack(r)
end

function png:decode_raw(file)
	local mgk = file:read(#magic)
	if mgk ~= magic then error("not a png file") end
	local chunks = {}
	while true do
		jit.off()
		local length = int(file:read(4))
		local ctype = file:read(4)
		local data = file:read(length)
		local crc_raw = int(file:read(4))
		local crc = crc_raw % (0xFFFFFFFF+1) -- don't even ask
		local fuck = 0
		local c_crc = zlib.crc32()(ctype..data)
		jit.on()
		if (crc ~= c_crc) then
			error(string.format("crc mismatch on chunk %s (%.8x ~= %.8x)", ctype, crc, c_crc))
		end
		local ancillery, private, reserved, safe_to_copy = b5_set(ctype:byte(1, 4))
		if reserved then
			error("reserved bit set in "..ctype)
		end
		if ctype == "IEND" then return chunks end
		chunks[#chunks+1] = {
			type = ctype,
			crc = crc,
			length = length,
			data = data,
			ancillery = ancillery,
			private = private,
			safe_to_copy = safe_to_copy
		}
	end
end

function png:add_decoder(ctype, func)
	self.decoders[ctype] = func
end

local function paeth_predictor(a, b, c)
	local p = a + b - c
	local pa = math.abs(p - a)
	local pb = math.abs(p - b)
	local pc = math.abs(p - c)
	if (pa <= pb and pa <= pc) then
		return a
	elseif (pb <= pc) then
		return b
	else
		return c
	end
end

function png:apply_filter_ffi(state)
	local oimage = ffi.new("uint8_t[?]", #state.idat, state)
	ffi.copy(oimage, state.idat)
	local recon = ffi.new("uint8_t[?]", state.h*state.w*4)
	local bpp = 4
	local stride = state.w * 4
	local function f_x(r, c)
		return oimage[r * (stride+1) + c + 1]
	end
	local function r_a(r, c)
		if c < bpp then return 0 end
		return recon[r * stride + c - bpp]
	end
	local function r_b(r, c)
		if r <= 0 then return 0 end
		return recon[(r-1) * stride + c]
	end
	local function r_c(r, c)
		if r <= 0 or c < bpp then return 0 end
		return recon[(r-1) * stride + c - bpp]
	end
	local filters = {
		[0] = function(x, r, c)
			return x
		end,
		function(x, r, c)
			return x + r_a(r, c)
		end,
		function(x, r, c)
			return x + r_b(r, c)
		end,
		function(x, r, c)
			return x + math.floor(r_a(r, c)/r_b(r, c))
		end,
		function(x, r, c)
			return x + paeth_predictor(r_a(r, c), r_b(r, c), r_c(r, c))
		end
	}
	local i = 0
	local rpos = 0
	for r=0, state.h-1 do
		local filter = oimage[i]
		--print(filter)
		i = i + 1
		for c=0, stride-1 do
			io.stdout:write(string.format("%.8x/%.8x (%d%%)\r", i, state.h*state.w*4, (i/(state.h*state.w*4))*100))
			local x = oimage[i]
			i = i + 1
			recon[rpos] = assert(filters[filter], "unknown filter "..filter.. " at "..i.."/"..r)(x, r, c)
			rpos = rpos+1
		end
	end
	state.idat = ffi.string(recon, state.h*state.w*4)
end

function png:apply_filter(state)
	local recon = {}
	local current_scanline = ""
	local function r_a(r, c)
		if c-4 < 0 then
			return 0
		end
		return current_scanline:byte(c-1)
	end
	local function r_b(r, c)
		if not recon[r-1] then return 0 end
		return recon[r-1]:byte(c)
	end
	local function r_c(r, c)
		if not recon[r-1] or c-4 < 0 then return 0 end
		return recon[r-1]:byte(c-4)
	end
	local sl_length = 1+(state.w*4)
	for i=1, state.h do
		local scanline = state.idat:sub((i-1)*sl_length+1, i*sl_length)
		local filter = scanline:byte(1)
		scanline = scanline:sub(2)
		for j=1, #scanline do
			if filter == 0 then
				current_scanline = current_scanline .. scanline:sub(j,j)
			elseif filter == 1 then
				current_scanline = current_scanline .. string.char(bit.band(scanline:byte(j) + r_a(i, j), 0xFF))
			elseif filter == 2 then
				current_scanline = current_scanline .. string.char(bit.band(scanline:byte(j) + r_b(i, j), 0xFF))
			elseif filter == 3 then
				current_scanline = current_scanline .. string.char(bit.band(scanline:byte(j) + math.floor((r_a(i, j) + r_b(i, j))/2), 0xFF))
			elseif filter == 4 then
				current_scanline = current_scanline .. string.char(bit.band(scanline:byte(j) + paeth_predictor(r_a(i, j), r_b(i, j), r_c(i, j)), 0xFF))
			end
			print(filter)
		end
		recon[#recon+1] = current_scanline
		current_scanline = ""
	end
	state.idat = table.concat(recon, "")
end

function png:decode(file)
	local chunks = self:decode_raw(file)
	local state = {}
	for i=1, #chunks do
		local chunk = chunks[i]
		if (self.decoders[chunk.type]) then
			self.decoders[chunk.type](chunk, state)
		elseif not chunk.ancillery then
			error("cannot decode critical chunk "..chunk.type)
		end
	end
	state.idat = inflate()(state.idat)
	self:apply_filter_ffi(state)
	return state, chunks
end

function decoders.IHDR(chunk, state)
	local dat = chunk.data
	local width = int(dat:sub(1, 4))
	local height = int(dat:sub(5, 8))
	local depth, color, compression, filter, interlace = dat:byte(9, 13)
	state.w = width
	state.h = height
	if (depth ~= 8 or color ~= 6 or compression ~= 0 or filter ~= 0 or interlace ~= 0) then
		error(string.format("bad image settings (expecting 8-6-0-0-0, got %i-%i-%i-%i-%i)", depth, color, compression, filter, interlace))
	end
end

function decoders.IDAT(chunk, state)
	if chunk.size == 0 then return end
	state.idat = (state.idat or "") .. chunk.data
end

return function()
	local t = {}
	for k, v in pairs(decoders) do
		t[k] = v
	end
	return setmetatable({decoders=t}, {__index=png})
end