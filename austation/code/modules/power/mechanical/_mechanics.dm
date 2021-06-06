
/// Make sure to update this if adding larger gears/wheels
#define COMPONENT_SCAN_RANGE 3

/obj/machinery/mechanical
	name = null
	icon = 'austation/icons/obj/machinery/mechanical.dmi'
	anchored = TRUE
	obj_flags = CAN_BE_HIT | ON_BLUEPRINTS
	use_power = NO_POWER_USE
	idle_power_usage = 0
	active_power_usage = 0
	var/damaged = FALSE
	var/max_rpm = 60000 // max rotations per minute before we start taking damage
	var/list/connections = list() // connected mechanical parts
	var/obj/machinery/mechanical/flywheel/flywheel // connected flywheel, if any

/obj/machinery/mechanical/Initialize()
	. = ..()
	locate_machinery()

/obj/machinery/mechanical/on_construction()
	locate_machinery()

/obj/machinery/mechanical/proc/locate_flywheel(turf/T)
	for(var/obj/machinery/mechanical/flywheel/W in T)
		if(W.master)
			flywheel = W
			return TRUE
	return FALSE

/obj/machinery/mechanical/locate_machinery()
	return locate_flywheel(get_turf(src))

/obj/machinery/mechanical/proc/overstress()
	return

/obj/machinery/mechanical/power
	var/max_input = 50000 // joules
	var/max_output = 50000 // joules
	var/obj/structure/cable/powernet

/obj/machinery/mechanical/power/proc/locate_powergrid(turf/T)
	powernet = T.get_cable_node().powernet
	return powernet
