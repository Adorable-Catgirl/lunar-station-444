local sock = require("luasocket")

local id = 0

local nwq = {} -- network queue, actually UDP
local fnwq = {} -- forced network queue, actually TCP

-- Warning: Here there be dragons
local function nwthread()
	
end

local net = {}

function net.listen(mtype, handler)

end