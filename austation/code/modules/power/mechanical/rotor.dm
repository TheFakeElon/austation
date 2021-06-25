// -------------- BEARINGS -------------------

/obj/machinery/mechanical/bearing
	name = "passive magnetic bearing"
	desc = "A sturdy magnetic bearing capable of supporting the mechanical stresses induced by high speed flywheels."
	radius = 0 // Flywheel is placed ontop of this
	gearable = FALSE
	var/max_load = 1500
	var/instability = 0
	var/instability_threshold = 5
	var/datum/looping_sound/flywheel/soundloop

/obj/machinery/mechanical/bearing/Initialize()
	. = ..()
	soundloop = new(list(src))

/obj/machinery/mechanical/bearing/Destroy()
	if(flywheel)
		flywheel.footloose()
	STOP_PROCESSING(SSmachines, src)
	QDEL_NULL(soundloop)
	return ..()

/obj/machinery/mechanical/bearing/locate_flywheel()
	for(var/obj/machinery/mechanical/flywheel/W in GLOB.machines)
		if(W.master && W.loc == loc)
			flywheel = W
			return TRUE
	return FALSE

/obj/machinery/mechanical/bearing/proc/startup()
	if(!flywheel && !locate_flywheel())
		return FALSE
	START_PROCESSING(SSmachines, src)
	soundloop.start()
	return TRUE

/obj/machinery/mechanical/bearing/process()
	if(!flywheel || (stat & BROKEN))
		return PROCESS_KILL

	if(flywheel.rpm > max_rpm || (flywheel.mass > max_load && has_gravity(get_turf(src))))
		instability += rand(0.2, 2.5)
		handle_overload()
		return

	if(instability)
		if(max_rpm > flywheel.rpm)
			instability -= min(rand(2, 3), instability)

		if(instability > instability_threshold)
			handle_overload()

/obj/machinery/mechanical/bearing/proc/handle_overload()
	if(flywheel?.rpm > max_rpm)
		var/diff = max(flywheel.rpm - max_rpm, 0)
		if(flywheel && prob(1 + instability + log(diff) * 2))
			flywheel.overstress() // handling in overstress() for consistency, even if it is only one call
	else
		instability -= min(rand(2, 8), instability)

/obj/machinery/mechanical/bearing/overstress()
	qdel(src)
	return TRUE

// -------------- MOTORS -------------------

/obj/machinery/mechanical/power/motor
	name = "electric flywheel motor"
	desc = "A high-power motor designed to input kinetic energy into a flywheel"
	icon_state = "motor"
	radius = 0.5 // radius of the rotor
	var/capacity = 50000 // max amount of input
	var/current_amt = 0 // current amount of input

/obj/machinery/mechanical/power/motor/process()
	var/turf/T = get_turf(src)
	cable = T.get_cable_node()
	if(!current_amt || (stat & BROKEN) || !flywheel)
		return
	var/drained = min(current_amt, cable.surplus(), capacity)
	if(drained)
		cable.add_load(drained)
		flywheel.add_energy(drained * GLOB.CELLRATE) // convert watts to joules

/obj/machinery/mechanical/power/motor/examine()
	. = ..()
	if(!cable)
		. += "<span class='warning'>It's not currently connected to a grid.</span>"

/obj/machinery/mechanical/power/motor/generator
	name = "electric generator"
	desc = "Converts mechanical energy into electricty"
	icon_state = "generator"

/obj/machinery/mechanical/power/motor/generator/process()
	if(!current_amt || !cable || (stat & BROKEN) || !flywheel)
		return
	var/added = min(current_amt, flywheel.get_energy(), capacity)
	if(added > 0)
		cable.add_avail(added / GLOB.CELLRATE) // convert joules to watts
		flywheel.suck_energy(added)
