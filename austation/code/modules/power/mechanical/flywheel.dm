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
	var/obj/machinery/mechanical/bearing/bearing
	var/list/additional = list() // additional connected flywheels, used for flywheel stacking
	var/master = TRUE // is not a child addition of another flywheel. flywheel components can only interact with the master wheel

	// flywheel radius in meters, used for maths.
	// I would reccomend keeping it consistent with tile length, treating each meter as a tile.
	var/radius = 1.5
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
	bearing.rpm = rpm
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
	bearing.rpm = rpm
	return TRUE

/obj/machinery/mechanical/flywheel/small
	name = "small flywheel"
	desc = "An extremely durable, dense disk capable of storing large amounts of kinetic energy. This one is a bit smaller than most"
	icon_state = "flywheel_small"
	radius = 0.5
	mass = 75

/obj/machinery/mechanical/flywheel/large
	name = "large flywheel"
	desc = "An extremely durable, dense disk capable of storing large amounts of kinetic energy. This one is quiet bulkier than most"
	icon_state = "flywheel_small"
	radius = 2.5
	mass = 200

// -------------- BEARINGS -------------------

/obj/machinery/mechanical/bearing
	name = "passive magnetic bearing"
	desc = "A high"
	var/max_weight = 1500
	var/instability = 0
	var/instability_threshold = 5
	var/datum/looping_sound/flywheel/soundloop

/obj/machinery/mechanical/bearing/Initialize()
	. = ..()
	soundloop = new(list(src))
	locate_wheel(get_turf(src))

/obj/machinery/mechanical/bearing/Destroy()
	STOP_PROCESSING(SSmachines, src)
	QDEL_NULL(soundloop)
	return ..()

/obj/machinery/mechanical/bearing/proc/startup()
	if(!flywheel)
		flywheel = locate() in loc
	START_PROCESSING(SSmachines, src)
	soundloop.start()

/obj/machinery/mechanical/bearing/process()
	if(!flywheel || (stat & BROKEN))
		return PROCESS_KILL

	if(rpm > max_rpm || (flywheel.mass > max_weight && has_gravity(get_turf(src))))
		instability += rand(0.2, 2.5)
		handle_overload()
		return

	if(instability)
		if(max_rpm > rpm)
			instability -= min(rand(2, 3), instability)

		if(instability > instability_threshold)
			var/damage = (instability - instability_threshold) / 3
			take_damage(damage)
		handle_overload()

/obj/machinery/mechanical/bearing/proc/handle_overload()
	if(rpm > max_rpm)
		var/diff = max(rpm - max_rpm, 0)
		if(prob(1 + instability + log(diff) * 2))
			overstress()
	else
		instability -= min(rand(2, 8), instability)

#define WEIGHT_LOSS 100

/// permanently reduces the bearing's load capacity, multiplied by the "damage" argument
/obj/machinery/mechanical/bearing/take_damage(damage)
	..()
	max_weight -= WEIGHT_LOSS * damage

/// same as take_damage() but reversed
/obj/machinery/mechanical/bearing/restore_integrity(repair)
	. = ..()
	var/o_weight = initial(max_weight)
	max_weight = min(max_weight + WEIGHT_LOSS * repair, o_weight)
	if(damaged && max_weight == o_weight && .)
		damaged = FALSE
		return TRUE

#undef WEIGHT_LOSS

/obj/machinery/mechanical/power/motor
	name = "electric flywheel motor"
	desc = "A high-power motor designed to input kinetic energy into a flywheel"
	icon_state = "motor"
	var/max_input = 50000 // joules
	var/current_input = 0
	var/rotor_radius = 0.5

/obj/machinery/mechanical/power/motor/process()
	if(!current_input || !powernet || (stat & BROKEN) || !flywheel)
		return
	var/drained = min(current_input, powernet.surplus(), max_input)
	if(drained)
		powernet.add_load(drained)
		flywheel.add_energy(drained * GLOB.CELLRATE) // convert watts to joules

/obj/machinery/mechanical/power/motor/locate_wheel(turf/T)
	for(var/obj/machinery/mechanical/flywheel/W in circleview(1 + COMPONENT_SCAN_RANGE, T))
		if(W.master && (get_dist(T, W) == W.radius + rotor_radius))
			flywheel = W
			return TRUE
	return FALSE

/obj/machinery/mechanical/power/
