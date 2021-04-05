
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
	var/obj/effect/flywheel/flywheel // connected flywheel, if any

/obj/machinery/mechanical/proc/locate_wheel(turf/T)
	for(var/obj/effect/flywheel/W in T)
		if(W.master)
			flywheel = W
			return TRUE
	return FALSE

// How much operational capacity is removed/restored when being damaged or repaired respectively
#define RPM_LOSS 700

/// permanently reduces the load capacity, multiplied by the "damage" argument
/obj/machinery/mechanical/bearing/proc/take_damage(damage)
	damaged = TRUE
	max_rpm -= RPM_LOSS * damage

/// same as take_damage() but reversed
/obj/machinery/mechanical/bearing/proc/restore_integrity(repair)
	var/o_rpm = initial(max_rpm)
	max_rpm = min(max_rpm + RPM_LOSS * repair, o_rpm)
	if(damaged && max_rpm == o_rpm)
		damaged = FALSE
		return TRUE

#undef RPM_LOSS
/obj/machinery/mechanical/power
	var/max_input = 50000 // joules
	var/max_output = 50000 // joules
	var/obj/structure/cable/powernet

/obj/machinery/mechanical/power/proc/locate_powergrid(turf/T)
	powernet = T.get_cable_node().powernet
	return powernet
