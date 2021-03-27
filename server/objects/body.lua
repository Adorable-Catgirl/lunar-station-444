object.movable.body.var.tiles = {}
object.movable.body.var.entities = {}

function object.movable.body:new()
	super()
	if (self.body_src) then
		local hand = fs.open(self.body_src, "rb")
		local data = hand:read("*a")
		hand:close()
		local mapdat = blt2.deserialize(data)
	end
end

function object.movable.body:add_tiles(tiles)
	-- i dunno how i'm gonna store tiles. maybe by {x,y} tables?
end

function object.movable.body:add_entity(x, y)

end

function object.movable.body:get_mass()
	local mass = 0
	for k, v in pairs(self.tiles) do
		mass = mass + self.tiles:mass()
	end
	for i=1, #entities do
		
	end
end