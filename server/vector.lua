local vector = {}

function vector:polar()
	return mathx.cartesian_to_polar(self.x, self.y)
end

function vector:cartesian()
	return self.x, self.y
end

function vector:copy()
	return vec(self.x, self.y)
end

function vector:add(v1)
	self:cartesian_add(v1.x, v1.y)
end

function vector:polar_add(radius, azimuth)
	local x, y = mathx.polar_to_cartesian(radius, azimuth)
	self.x, self.y = self.x+x, self.y+y
end

function vector:cartesian_add(x, y)
	self.x, self.y = self.x+x, self.y+y
end

function vector:subtract(v1)
	self:cartesian_subtract(v1.x, v1.y)
end

function vector:polar_subtract(radius, azimuth)
	local x, y = mathx.polar_to_cartesian(radius, azimuth)
	self.x, self.y = self.x-x, self.y-y
end

function vector:cartesian_subtract(x, y)
	self.x, self.y = self.x-x, self.y-y
end

function vector:length()

end

function vector:multiply(mult)
	self.x = self.x * mult
	self.y = self.y * mult
end

function vec(x, y, polar)
	if polar then
		x, y = mathx.polar_to_cartesian(x, y)
	end
	return setmetatable({x=x, y=y}, {__index=vector,})
end