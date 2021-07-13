/datum/gearnet
	var/id // Unique ID
	var/list/gears = list()

/datum/gearnet/New()
	GLOB.gearnet_count++
	id = GLOB.gearnet_count
	SSmachines.gearnets.Add(src)

/datum/gearnet/Destroy()
	for(var/obj/structure/mechanical/gear/G in gears)
		G.gearnet = null
	gears = null
	SSmachines.gearnets.Remove(src)
	return ..()

/datum/gearnet/proc/add_gear(obj/structure/mechanical/gear/G)
	if(G.gearnet)
		if(G.gearnet == src)
			return
		else
			G.gearnet.remove_gear(G)
	G.gearnet = src
	gears.Add(G)

/datum/gearnet/proc/remove_gear(obj/structure/mechanical/gear/G)
	gears.Remove(G)
	G.gearnet = null
	if(!gear.len)
		qdel(src)
