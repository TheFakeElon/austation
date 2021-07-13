/obj/structure/mechanical
	name = "mechanical component"
	icon = 'austation/icons/obj/machinery/mechanical.dmi'
	anchored = TRUE
	obj_flags = CAN_BE_HIT | ON_BLUEPRINTS
	var/damaged = FALSE
	var/gearable = TRUE // Can this be spun by gears?
	var/max_rpm = 60000 // max rotations per minute before we start taking damage
	var/list/connections = list() // connected mechanical parts

	// part radius in meters (tiles).
	// keep it consistent with tile length, treating each meter as a tile. The resulting **diameter** should always be a whole number
	// I.e, a radius of one will take up two tiles, a radius of 1.5 will take up 3. Hitboxes are dynamically asigned on init based off this value
	// 0.5 should be used for one tile (32x32 pixel) objects
	var/radius = 0

/obj/structure/mechanical/New()
	..()
	GLOB.mechanical.Add(src)
	locate_mechanical()
	bound_width = 32 * (radius * 2)
	bound_height = 32 * (radius * 2)

/obj/structure/mechanical/proc/locate_mechanical()
	return TRUE

/obj/structure/mechanical/proc/overstress()
	qdel(src)

/obj/structure/mechanical/Destroy()
	GLOB.mechanical.Remove(src)
	return ..()

// Mechanical components that utilize powernet should be a subtype of this
/obj/structure/mechanical/power
	var/max_input = 50000 // joules
	var/max_output = 50000 // joules
	var/obj/structure/cable/cable

// Basic gear
/obj/structure/mechanical/gear
	name = "plasteel gear"
	desc = "A basic gear used to transfer rotary motion between objects."
	icon = 'austation/icon/obj/machinery/mechanical.dmi'
	radius = 0.5
	var/datum/gearnet/gearnet
//	var/gear_ratio = (rotor_radius * 2 * PI) / (flywheel.radius * 2 * PI)

/obj/structure/mechanical/gear/locate_mechanical()
	for(var/obj/structure/mechanical/gear/G in GLOB.mechanical)
		if(get_dist(src, G) == radius * 2)
			gearnet = G.gearnet
			if(!gearnet)
				gearnet = new()
			gearnet.add_gear(src)

