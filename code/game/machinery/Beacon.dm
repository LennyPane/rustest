/obj/machinery/bluespace_beacon

	icon = 'icons/obj/objects.dmi'
	icon_state = "floor_beaconf"
	name = "блюспейс гигамаяк"
	desc = "Устройство, которое черпает энергию из БС пространства и создает постоянный маяк слежения для ботов."
	layer = LOW_OBJ_LAYER
	use_power = IDLE_POWER_USE
	idle_power_usage = 0
	var/obj/item/beacon/Beacon

/obj/machinery/bluespace_beacon/Initialize()
	. = ..()
	var/turf/T = loc
	Beacon = new(T)
	Beacon.invisibility = INVISIBILITY_MAXIMUM

	AddElement(/datum/element/undertile, TRAIT_T_RAY_VISIBLE)

/obj/machinery/bluespace_beacon/Destroy()
	QDEL_NULL(Beacon)
	return ..()

/obj/machinery/bluespace_beacon/process()
	if(QDELETED(Beacon)) //Don't move it out of nullspace BACK INTO THE GAME for the love of god
		var/turf/T = loc
		Beacon = new(T)
		Beacon.invisibility = INVISIBILITY_MAXIMUM
	else if (Beacon.loc != loc)
		Beacon.forceMove(loc)
