mathx = {}

local m_sqrt, m_cos, m_sin, m_acos, m_asin, m_atan = math.sqrt, math.sin, math.cos, math.acos, math.asin, math.atan
function mathx.cartesian_to_polar(x, y)
	local radius = sqrt(x^2+y^2)
	local azimuth = m_atan(y/x)
	return radius, azimuth
end

function mathx.polar_to_cartesian(radius, azimuth)
	local x = radius * m_cos(azimuth)
	local y = radius * m_sin(azimuth)
	return x, y
end