
/obj/machinery/computer/lore_terminal/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = FALSE, \
											datum/tgui/master_ui = null, datum/ui_state/state = GLOB.default_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "seegson", name, 500, 500, master_ui, state)
		ui.open()

/obj/machinery/computer/lore_terminal/attack_hand(mob/user)
	ui_interact(user)

/obj/machinery/computer/lore_terminal/ui_data(mob/user)
	var/list/data = list()
	data["Entries"] = list()
	data["Categories"] = list()
	for(var/datum/lore_entry/LE in GLOB.lore_terminal_controller.entries)
		if(!data["Categories"][LE.category])
			data["Categories"][LE.category] = LE.category

		var/list/info = list()
		info["name"] = LE.name
		info["id"] = "\ref[LE]"
		data["Entries"][++data["Entries"].len] = info
	return data