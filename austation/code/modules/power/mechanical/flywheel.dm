//	var/gear_ratio = (rotor_radius * 2 * PI) / (flywheel.radius * 2 * PI)

// disk flywheels
#define INERTIAL_CONSTANT 0.606

// Rotations per minute to radians per second
#define RPM_TO_RADS(R) (R / 60 * 2 * PI)

#define RADS_TO_RPM(R) (R * 60 / 2 / PI)

/obj/machinery/mechanical/flywheel
	name = "flywheel"
	desc = "An extremely durable, dense disk capable of storing large amounts of kinetic energy"
	icon_state = "flywheel"
	appearance_flags = KEEP_TOGETHER
	pixel_x = -16
	pixel_y = -16
	var/obj/machinery/mechanical/bearing/bearing
	var/list/additional = list() // additional connected flywheels, used for flywheel stacking
	var/master = TRUE // is not a child addition of another flywheel. flywheel components can only interact with the master wheel

	// flywheel radius in meters, used for maths.
	// I would reccomend keeping it consistent with tile length, treating each meter as a tile.
	var/radius = 1
	var/mass = 100 // mass in kilograms.
	var/rpm = 0
	var/angular_mass = 0

/obj/machinery/mechanical/flywheel/Initialize()
	angular_mass = get_inertia()
	return ..()

/obj/machinery/mechanical/flywheel/proc/get_inertia()
	return INERTIAL_CONSTANT * mass * radius**2

/obj/machinery/mechanical/flywheel/proc/get_energy(isolated = FALSE)
	var/energy = 0.5 * angular_mass * RPM_TO_RADS(rpm) ** 2
	if(!additional.len || isolated)
		return energy

	var/t_energy = energy
	for(var/obj/machinery/mechanical/flywheel/F in additional)
		t_energy += F.get_energy(TRUE)

	return t_energy

/// Probably will be used for something
/obj/machinery/mechanical/flywheel/proc/get_centrif_force()
	return (mass * rpm ** 2) * radius

/obj/machinery/mechanical/flywheel/proc/add_energy(joules, safe = FALSE)
	if(!bearing)
		return FALSE
	var/rpm_increase = RADS_TO_RPM(sqrt(joules / (angular_mass / 2)))
	if(additional.len)
		rpm_increase /= additional.len
		for(var/obj/machinery/mechanical/flywheel/F in additional)
			F.rpm += rpm_increase
	rpm += rpm_increase
	return TRUE

/obj/machinery/mechanical/flywheel/proc/overstress(warning = TRUE)
	if(!warning)
		footloose()
	else
		addtimer(CALLBACK(src, .proc/footloose), rand(10, 50))

/obj/machinery/mechanical/flywheel/proc/footloose()
	var/energy = get_energy()
	//todo: everything related to this

/obj/machinery/mechanical/flywheel/proc/suck_energy(joules, isolated = FALSE)
	if(!bearing)
		return FALSE
	var/sucked = max(RADS_TO_RPM(sqrt(joules / (angular_mass / 2))), rpm)
	if(additional.len)
		sucked /= additional.len
		for(var/obj/machinery/mechanical/flywheel/F in additional)
			F.rpm -= sucked
	rpm -= sucked
	return TRUE

/obj/machinery/mechanical/flywheel/Bumped(atom/movable/AM)
	if(AM.movement_type & UNSTOPPABLE)
		return
	var/bonk = log(rpm) * 10
	if(bonk > 25)
		if(isliving(AM))
			var/mob/living/L = AM
			L.adjustBruteLoss(bonk)
		playsound(src, 'sound/effects/clang.ogg', min(bonk, 100), FALSE)
	AM.throw_at(get_edge_target_turf(src, get_dir(src, AM), bonk, bonk / 10))

/obj/machinery/mechanical/flywheel/small
	name = "small flywheel"
	desc = "An extremely durable, dense disk capable of storing large amounts of kinetic energy. This one is a bit smaller than most."
	icon_state = "flywheel_small"
	pixel_x = 0
	pixel_y = 0
	radius = 0.5
	mass = 50

/obj/machinery/mechanical/flywheel/large
	name = "large flywheel"
	desc = "An extremely durable, dense disk capable of storing large amounts of kinetic energy. This one is a bit bulkier than most."
	icon_state = "flywheel_large"
	pixel_x = -32
	pixel_y = -32
	radius = 1.5
	mass = 175

// -------------- BEARINGS -------------------

/obj/machinery/mechanical/bearing
	name = "passive magnetic bearing"
	desc = "A high"
	var/max_load = 1500
	var/instability = 0
	var/instability_threshold = 5
	var/datum/looping_sound/flywheel/soundloop

/obj/machinery/mechanical/bearing/Initialize()
	. = ..()
	soundloop = new(list(src))

/obj/machinery/mechanical/bearing/Destroy()
	locate_wheel()
	if(flywheel)
		flywheel.footloose()
	STOP_PROCESSING(SSmachines, src)
	QDEL_NULL(soundloop)
	return ..()

/obj/machinery/mechanical/bearing/proc/startup()
	locate_wheel()
	if(!flywheel && !locate_wheel(get_turf(src)))
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

/obj/machinery/mechanical/power/motor
	name = "electric flywheel motor"
	desc = "A high-power motor designed to input kinetic energy into a flywheel"
	icon_state = "motor"
	var/capacity = 50000 // max amount of input
	var/current_amt = 0 // current amount of input
	var/rotor_radius = 0.5 // radius of the rotor, used in tile calculations

/obj/machinery/mechanical/power/motor/process()
	if(!current_amt || !powernet || (stat & BROKEN) || !flywheel)
		return
	var/drained = min(current_amt, powernet.surplus(), capacity)
	if(drained)
		powernet.add_load(drained)
		flywheel.add_energy(drained * GLOB.CELLRATE) // convert watts to joules

/obj/machinery/mechanical/power/motor/locate_wheel(turf/T)
	for(var/obj/machinery/mechanical/flywheel/W in circleview(1 + COMPONENT_SCAN_RANGE, T))
		if(W.master && (get_dist(T, W) == W.radius + rotor_radius))
			flywheel = W
			return TRUE
	return FALSE

/obj/machinery/mechanical/power/motor/examine()
	. = ..()
	if(!powernet)
		. += "<span class='warning'>It's not currently connected to a grid.</span>"

/obj/machinery/mechanical/power/motor/generator
	name = "electric generator"
	desc = "Converts mechanical energy into electricty"
	icon_state = "generator"

/obj/machinery/mechanical/power/motor/generator/process()
	if(!current_amt || !powernet || (stat & BROKEN) || !flywheel)
		return
	var/added = min(current_amt, flywheel.get_energy(), capacity)
	if(added > 0)
		powernet.add_avail(added / GLOB.CELLRATE))  // convert joules to watts
		flywheel.suck_energy(added)
