object = inheritable()

object.vars.coords = {
	x = 0,
	y = 0,
	z = 0, -- only integers, please
	azimuth = 0
}

object.vars.mass = 0

function object:get_mass()
	return self.mass
end