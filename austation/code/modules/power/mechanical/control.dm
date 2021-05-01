/obj/machinery/computer/motor
	name = "flywheel motor control console"
	desc = "A simple console used to control flywheel motors"
	icon_state = "oldcomp"
	icon_screen = "turbinecomp"
	icon_keyboard = null
	var/list/motors = list()
	var/automode = TRUE
	var/autoset = 0
	var/obj/effect/flywheel/flywheel
	var/M_ID = "lazy1"

/obj/machinery/computer/motor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(ui)
		return
	ui = new(user, src, "MotorControl")
	ui.open()

/obj/machinery/computer/motor/ui_act(action, params)
	if(..())
		return
	var/selected = params["target"]
	switch(action)
		if("input")
			if(automode)
				return
			var/obj/machinery/mechanical/power/motor/vroom = motors[target]
			if(!vroom)
				return
			var/input = clamp(text2num(params["desired_man"]), 0, vroom.capacity)
			vroom.current_amt = input
		if("toggle_auto")
			automode = !automode
		if("input_auto")
			var/input = max(text2num(params["desired_auto"]), 0)
			autoset = input

/obj/machinery/computer/motor/ui_data(mob/user)
	var/list/data = list()
	data["motors"] = list()
	data["rpm"] = 0
	data["max_rpm"] = 0
	data["auto"] = automode
	data["auto_amt"] = autoset
	if(flywheel)
		data["motors"] = motors
		data["rpm"] = flywheel.rpm
		data["max_rpm"] = flywheel.bearing.max_rpm
	return data

// for handling auto
/obj/machinery/computer/motor/process()
	if(!automode || (stat & BROKEN) || !motors.len || !flywheel)
		return
	for(var/obj/machinery/mechanical/power/motor/MO in motors)
		if(is_satisfied())
			return
		MO.current_amt = clamp(auto_remaining(), 0, MO.capacity)

/// Gets the energy difference between the current level and the target level
/obj/machinery/computer/motor/proc/auto_remaining()
	return autoset - flywheel.get_energy() / GLOB.CELLRATE

// ------ Generator ------

/obj/machinery/computer/motor/generator
	name = "flywheel output control console"
	desc = "A simple console use to control flywheel electric generators"
	icon_screen = "recharge_comp"

/obj/machinery/computer/motor/generator/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(ui)
		return
	ui = new(user, src, "GeneratorControl")
	ui.open()

/obj/machinery/computer/motor/auto_remaining()
	return flywheel.get_energy() / GLOB.CELLRATE - autoset
