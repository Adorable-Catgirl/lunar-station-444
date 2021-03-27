local lzma = require("lzma")

function editor:save(body, path)
	local f = io.open(path, "wb")
	local dat = lzma.compress(blt2.serialize(body))
end