//	var/gear_ratio = (rotor_radius * 2 * PI) / (flywheel.radius * 2 * PI)

// disk flywheels
#define INERTIAL_CONSTANT 0.606

/obj/machinery/mechanical/flywheel
	name = "flywheel"
	desc = "An extremely durable, dense disk capable of storing large amounts of kinetic energy"
	icon_state = "flywheel"
	appearance_flags = KEEP_TOGETHER
	movement_type = UNSTOPPABLE
	pixel_x = -16
	pixel_y = -16
	radius = 1 // hitboxes are dynamically asigned on intialize.
	var/obj/machinery/mechanical/bearing/bearing
	var/list/additional = list() // additional connected flywheels, used for flywheel stacking
	var/master = TRUE // is not a child addition of another flywheel. flywheel components can only interact with the master wheel
	var/mass = 100 // mass in kilograms.
	var/rpm = 0
	var/angular_mass = 0

	var/loose = FALSE // Is this flywheel currently a bayblade?

/obj/machinery/mechanical/flywheel/Initialize()
	angular_mass = get_inertia()
	return ..()

/obj/machinery/mechanical/flywheel/proc/get_inertia() // Maths >:(
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
	set waitfor = FALSE
	for(var/i in 1 to rand(3, 5))
		sleep(rand(4, 10))
		playsound(src, 'sound/effects/clang.ogg', rand(80, 90) + 10 / i, TRUE)
	step(pick(GLOB.cardinals))
	START_PROCESSING(SSobj, src)

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

/obj/machinery/mechanical/flywheel/process()
	if(!loose)
		return PROCESS_KILL
	var/energy = get_energy()
	if(prob(30))
		step(pick(GLOB.cardinals))

/obj/machinery/mechanical/bearing/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/machinery/mechanical/flywheel/Bump(atom/movable/AM)
	contact(AM)

/obj/machinery/mechanical/flywheel/Bumped(atom/movable/AM)
	contact(AM)

/obj/machinery/mechanical/flywheel/proc/contact(atom/movable/AM)
	if((AM.movement_type & UNSTOPPABLE) || bonk < 25)
		return
	var/bonk = log(rpm) * 10
	playsound(src, 'sound/effects/clang.ogg', min(bonk, 100), FALSE)
	if(iswallturf(AM))
		var/turf/closed/wall/T = AM
		T.devastate_wall()
		return
	if(isliving(AM))
		var/mob/living/L = AM
		L.adjustBruteLoss(bonk)
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
