--[[local ffi = require("ffi")
local bor = bit.bor
local band = bit.band
local lshift = bit.lshift
local rshift = bit.rshift

ffi.cdef [[
	struct blt2_table_header {
		uint32_t id;
		uint32_t array_len;
		uint8_t flags;
	};

	struct blt2_serialize_header {
		char magic[4];
		uint32_t entries;
	};
]]

local table_flags = {

}

local tag_flags = {
	internal = 1,
	sign = 2,
}

local tag_types = {
	null = 0,
	float = 1,
	int = 2,
	string = 3,
	bool = 4,
	table_ref = 5
}

-- table stuff

local function flatten(tbl)
	local tables_in = {{tbl=tbl, i=1}}
	local tables_out = {{id=0, tbl={}}}
	local tables_written = {[tbl]=0}
	local function get_tbl(tbl)
		if not tables_written[tbl] then
			tables_written[tbl] = #tables_out
			tables_out[#tables_out+1] = {id=#tables_out, tbl={}}
			tables_in[#tables_in+1] = {tbl=tbl,i=#tables_out}
		end
		return {ref=tables_written[tbl]}
	end
	while #tables_in > 0 do
		local tbl_i = tables_in[1].tbl
		local tbl_o = tables_out[tables_in[1].i].tbl
		for k, v in pairs(tbl_i) do
			local nk = k
			if (type(k) == "table") then
				nk = get_tbl(k)
			end
			local nv = v
			if (type(v) == "table") then
				nv = get_tbl(v)
			end
			tbl_o[nk] = nv
		end
		table.remove(tables_in, 1)
	end
	return tables_out
end

local function expand(tbl) -- owo wuts this
	local tables_ref = {}
	for i=1, #tbl do
		local t = tbl[i]
		tables_ref[t.id] = t.tbl
	end
	for i=1, #tbl do
		local t = tbl[i].tbl
		local dk = {}
		for k, v in pairs(t) do
			local nk = k
			if (type(k) == "table") then
				nk = tables_ref[k.ref]
				dk[#dk+1] = k
			end
			local nv = v
			if (type(v) == "table") then
				nv = tables_ref[v.ref]
			end
			t[nk] = nv
		end
		for i=1, #dk do
			table.remove(t, dk)
		end
	end
	for i=1, #tbl do
		if (tbl[i].id == 0) then
			return tbl[i].tbl
		end
	end
	error("failed to find root")
end

-- serialization

local function get_int_size(int)
	--print(int)
	for i=1, 8 do
		--[[max = max | (0xFF << (8*(i-1)))
		if (max >= int) then
			return i
		end]]
		--print(i)
		if (pcall(string.pack, "<I"..i, int)) then
			return i
		end
	end
	return 8
end

local function get_int_size_s(int)
	for i=1, 8 do
		--[[max = max | (0xFF << (8*(i-1)))
		if (max >= int) then
			return i
		end]]
		--print(i)
		if (pcall(string.pack, "<i"..i, int)) then
			return i
		end
	end
	return 8
end

local function get_int(size, int)
	local str = ""
	--print(size)
	return string.pack("<I"..size, int)
	--[[for i=1, size do
		str = str .. string.char(int & 0xFF)
		int = (int >> 8)
	end]]
--	return str
end

local function get_int_s(size, int)
	local str = ""
	str = string.pack("<i"..size, int)
	return str
end

local function write_tag(type, flags, data)
	local dsize = #data
	if (dsize <= 15) then
		return string.char(type, (((flags | tag_flags.internal) << 4) | dsize))..data
	end
	local isize = get_int_size(dsize)
	return string.char(type, ((flags << 4) | isize))..get_int(isize, dsize)..data
end

local function write_nil()
	return write_tag(tag_types.null, 0, "")
end

local function write_int(i)
	if (i < 0) then
		local dsize = get_int_size_s((i))
		return write_tag(tag_types.int, tag_flags.sign, get_int_s(dsize, i))
	end
	--print(i)
	local dsize = get_int_size(i)
	return write_tag(tag_types.int, 0, get_int(dsize, i))
end

local function write_double(d)
	--return write_tag(tag_types.float, 0, ffi.string(ffi.new("double[1]", {d}), 8))
	return write_tag(tag_types.float, 0, string.pack("<d", d))
end

local function write_string(s)
	return write_tag(tag_types.string, 0, s)
end

local function write_bool(b)
	return write_tag(tag_types.bool, 0, string.char(b and 1 or 0))
end

local function write_table_ref(r)
	local dsize = get_int_size(r.ref)
	return write_tag(tag_types.table_ref, 0, get_int(dsize, r.ref))
end

local function write_value(v)
	if (type(v) == "string") then
		return write_string(v)
	elseif (type(v) == "number") then
		if (math.floor(v) ~= v or v == math.huge or v == -math.huge or v ~= v) then
			return write_double(v)
		else
			return write_int(v)
		end
	elseif (type(v) == "boolean") then
		return write_bool(v)
	elseif (type(v) == "table") then
		return write_table_ref(v)
	elseif (type(v) == "nil") then
		return write_nil()
	end
	return write_string(tostring(v))
end

local function write_flattened_table(tbl)
	local t = tbl.tbl
	local data = ""
	local entries = #t
	for i=1, entries do
		data = data .. write_value(t[i])
	end
	for k, v in pairs(t) do
		--print(k, v)
		if (type(k) == "number" and k <= entries) then
			goto continue
		end
		data = data .. write_value(k) .. write_value(v)
		::continue::
	end
	data = data .. write_nil() .. write_nil()
	--[[local header = ffi.new("struct blt2_table_header")
	header.id = tbl.id
	header.flags = 0
	header.array_len = entries
	return ffi.string(header, 9)..data]]
	return string.pack("<IIB", tbl.id, entries, 0)..data
end

local function serialize_table(tbl)
	local flattened = flatten(tbl)
	--[[local header = ffi.new("struct blt2_serialize_header")
	header.entries = #flattened
	header.magic = "blt2"
	local data = ffi.string(header, 8)]]
	local data = string.pack("<c4I", "blt2", #flattened)
	for i=1, #flattened do
		data = data .. write_flattened_table(flattened[i])
	end
	return data
end

-- deserialization

local function read_int(s)
	local int = 0
	if #s > 0 then
		int = string.unpack("<I"..#s, s)
	end
	return int
end

local function read_int_s(s)
	local int = 0
	if #s > 0 then
		int = string.unpack("<i"..#s, s)
	end
	return int
end

local function decode_string(s)
	return s
end

local function decode_double(d)
	return string.unpack("<d", d)--ffi.cast("double *", ffi.new("char[8]", d))[0]
end

local function decode_bool(b)
	return b ~= "\0"
end

local function decode_int(b, flags)
	if (flags & tag_flags.sign > 0) then
		return read_int_s(b)
	end
	return read_int(b)
	--return read_int(b)*(((flags & tag_flags.sign) > 0) and -1 or 1)
end

local function decode_ref(r)
	return {ref=read_int(r)}
end

local dser = {
	[0] = function()return nil end,
	decode_double,
	decode_int,
	decode_string,
	decode_bool,
	decode_ref
}

local function read_tag(state)
	local header = state:read(2)
	local ttype, flags_size = header:byte(1, 2)
	local size = (flags_size & 0xF)
	local flags = (flags_size >> 4)
	local dsize
	if ((flags & tag_flags.internal) > 0) then
		dsize = size
	else
		dsize = read_int(state:read(size))
	end
	local data = state:read(dsize)
	return (dser[ttype] or decode_string)(data, flags)
end

local function read_tbl_header(state)
	local id, len, flags = string.unpack("<IIB", state:read(9))
	return {id=id,array_len=len,flags=flags}
end

local function read_flattened_table(state)
	local header = read_tbl_header(state) --ffi.cast("struct blt2_table_header *", ffi.new("char[9]", state:read(9)))[0]
	local t = {}
	for i=1, header.array_len do
		t[i] = read_tag(state)
	end
	while true do
		local k, v = read_tag(state), read_tag(state)
		if (k == nil and v == nil) then
			return {id=header.id, tbl=t}
		end
		t[k] = v
	end
end

local function read_serialize_header(state)
	local magic, entries = string.unpack("<c4I", state:read(8))
	return {magic=magic,entries=entries}
end

local function deserialize_table(data)
	local state = {
		data = data,
		pos = 1
	}
	function state:read(amt)
		local s = self.data:sub(self.pos, self.pos+amt-1)
		self.pos = self.pos+amt
		return s
	end
	local header = read_serialize_header(state) --ffi.cast("struct blt2_serialize_header *", ffi.new("char[8]", state:read(8)))[0]
	local parts = {}
	for i=1, header.entries do
		parts[i] = read_flattened_table(state)
	end
	return expand(parts)
end

return {serialize=serialize_table, deserialize=deserialize_table}