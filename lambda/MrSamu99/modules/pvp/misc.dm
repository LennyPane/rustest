#define SHIP_GRACE_TIME (3 MINUTES)

/datum/overmap/ship/controlled
	var/obj/machinery/computer/helm/most_recent_helm // For sending messages to the target's helm
	///Cooldown for when you get subverted and cannot control the ship anymore
	COOLDOWN_DECLARE(engine_cooldown)
	///How many subversion attempts you can block
	var/antivirus_nodes = 0
	///How long you are immune to being subverted
	COOLDOWN_DECLARE(sub_grace)
	///Ship that is requesting to dock with you
	var/datum/overmap/ship/controlled/requesting_ship
	///prevent spamming
	COOLDOWN_DECLARE(request_cooldown)
	///prevent someone from sending docking requests to multiple ships and probably breaking the game
	var/sent_request = FALSE

/datum/overmap/ship
	///The current target for the autopiloting system
	var/atom/current_autopilot_target

//For uploading an antivirus
/obj/machinery/computer/helm/attackby(obj/item/O, mob/user, params)
	if (istype(O, /obj/item/disk/antivirus))
		current_ship.antivirus_nodes++
		playsound(loc, 'sound/misc/compiler-stage2.ogg', 90, 1, 0)
		say("Антивирус загружен в систему судна.")
		qdel(O)
	else
		return ..()

/obj/machinery/computer/helm/examine(mob/user)
	. = ..()
	. += "<hr><span class='notice'>It has [current_ship.antivirus_nodes] antiviral node[(current_ship.antivirus_nodes > 1) || (current_ship.antivirus_nodes == 0) ? "s" : ""] installed.</span>"

/**
*	Try to block a sub attempt. If successful, use up an antivirus node and return TRUE
*/
/datum/overmap/ship/controlled/proc/run_antivirus()
	. = FALSE
	if (antivirus_nodes > 0)
		antivirus_nodes--
		return TRUE

/**
*	You just survived a subversion, start the grace period and make the helm say something
*/
/datum/overmap/ship/controlled/proc/systems_restored()
	COOLDOWN_START(src, sub_grace, SHIP_GRACE_TIME)
	most_recent_helm.say("Управление восстановлено.")

//Prevent subverted ship from being able to do anything
/obj/machinery/computer/helm/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if (!COOLDOWN_FINISHED(current_ship, engine_cooldown))
		say("Ошибка управления!")
	else
		return ..()

/obj/machinery/computer/autopilot/ui_act(action, params)
	if (!COOLDOWN_FINISHED(ship, engine_cooldown))
		say("Вспомогательная консоль не отвечает!")
	else
		return ..()

/**
*	Used for request docking
*
*	mob/user - player who initiated the dock
*	datum/overmap/ship/controlled - ship that asked to dock
*/
/datum/overmap/ship/controlled/proc/duo_dock(mob/user, datum/overmap/ship/controlled/acting)
	var/datum/overmap/dynamic/empty/E
	E = locate() in SSovermap.overmap_container[x][y]
	if(!E)
		E = new(list("x" = x, "y" = y))
	if(E)
		Dock(E)

/**
*	New interaction for ships: request docking. This will send a request to the other ship's helm console
*	that will allow them to both dock in an empty space at the same time
*
*	mob/user - player who made the request
*	obj/structure/overmap/ship/simulated/acting - the requesting ship
*/
/datum/overmap/ship/controlled/proc/ship_act(mob/user, datum/overmap/ship/controlled/acting)
	if (acting.sent_request)
		acting.most_recent_helm.say("Запрос уже отправлен.")
		return
	if (requesting_ship)
		acting.most_recent_helm.say("Этот корабль уже обрабатывает запрос на стыковку.")
		return
	if (!COOLDOWN_FINISHED(acting, request_cooldown))
		acting.most_recent_helm.say("Подождите [num2text(COOLDOWN_TIMELEFT(acting, request_cooldown)/10)] секунд, прежде чем вы сможете запросить стыковку.")
		return
	/*if (state != OVERMAP_SHIP_FLYING)
		acting.most_recent_helm.say("The [name] is busy.")
		return
	if (acting.state != OVERMAP_SHIP_FLYING)
		acting.most_recent_helm.say("Must be in hyperspace to request docking.")
		return*/
	/*if (loc != acting.loc)
		acting.most_recent_helm.say("Not in docking range.")
		return*/
	var/poll_client = tgui_alert(usr, "Request to dock with [name]?", "Requesting dock", list("Yes", "No"))
	if (poll_client == "Yes")
		/*if (loc != acting.loc)
			acting.most_recent_helm.say("Too far to request docking.")
			return*/
		acting.sent_request = TRUE
		acting.most_recent_helm.say("Requested to dock with [name].")
		most_recent_helm.say("Docking request recieved from [acting.name].")
		playsound(most_recent_helm.loc, 'sound/machines/buzz-two.ogg', 90, 1, 0)
		requesting_ship = acting
		COOLDOWN_START(acting, request_cooldown, 10 SECONDS)


#undef SHIP_GRACE_TIME

/datum/overmap/ship/controlled/tick_autopilot()
	if(docked_to != null)
		return
	. = ..()
	if(!.) //Parent proc only returns TRUE when destination is reached.
		return
	Dock(current_autopilot_target)
	current_autopilot_target = null
