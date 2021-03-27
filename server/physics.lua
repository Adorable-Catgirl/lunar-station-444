local physics = {}

local m_sqrt, m_cos, m_sin, m_acos, m_asin, m_atan = math.sqrt, math.sin, math.cos, math.acos, math.asin, math.atan
local big_G = 6.67e-11
function physics.apply_gravitational_pull(obj1, obj2)
	local m1 = obj1:get_mass()
	local m2 = obj2:get_mass()

	local x1, y1 = obj1:get_coords()
	local x2, y2 = obj2:get_coords()

	local d_x = x1-x2
	local d_y = y1-y2

	local dist_sqr = (d_x^2+d_y^2)

	local azimuth = m_atan(y/x)

	-- plug it into
	-- G x M x m
	-- ---------
	--   dist^2
	local force = (big_G * m1 * m2)/dist_sqr
	obj1:apply_polar_force(force, azimuth)
end

function physics.update_object(obj)

end