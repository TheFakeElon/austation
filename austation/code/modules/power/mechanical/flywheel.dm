// disk flywheels
#define INERTIAL_CONSTANT 0.606

/obj/structure/flywheel
	name = "flywheel"
	desc = "An extremely durable, dense disk capable of storing large amounts of kinetic energy"
	icon_state = "flywheel"
	appearance_flags = KEEP_TOGETHER
	movement_type = UNSTOPPABLE
	pixel_x = -16
	pixel_y = -16
	var/radius = 1 // hitboxes are dynamically asigned on intialize.
	// bearing should always be on the same tile as the flywheel
	var/obj/structure/mechanical/bearing/bearing
	var/list/additional = list() // additional connected flywheels, used for flywheel stacking.
	var/master = TRUE // is not a child addition of another flywheel. flywheel components can only interact with the master wheel
	var/mass = 100 // mass in kilograms.
	var/rpm = 0
	var/angular_mass = 0

	var/loose = FALSE // Is this flywheel currently a bayblade?

	var/list/shitlist = list() // Mobs who aren't going to live very longer
	var/mob/shitlist_target

/obj/structure/flywheel/Initialize()
	angular_mass = get_inertia()
	return ..()

/obj/structure/flywheel/proc/get_inertia() // Maths >:(
	return INERTIAL_CONSTANT * mass * radius**2

/obj/structure/flywheel/proc/get_energy(isolated = FALSE)
	var/energy = 0.5 * angular_mass * RPM_TO_RADS(rpm) ** 2
	if(!additional.len || isolated)
		return energy

	var/t_energy = energy
	for(var/obj/structure/flywheel/F in additional)
		t_energy += F.get_energy(TRUE)

	return t_energy

/// Probably will be used for something
/obj/structure/flywheel/proc/get_centrif_force()
	return (mass * rpm ** 2) * radius

/obj/structure/flywheel/proc/add_energy(joules, safe = FALSE)
	if(!bearing)
		return FALSE
	var/rpm_increase = RADS_TO_RPM(sqrt(joules / (angular_mass / 2)))
	if(additional.len)
		rpm_increase /= additional.len
		for(var/obj/structure/flywheel/F in additional)
			F.rpm += rpm_increase
	rpm += rpm_increase
	return TRUE

/obj/structure/flywheel/proc/overstress(warning = TRUE)
	if(!warning)
		footloose()
	else
		addtimer(CALLBACK(src, .proc/footloose), rand(10, 50))

/obj/structure/flywheel/proc/footloose()
	set waitfor = FALSE
	for(var/i in 1 to rand(3, 5))
		sleep(rand(4, 10))
		playsound(src, 'sound/effects/clang.ogg', rand(80, 90) + 10 / i, TRUE)
	step_rand(src)
	START_PROCESSING(SSobj, src)

/obj/structure/flywheel/proc/suck_energy(joules, isolated = FALSE)
	if(!bearing)
		return FALSE
	var/sucked = max(RADS_TO_RPM(sqrt(joules / (angular_mass / 2))), rpm)
	if(additional.len)
		sucked /= additional.len
		for(var/obj/structure/flywheel/F in additional)
			F.rpm -= sucked
	rpm -= sucked
	return TRUE

/obj/structure/flywheel/process()
	if(!loose)
		return PROCESS_KILL
	if(length(shitlist))
		if(!shitlist_target || isdead(shitlist_target))
			var/closest = 130
			for(var/mob/M as() in shitlist)
				if(isdead(M))
					shitlist.Remove(M)
					continue
				if(M.z != z)
					continue
				var/dist = get_dist(src, M)
				if(dist < closest)
					closet = closest
					shitlist_target = M
		else if(get_dist(src, shitlist_target) >= radius * 2)
			Move(get_step_towards(shitlist_target))
			return
	if(prob(30))
		Move(get_step_rand(src))

/obj/structure/mechanical/bearing/Destroy()
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/structure/flywheel/Bump(atom/movable/AM)
	contact(AM)

/obj/structure/flywheel/Bumped(atom/movable/AM)
	contact(AM)

/obj/structure/flywheel/proc/contact(atom/movable/AM)
	var/bonk = log(rpm) * 10
	if((AM.movement_type & UNSTOPPABLE) || bonk < 25)
		return
	playsound(src, 'sound/effects/clang.ogg', min(bonk, 100), FALSE)
	if(iswallturf(AM))
		var/turf/closed/wall/T = AM
		T.devastate_wall()
		suck_energy(7000)
		return
	if(isliving(AM))
		var/mob/living/L = AM
		L.adjustBruteLoss(bonk)
		suck_energy(5000)
	AM.throw_at(get_edge_target_turf(src, get_dir(src, AM), bonk, bonk / 10))
	suck_energy(1000)


/obj/structure/flywheel/small
	name = "small flywheel"
	desc = "An extremely durable, dense disk capable of storing large amounts of kinetic energy. This one is a bit smaller than most."
	icon_state = "flywheel_small"
	pixel_x = 0
	pixel_y = 0
	radius = 0.5
	mass = 50

/obj/structure/flywheel/large
	name = "large flywheel"
	desc = "An extremely durable, dense disk capable of storing large amounts of kinetic energy. This one is a bit bulkier than most."
	icon_state = "flywheel_large"
	pixel_x = -32
	pixel_y = -32
	radius = 1.5
	mass = 175
