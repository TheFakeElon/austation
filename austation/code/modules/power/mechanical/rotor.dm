// -------------- BEARINGS -------------------

/obj/structure/mechanical/bearing
	name = "passive magnetic bearing"
	desc = "A sturdy magnetic bearing capable of supporting the mechanical stresses induced by high speed flywheels."
	radius = 0 // Flywheel is placed ontop of this
	gearable = FALSE
	var/max_load = 1500
	var/instability = 0
	var/instability_threshold = 5
	var/datum/looping_sound/flywheel/soundloop

	var/obj/structure/flywheel/flywheel // connected flywheel, if any

/obj/structure/mechanical/bearing/Initialize()
	. = ..()
	soundloop = new(list(src))

/obj/structure/mechanical/bearing/Destroy()
	if(flywheel)
		flywheel.footloose()
	STOP_PROCESSING(SSmachines, src)
	QDEL_NULL(soundloop)
	return ..()

/obj/structure/mechanical/bearing/locate_flywheel()
	for(var/obj/structure/flywheel/W in GLOB.mechanical)
		if(W.master && W.loc == loc)
			flywheel = W
			return TRUE
	return FALSE

/obj/structure/mechanical/bearing/proc/startup()
	if(!flywheel && !locate_mechanical())
		return FALSE
	START_PROCESSING(SSmachines, src)
	soundloop.start()
	return TRUE

/obj/structure/mechanical/bearing/process()
	if(!flywheel)
		return PROCESS_KILL

	if(flywheel.rpm > max_rpm) // || (flywheel.mass > max_load && has_gravity(get_turf(src)))
		instability += rand(0.2, 2.5)
		handle_overload()
		return

	if(instability)
		if(max_rpm > flywheel.rpm)
			instability -= min(rand(2, 3), instability)

		if(instability > instability_threshold)
			handle_overload()

/obj/structure/mechanical/bearing/proc/handle_overload()
	if(flywheel?.rpm > max_rpm)
		var/diff = max(flywheel.rpm - max_rpm, 0)
		if(flywheel && prob(1 + instability + log(diff) * 2))
			flywheel.overstress() // handling in overstress() for consistency, even if it is only one call
	else
		instability -= min(rand(2, 8), instability)

/obj/structure/mechanical/bearing/overstress()
	qdel(src)
	return TRUE

// -------------- FLYWHEEL MOTORS -------------------

/obj/structure/mechanical/flywheel_motor
	name = "electric flywheel motor"
	desc = "A high-power motor designed to input kinetic energy into a flywheel"
	icon_state = "fmotor"
	radius = 0.5 // radius of the rotor
	var/max_delta = 50000 // max input/output in joules
	var/current_amt = 0 // current amount of input
	var/obj/structure/flywheel/flywheel // connected flywheel, if any
	var/obj/structure/cable/cable

/obj/structure/mechanical/flywheel_motor/locate_mechanical()
	for(var/obj/structure/flywheel/W in GLOB.mechanical)
		if(W.master && get_dist(W) == W.radius * 2)
			flywheel = W
			return TRUE
	return FALSE

/obj/structure/mechanical/flywheel_motor/process()
	var/turf/T = get_turf(src)
	cable = T.get_cable_node()
	if(!current_amt || !flywheel)
		return
	var/drained = min(current_amt, cable.surplus(), max_input)
	if(drained)
		cable.add_load(drained)
		flywheel.add_energy(drained * GLOB.CELLRATE) // convert watts to joules

/obj/structure/mechanical/flywheel_motor/examine()
	. = ..()
	if(!cable)
		. += "<span class='warning'>It's not currently connected to a grid.</span>"

/obj/structure/mechanical/flywheel_motor/generator
	name = "electric generator"
	desc = "Converts mechanical energy into electricty"
	icon_state = "fgenerator"
	max_delta = 100000

/obj/structure/mechanical/flywheel_motor/generator/process()
	if(!current_amt || !cable || !flywheel)
		return
	var/added = min(current_amt, flywheel.get_energy(), max_delta)
	if(added > 0)
		cable.add_avail(added / GLOB.CELLRATE) // convert joules to watts
		flywheel.suck_energy(added)

// -------------- MECHANICAL MOTORS -------------------
// ------ (Or more specifically, ones for gears.) -----

/obj/structure/mechanical/gear/power/motor
	name = "electric motor"
	desc = "A high-power electric motor. Converts electrical energy into mechanical rotational energy."
	icon_state = "motor"
	radius = 0.5
	max_input = 50000
	source = TRUE

/obj/structure/mechanical/gear/power/motor/locate_mechanical()
	for(var/obj/structure/mechanical/M in GLOB.mechanical)
		if(M.gearable && get_dist(src, M) == radius * 2)
			gearnet = M.gearnet
			if(!gearnet)
				var/datum/gearnet/GN = new()
				properagate_gear_network(src, GN)
