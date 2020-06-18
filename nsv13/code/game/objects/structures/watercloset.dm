/obj/structure/sink/ship
	name = "kitchen sink"
	icon = 'nsv13/icons/obj/watercloset.dmi'
	icon_state = "sink"
	desc = "A sink used for washing one's hands and face."
	var/filled = FALSE

/obj/structure/sink/ship/proc/reset_filled()
	filled = FALSE
	update_icon()

/obj/structure/sink/ship/update_icon()
	playsound('nsv13/sound/effects/sink.ogg', 100, TRUE)
	icon_state = (filled) ? "sink_full" : "sink"

/obj/structure/sink/ship/attack_hand(mob/living/user)
	. = ..()
	if(!filled)
		filled = TRUE
		update_icon()
		addtimer(CALLBACK(src, .proc/reset_filled), 1 MINUTES)

/obj/structure/sink/ship/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	if(!filled)
		filled = TRUE
		update_icon()
		addtimer(CALLBACK(src, .proc/reset_filled), 1 MINUTES)
