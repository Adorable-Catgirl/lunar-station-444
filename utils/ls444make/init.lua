local lzma = require("lzma")
local blt = require("blt2")

function mkdir(dir)
	if (os.jit == "Windows") then
		os.execute(string.format("mkdir %q", dir))
	else
		os.execute(string.format("mkdir -p %q", dir))
	end
end

function copy(idir, odir)
	if (os.jit == "Windows") then
		os.execute(string.format("copy %q %q", idir, odir))
	else
		os.execute(string.format("cp -r %q %q", idir, odir))
	end
end

function list_archive(arc)
	local p = io.popen(string.format("7z l -ba %q", arc), "r")
	local files = {}
	for line in p:lines() do
		local name = line:match("%s+(.+)$") -- don't have spaces in the file names
		files[#files+1] = name
	end
	p:close()
	return files
end

function extract_archive(arc, out)
	os.execute(string.format("7z e %q -o%q"))
end

function extract_fp_archive(arc, out)
	os.execute(string.format("7z x %q -o%q"))
end

local tdir = ""
function setup_temp_dir()
	tdir = os.tmpname()
	mkdir(tdir)
	mkdir(tdir.."/client_src/modules")
	mkdir(tdir.."/arc_temp")
	mkdir(tdir.."/arc_temp/~nix_arc")
	mkdir(tdir.."/server_src/modules")
end

function get_file_name(path)
	return string.match("/(.+)$")
end

function flatten_name(name)
	return name:grep("%W", "_")
end

function parse_ini(f)
	local sec = {}
	local ini = {_root=sec}
	for line in f:lines() do
		line = line:gsub("^%s+", ""):gsub("%s+$", ""):gsub(";.+", "")
		if line == "" then goto continue end
		local title = line:match("%[(.+)%]")
		if title then
			sec = {}
			ini[title] = sec
			goto continue
		end
		local k, v = line:match("(.+)%s+=%s+(.+)")
		sec[k] = v
		::continue::
	end
	return ini
end

function extract_files(arc)
	local files = list_archive(arc)
	local aname = flatten_name(get_file_name(arc))
	if (#files == 1) then
		mkdir(tdir.."/arc_temp/~nix_arc/"..aname)
		extract_archive(arc, tdir.."/arc_temp/~nix_arc/"..aname)
		return extract_files(tdir.."/arc_temp/~nix_arc/"..aname.."/"..files[1])
	end
	mkdir(tdir.."/arc_temp/"..aname)
	extract_fp_archive(arc, tdir.."/arc_temp/"..aname)
	local h = io.open(tdir.."/arc_temp/"..aname.."/module.ini", "r")
	local config = parse_init(h)
	h:close()
	print(string.format("[3rd Party Module] %s v%s (License: %s)"), config.module.name, config.module.version, config.module.license or "N/A")
	if (config.module.client) then
		copy(tdir.."/arc_temp/"..aname.."/"..config.module.client.."/*", tdir.."/client_temp/modules/"..config.module.namespace)
	end
end