// Similar to SSmachinery powernet but exclusively handles gear networks.
// This avoids loading any expensive bloat on the main machinery subsystem.
SUBSYSTEM_DEF(mechanics)
	name = "Mechanics"
	init_order = INIT_ORDER_MECHANICS
	flags = SS_KEEP_TIMING
	wait = 2 SECONDS
	var/list/processing = list()
	var/list/currentrun = list()
	var/list/gearnets = list()

/datum/controller/subsystem/mechanics/Initialize()
	makegearnets()
	fire()
	return ..()

/datum/controller/subsystem/mechanics/proc/makegearnets()
	for(var/datum/gearnet/GN in gearnets)
		qdel(GN)
	gearnets.Cut()

	for(var/obj/structure/mechanical/gear/M in GLOB.mechanical)
		if(!M.gearnet && M.source)
			var/datum/gearnet/NewGN = new()
			NewGN.add_gear(M)
			propagate_gear_network(M,M.gearnet)

/datum/controller/subsystem/mechanics/stat_entry()
	. = ..("M:[processing.len]|GN:[gearnets.len]")


/datum/controller/subsystem/mechanics/fire(resumed = 0)
	if(!resumed)
		for(var/datum/gearnet/GN as() in gearnets)
			gearnet.reset()
		src.currentrun = processing.Copy()

	//cache for sanic speed (lists are references anyways)
	var/list/currentrun = src.currentrun

	while(currentrun.len)
		var/obj/structure/mechanical/M = currentrun[currentrun.len]
		currentrun.len--
		if(!QDELETED(M) && M.gearable)
			M.transmission_process()
		else
			processing.Remove(M)

		if(MC_TICK_CHECK)
			return

/datum/controller/subsystem/mechanics/proc/setup_template_gearnets(list/gears)
	for(var/obj/structure/mechanical/gear/G in gears)
		if(!G.gearnet)
			var/datum/gearnet/NewGN = new()
			NewGN.add_gear(G)
			propagate_gear_network(G,G.gearnet)

/datum/controller/subsystem/mechanics/Recover()
	if(istype(SSmechanics.processing))
		processing = mechanics.processing
	if(istype(SSmechanics.gearnets))
		gearnets = mechanics.gearnets
