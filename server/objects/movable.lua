object.movable.subpixel_movement = true
object.movable.has_gravity = false -- let's just say they don't for simplicities sake

objects.vars.velocity = { -- Measured in azimuth and speed because it makes gravitational calculations easier, but can be switched to x/y mode if needed
	azimuth = 0,
	speed = 0 
}

function object.movable:new()

end