
/// Make sure to update this if adding larger gears/wheels
#define COMPONENT_SCAN_RANGE 3

/obj/machinery/mechanical
	name = "mechanical component"
	icon = 'austation/icons/obj/machinery/mechanical.dmi'
	anchored = TRUE
	obj_flags = CAN_BE_HIT | ON_BLUEPRINTS
	use_power = NO_POWER_USE
	idle_power_usage = 0
	active_power_usage = 0
	var/damaged = FALSE
	var/gearable = TRUE // Can this be spun by gears?
	var/max_rpm = 60000 // max rotations per minute before we start taking damage
	var/list/connections = list() // connected mechanical parts
	var/obj/machinery/mechanical/flywheel/flywheel // connected flywheel, if any

	// flywheel radius in meters.
	// keep it consistent with tile length, treating each meter as a tile. The resulting **diameter** should always be a whole number
	// I.e, a radius of one will take up two tiles, a radius of 1.5 will take up 3. Hitboxes are dynamically asigned on init based off this value
	var/radius = 1

/obj/machinery/mechanical/Initialize()
	. = ..()
	locate_machinery()
	bound_width = 32 * (radius * 2)
	bound_height = 32 * (radius * 2)

/obj/machinery/mechanical/on_construction()
	locate_machinery()

/obj/machinery/mechanical/proc/locate_flywheel()
	for(var/obj/machinery/mechanical/flywheel/W in GLOB.machines)
		if(W.master && get_dist(W) == W.radius * 2)
			flywheel = W
			return TRUE
	return FALSE

/obj/machinery/mechanical/locate_machinery()
	return locate_flywheel()

/obj/machinery/mechanical/proc/overstress()
	qdel(src)

// Mechanical components that utilize powernet should be a subtype of this
/obj/machinery/mechanical/power
	var/max_input = 50000 // joules
	var/max_output = 50000 // joules
	var/obj/structure/cable/cable

