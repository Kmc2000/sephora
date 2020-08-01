/**

Looking for weaknesses in our core structure here will yield you nothing. Do not resist further.

*/

#define TRAIT_OBSOLESCENT "obsolescent_drone"
#define OBSOLESCENT_TRAIT "obsolescent_trait"
#define GET_OBSOLESCENT_TAUNT pick('nsv13/sound/voice/obsolescents/culture.ogg', 'nsv13/sound/voice/obsolescents/service_us.ogg','nsv13/sound/voice/obsolescents/augmentation.ogg', 'nsv13/sound/voice/obsolescents/donotresist.ogg', 'nsv13/sound/voice/obsolescents/deletion.ogg')
#define GET_BULLET_DING pick('nsv13/sound/effects/ship/freespace2/ding1.wav','nsv13/sound/effects/ship/freespace2/ding2.wav','nsv13/sound/effects/ship/freespace2/ding3.wav','nsv13/sound/effects/ship/freespace2/ding4.wav','nsv13/sound/effects/ship/freespace2/ding5.wav')
#define isobsolescent(A) (HAS_TRAIT(A, TRAIT_OBSOLESCENT))
#define RADIO_OBSOLESCENTS "obsolescents_collective"
#define FREQ_OBSOLESCENTS 666

//'nsv13/sound/effects/ship/freespace2/debris.wav' Revival sound!

/datum/outfit/obsolescent
	name = "Obsolescent drone"
	uniform = /obj/item/clothing/under/abductor
	mask = /obj/item/clothing/mask/gas/obsolescent
	shoes = /obj/item/clothing/shoes/combat
	suit = /obj/item/clothing/suit/space/obsolescent
	head = /obj/item/clothing/head/helmet/space/obsolescent
	r_hand = /obj/item/melee/obsolescent
	id = /obj/item/card/id

/datum/outfit/obsolescent/equip(mob/living/carbon/human/H, visualsOnly)
	. = ..()
	var/obj/item/organ/emotional_inhibitor/noSOUL = new /obj/item/organ/emotional_inhibitor(H)
	noSOUL.Insert(H)

/obj/item/clothing/mask/gas/obsolescent
	name = "Facial Shroud"
	desc = "A collection of bandages to hide the mangled face of the person beneath it."
	icon_state = "mummy_mask"
	item_state = "mummy_mask"
	breathing_sound = FALSE
	resistance_flags = FIRE_PROOF | ACID_PROOF //You never lose the shroud.

/obj/item/clothing/mask/gas/obsolescent/Initialize()
	. = ..()
	soundloop = new /datum/looping_sound/gasmask/obsolescent(list(src), FALSE)

/obj/item/organ/emotional_inhibitor
	name = "Emotional inhibitor"
	desc = "Such a device is painfully implanted into an obsolescent drone to keep its mind from realizing what a monstrosity of a body it lives in."
	icon_state = "brain_implant"
	var/datum/radio_frequency/radio_connection

/obj/item/organ/emotional_inhibitor/Initialize()
	. = ..()
	if(!radio_connection)
		radio_connection = SSradio.add_object(src, FREQ_OBSOLESCENTS, RADIO_OBSOLESCENTS)

/obj/item/organ/emotional_inhibitor/receive_signal(datum/signal/signal)
	if(!signal.data["message"])
		return
	if(owner && isobsolescent(owner))
		var/msg = signal.data["message"]
		to_chat(owner, msg)

/obj/item/organ/emotional_inhibitor/Insert(mob/living/carbon/M, special, drop_if_replaced)
	. = ..()
	M.make_obsolescent()

/obj/item/organ/emotional_inhibitor/Remove(mob/living/carbon/M, special)
	. = ..()
	M.remove_obsolescent()

/datum/looping_sound/gasmask/obsolescent
	mid_sounds = list('nsv13/sound/effects/obsolescent_breath.ogg')
	mid_length = 20 SECONDS
	volume = 100

/obj/item/clothing/mask/gas/obsolescent/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, LOCKED_HELMET_TRAIT)

/obj/item/clothing/suit/space/obsolescent
	name = "Exoskeleton"
	desc = "Encases weak biologics."
	icon = 'nsv13/icons/obj/clothing/suits.dmi'
	alternate_worn_icon = 'nsv13/icons/mob/suit.dmi'
	icon_state = "obsolescent"
	item_state = "obsolescent"
	body_parts_covered = CHEST
	cold_protection = CHEST|GROIN
	min_cold_protection_temperature = ARMOR_MIN_TEMP_PROTECT
	heat_protection = CHEST|GROIN
	max_heat_protection_temperature = ARMOR_MAX_TEMP_PROTECT
	slowdown = 4
	strip_delay = 60
	equip_delay_other = 40
	max_integrity = 250
	armor = list("melee" = 40, "bullet" = 98, "laser" = 50, "energy" = 30, "bomb" = 10, "bio" = 100, "rad" = 100, "fire" = 60, "acid" = 60)
	var/mob/listeningTo = null
	var/stomp_cooldown_time = 0.3 SECONDS
	var/current_cooldown = 0

/obj/item/clothing/suit/space/obsolescent/proc/on_mob_move()
	var/mob/living/carbon/human/H = loc
	if(!istype(H) || H.wear_suit != src)
		return
	if(current_cooldown <= world.time) //Deliberately not using a timer here as that would spam create tonnes of timer objects, hogging memory.
		current_cooldown = world.time + stomp_cooldown_time
		playsound(src, 'nsv13/sound/effects/obsolescent_step.ogg', 50, TRUE)

/obj/item/clothing/suit/space/obsolescent/equipped(mob/user, slot)
	. = ..()
	if(slot != SLOT_WEAR_SUIT)
		if(listeningTo)
			UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
		return
	if(listeningTo == user)
		return
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, .proc/on_mob_move)
	listeningTo = user

/obj/item/clothing/suit/space/obsolescent/dropped()
	. = ..()
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)

/obj/item/clothing/suit/space/obsolescent/hit_reaction(mob/living/carbon/human/owner, atom/movable/hitby, attack_text = "the attack", final_block_chance = 0, damage = 0, attack_type = MELEE_ATTACK)
	. = ..()
	playsound(src.loc, GET_BULLET_DING, 100, TRUE)

/obj/item/clothing/suit/space/obsolescent/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, NINJA_SUIT_TRAIT)

//You will find no help here.

/datum/action/item_action/obsolescent_transmit
	name = "Message Collective"

/datum/action/item_action/obsolescent_taunt
	name = "Voice Synthesiser"

/obj/item/clothing/head/helmet/space/obsolescent
	name = "Cranial mount"
	desc = "Past identities are to be forgotten."
	icon = 'nsv13/icons/obj/clothing/hats.dmi'
	alternate_worn_icon = 'nsv13/icons/mob/head.dmi'
	icon_state = "obsolescent"
	item_state = "obsolescent"
	item_color = "obsolescent"
	armor = list("melee" = 20, "bullet" = 98, "laser" = 10, "energy" = 10, "bomb" = 70, "bio" = 100, "rad" = 100, "fire" = 60, "acid" = 100)
	resistance_flags = FIRE_PROOF
	heat_protection = HEAD
	max_heat_protection_temperature = FIRE_IMMUNITY_MAX_TEMP_PROTECT
	var/datum/radio_frequency/radio_connection = null
	actions_types = list(/datum/action/item_action/obsolescent_transmit, /datum/action/item_action/obsolescent_taunt)
	var/next_taunt = 0
	var/next_message = 0

/obj/item/clothing/head/helmet/space/obsolescent/ui_action_click(mob/user, action)
	if(istype(action, /datum/action/item_action/obsolescent_transmit))
		message_collective(user)
	if(istype(action, /datum/action/item_action/obsolescent_taunt))
		taunt()

/obj/item/clothing/head/helmet/space/obsolescent/proc/taunt()
	if(world.time < next_taunt)
		return
	next_taunt = world.time + 10 SECONDS
	playsound(src.loc, GET_OBSOLESCENT_TAUNT, 100, FALSE)

/obj/item/clothing/head/helmet/space/obsolescent/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, LOCKED_HELMET_TRAIT)
	if(!radio_connection)
		radio_connection = SSradio.add_object(src, FREQ_OBSOLESCENTS, RADIO_OBSOLESCENTS)

/obj/item/clothing/head/helmet/space/obsolescent/proc/message_collective(mob/user)
	if(!isobsolescent(user))
		return FALSE
	if(world.time < next_message)
		return
	next_message = world.time + 2 SECONDS
	var/message = stripped_input(user, "Message the collective:", "[name]", "", MAX_MESSAGE_LEN)
	if(!message)
		return FALSE

	message = "<span class='binarysay'><b>\[Obsolescent collective\]</b> [user.real_name]: [message]</span>"
	var/datum/signal/signal = new(list("message" = message))
	for(var/mob/M in GLOB.dead_mob_list)
		var/link = FOLLOW_LINK(M, user)
		to_chat(M, "[link] [message]")
	radio_connection.post_signal(src, signal, filter = RADIO_OBSOLESCENTS)

//Distribute the following equipment amongst all drones.

/obj/item/melee/obsolescent
	name = "Prosthetic"
	desc = "Refactor them until they conform."
	icon = 'nsv13/icons/obj/machines/soul_sucker.dmi'
	icon_state = "prosthetic"
	item_state = "obsolescent"
	lefthand_file = 'nsv13/icons/mob/inhands/weapons/melee_lefthand.dmi'
	righthand_file = 'nsv13/icons/mob/inhands/weapons/melee_righthand.dmi'
	flags_1 = CONDUCT_1
	attack_verb = list("slammed", "punted", "cracked")
	force = 18
	attack_weight = 1
	throwforce = 10
	throw_range = 2
	w_class = WEIGHT_CLASS_NORMAL
	armor = list("melee" = 0, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 100, "acid" = 40)
	resistance_flags = FIRE_PROOF
	var/next_delimb = 0
	var/material_stored = 0
	var/max_material = 1000 //Already a bit nuts
	var/cost_per_build = 100 //10 sheets of whatever material.

/obj/item/melee/obsolescent/proc/check_menu(mob/living/user)
	if(!istype(user))
		return FALSE
	if(user.incapacitated() || !isobsolescent(user) || material_stored < cost_per_build)
		return FALSE
	return TRUE

/obj/item/melee/obsolescent/attackby(obj/item/I, mob/living/user, params)
	. = ..()
	if(material_stored >= max_material)
		to_chat(user, "<span class='notice'>[src] is full.</span>")
		return
	if(istype(I, /obj/item/stack/sheet))
		var/obj/item/stack/sheet/S = I
		var/inputAmount = input(user, "How much of [I] do you want to input into [src]?", "Num", null) as null|num
		if(!inputAmount)
			return
		inputAmount = CLAMP(inputAmount, 0, S.get_amount())
		if(inputAmount <= 0)
			return
		S.use(inputAmount)
		material_stored += inputAmount * 10
		material_stored = CLAMP(material_stored, 0, max_material)
		to_chat(user, "<span class='notice'>You slot [inputAmount] sheets of [I] into [src]...</span>")

/obj/item/melee/obsolescent/examine(mob/user)
	. = ..()
	. += "<span class='notice'>It has [material_stored] units of material stored, and takes <b>[cost_per_build]</b> units to create structures."

/obj/item/melee/obsolescent/attack_self(mob/user)
	. = ..()
	if(!isobsolescent(user))
		return
	if(material_stored < cost_per_build)
		to_chat(user, "<span class='warning'>Insufficient materials ([material_stored] / [cost_per_build] U)")
		return
	var/list/options = list(
		"conversion chamber" = image(icon = 'nsv13/icons/obj/machines/soul_sucker.dmi', icon_state = "soulremover"),
		"prosthetic vendor" = image(icon = 'nsv13/icons/obj/machines/soul_sucker.dmi', icon_state = "geargiver"),
		"maturation chamber" = image(icon = 'nsv13/icons/obj/machines/soul_sucker.dmi', icon_state = "maturation_0"),
		"cyberbite" = image(icon = 'nsv13/icons/mob/animal.dmi', icon_state = "minisoulsucker")
		)
	var/chosenGear = show_radial_menu(user, src, options, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return
	var/machinePath = null
	switch(chosenGear)
		if("conversion chamber")
			machinePath = /obj/machinery/obsolescent_conversion
		if("prosthetic vendor")
			machinePath = /obj/machinery/obsolescent_gear
		if("maturation chamber")
			machinePath = /obj/machinery/obsolescent_maturation
		if("cyberbite")
			machinePath = /mob/living/simple_animal/hostile/obsolescent_rat
	if(!machinePath)
		return
	playsound(src, 'nsv13/sound/effects/obsolescent_build.ogg', 100, TRUE)
	if(!do_after(user, 5 SECONDS, target=get_turf(src)) || !check_menu(user))
		return FALSE
	new machinePath(get_turf(user))
	material_stored -= cost_per_build

/obj/item/melee/obsolescent/Initialize()
	. = ..()
	ADD_TRAIT(src, TRAIT_NODROP, GLUED_ITEM_TRAIT)

/obj/item/melee/obsolescent/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(world.time < next_delimb || !proximity_flag)
		return ..()
	if(istype(target, /obj/structure/window))
		visible_message("<span class='warning'>[user] punches clean through [target] with [src]!</span>")
		target.shake_animation(5)
		playsound(src, 'sound/effects/bang.ogg', 50, 1)
		sleep(0.2)
		qdel(target)
		next_delimb = world.time + 5 SECONDS
	if(istype(target, /turf/closed/wall))
		visible_message("<span class='warning'>[user] slams [target] with an immense force!</span>")
		playsound(src, 'sound/effects/meteorimpact.ogg', 100, 1)
		target.shake_animation(7)
		if(prob(40))
			var/turf/closed/wall/W = target
			W.dismantle_wall(1)
			var/atom/movable/girder = new /obj/structure/girder/displaced(W)
			var/atom/throw_target = get_edge_target_turf(girder, user.dir)
			girder.throw_at(throw_target, rand(2,7), rand(3,6))
			visible_message("<span class='warning'>[girder] is thrown away with a huge force!</span>")
			next_delimb = world.time + 5 SECONDS
			playsound(src, 'nsv13/sound/voice/obsolescents/obstruction.ogg', 100, FALSE)

/obj/item/melee/obsolescent/attack(mob/living/M, mob/living/user)
	. = ..()
	if(world.time >= next_delimb)
		if(!iscarbon(M))
			return
		if(user.grab_state < GRAB_AGGRESSIVE)
			user.start_pulling(M, supress_message = FALSE)
			user.setGrabState(GRAB_AGGRESSIVE)
			M.Paralyze(7.5 SECONDS) //Longer than a clown PDA
			playsound(src, 'sound/items/jaws_pry.ogg', 100, TRUE)
			var/list/all_items = M.GetAllContents()
			for(var/obj/I in all_items)
				if(istype(I, /obj/item/radio/))
					var/obj/item/radio/r = I
					r.listening = FALSE
					if(!istype(I, /obj/item/radio/headset))
						r.broadcasting = FALSE
		else
			if(!iscarbon(user.pulling))
				return
			var/mob/living/carbon/H = user.pulling
			var/list/blacklist = H.get_missing_limbs()
			var/list/full = list(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG) //You can't rip their chest or head off.
			for(var/X in full)
				if(X in blacklist)
					full -= X
			if(!full.len)
				return
			var/obj/item/bodypart/affecting = H.get_bodypart(pick(full))
			to_chat(user, "<span class='danger'><B>[user] rips [H]'s [affecting] off!</B></span>")
			playsound(src, 'nsv13/sound/effects/obsolescent_rip.ogg', 80, FALSE)
			affecting.dismember(damtype)
			H.shake_animation(7)
			affecting.shake_animation(7)
			H.emote("scream")
			H.update_damage_overlays()
			to_chat(user, "<span class='boldnotice'>Servos recharging. Full power will be regained in 5 seconds.</span>")
			next_delimb = world.time + 5 SECONDS

/mob/living/carbon/proc/remove_obsolescent()
	REMOVE_TRAIT(src, TRAIT_OBSOLESCENT, OBSOLESCENT_TRAIT)

//Conversion

/datum/disease/advance/obsolescent
	name = "Blight of the obsolescents"
	mutable = TRUE
	form = "Unknown"
	agent = "Nanotechnology"
	symptoms = list(new /datum/symptom/vitiligo, new /datum/symptom/heal/coma, new /datum/symptom/nano_destroy, new /datum/symptom/viraladaptation, new /datum/symptom/oxygen/obsolescent)

/datum/antagonist/obsolescent
	name = "Obsolescent drone"
	antagpanel_category = "Obsolescents"
	roundend_category = "obsolescent drones"

/datum/antagonist/obsolescent/greet()
	to_chat(owner, "<B><font size=3 color=red>We are an [name].</font></B>")
	to_chat(owner, "<span class='boldnotice'>The lifeforms of this vessel are of little concern to the collective. If they obstruct you in any way, convert them and add their being to the collective. <br/>\
	Acquire prosthetics and proceed with ship system conversion. [station_name()]'s FTL drive must be upgraded to allow us to transport it to the rest of the collective. <br/>\
	Resistance is ill-advised.</span>")

//We do not breathe.
/datum/symptom/oxygen/obsolescent
	name = "Automated life-support"
	resistance = 0
	stage_speed = 0
	emote = "gasp"
	regenerate_blood = TRUE

/obj/machinery/obsolescent_conversion
	name = "conversion chamber"
	desc = "You will be upgraded."
	icon = 'nsv13/icons/obj/machines/soul_sucker.dmi'
	icon_state = "soulremover"
	density = TRUE
	anchored = TRUE
	initial_language_holder = /datum/language_holder/obsolescent
	var/ready = TRUE
	var/conversion_delay = 30 SECONDS
	var/mob/living/carbon/conversion_target = null

/obj/machinery/obsolescent_conversion/MouseDrop_T(mob/living/carbon/M, mob/living/user)
	. = ..()
	if(!iscarbon(M) || isobsolescent(M))
		return
	if(conversion_target || !ready)
		return
	for(var/zone in list(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG))
		if(M.get_bodypart(zone))
			to_chat(user, "<span class='boldwarning'>Subject [M] has not been properly prepared for upgrading. Remove the subject's limbs before using this machine.</span>")
			return FALSE
	if(!do_after(user, 5 SECONDS, target=src) || !Adjacent(user))
		return FALSE
	conversion_target = M
	cut_overlays()
	add_overlay("door")
	conversion_target.forceMove(src)
	conversion_target.Paralyze(25 SECONDS)
	playsound(src, 'nsv13/sound/voice/obsolescents/conversion.ogg', 100, FALSE)
	say("Beginning conversion. All non-viable stock will be incinerated.")
	sleep(7 SECONDS)
	playsound(src, 'nsv13/sound/effects/obsolescent_conversion.ogg', 100, FALSE)
	sleep(7 SECONDS)
	var/obj/item/organ/emotional_inhibitor/noSOUL = new /obj/item/organ/emotional_inhibitor(M)
	noSOUL.Insert(M)
	var/obj/item/organ/cyberimp/chest/nutriment/plus/scream = new /obj/item/organ/cyberimp/chest/nutriment/plus(M)
	scream.Insert(M)
	var/obj/item/organ/eyes/robotic/xray/newEyes = new /obj/item/organ/eyes/robotic/xray(M)
	newEyes.Insert(M)
	sleep(2 SECONDS)
	M.revive(TRUE, FALSE)
	M.forceMove(get_turf(src))
	say("Conversion chamber now closed for sterilisation...")
	playsound(src, 'nsv13/sound/voice/obsolescents/sterilisation.ogg', 100, FALSE)
	new /obj/effect/gibspawner/human(get_turf(src))
	conversion_target = null
	cut_overlays()
	add_overlay("fat_smoke")
	add_overlay("recharging")
	addtimer(CALLBACK(src, .proc/sterilise), conversion_delay)

/obj/machinery/obsolescent_conversion/proc/sterilise()
	cut_overlays()
	ready = TRUE
	playsound(src, 'nsv13/sound/voice/obsolescents/chamberopen.ogg', 100, FALSE)

#define OBSOLESCENT_PREFIXES list("Unimatrix", "Node", "Drone", "Unit", "Subprocessor", "Subjunction", "Terminus", "Network", "Machine")

/datum/language_holder/obsolescent
	only_speaks_language = /datum/language/machine
	languages = list(/datum/language/machine)

/mob/living/carbon/proc/make_obsolescent()
	fully_replace_character_name(real_name, "[pick(OBSOLESCENT_PREFIXES)] [rand(0, 999)]")
	mind?.add_antag_datum(/datum/antagonist/obsolescent)
	language_holder	= new /datum/language_holder/obsolescent(src) //We do not care to learn your languages.
	var/datum/disease/advance/obsolescent_virus = new /datum/disease/advance/obsolescent()
	obsolescent_virus.try_infect(src)
	ADD_TRAIT(src, TRAIT_OBSOLESCENT, OBSOLESCENT_TRAIT)
	if(ishuman(src))
		var/mob/living/carbon/human/H = src
		H.skin_tone = "albino"
		H.update_body(0)
	for(var/limb_slot in list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
		var/obj/item/bodypart/prosthetic = null
		switch(limb_slot)
			if(BODY_ZONE_L_ARM)
				prosthetic = new/obj/item/bodypart/l_arm/robot(src)
			if(BODY_ZONE_R_ARM)
				prosthetic = new/obj/item/bodypart/r_arm/robot(src)
			if(BODY_ZONE_L_LEG)
				prosthetic = new/obj/item/bodypart/l_leg/robot(src)
			if(BODY_ZONE_R_LEG)
				prosthetic = new/obj/item/bodypart/r_leg/robot(src)
		prosthetic.replace_limb(src)

/obj/machinery/obsolescent_gear
	name = "Prosthetic attacher"
	desc = "It has a limb sized slot in it and several gears."
	icon = 'nsv13/icons/obj/machines/soul_sucker.dmi'
	icon_state = "geargiver"
	density = TRUE
	anchored = TRUE
	initial_language_holder = /datum/language_holder/obsolescent
	var/material_amount = 0
	var/next_gear_collection = 0

/obj/machinery/obsolescent_gear/proc/check_menu(mob/living/user)
	if(!istype(user))
		return FALSE
	if(user.incapacitated() || !user.Adjacent(src) || !isobsolescent(user))
		return FALSE
	return TRUE

/obj/machinery/obsolescent_gear/attack_hand(mob/living/user)
	. = ..()
	if(world.time < next_gear_collection)
		return
	next_gear_collection = world.time + 2.5 SECONDS
	var/list/options = list(
		"prosthetic" = image(icon = 'nsv13/icons/obj/machines/soul_sucker.dmi', icon_state = "prosthetic"),
		"cranial_mount" = image(icon = 'nsv13/icons/obj/clothing/hats.dmi', icon_state = "obsolescent"),
		"shroud" = image(icon = 'icons/obj/clothing/masks.dmi', icon_state = "mummy_mask"),
		"suit" = image(icon = 'nsv13/icons/obj/clothing/suits.dmi', icon_state = "obsolescent")
		)
	var/chosenGear = show_radial_menu(user, src, options, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return
	var/gear_type = null
	var/slot = null
	switch(chosenGear)
		if("prosthetic")
			gear_type = /obj/item/melee/obsolescent
			slot = "hands"
		if("cranial_mount")
			gear_type = /obj/item/clothing/head/helmet/space/obsolescent
			slot = SLOT_HEAD
		if("shroud")
			gear_type = /obj/item/clothing/mask/gas/obsolescent
			slot = SLOT_WEAR_MASK
		if("suit")
			gear_type = /obj/item/clothing/suit/space/obsolescent
			slot = SLOT_WEAR_SUIT
	var/obj/item/gear = new gear_type(src)
	if(slot == "hands")
		if(!user.put_in_hands(gear))
			qdel(gear)
			say("Unable to apply prosthetic. Ensure selected zone is free from obstruction.")
			return FALSE
		playsound(src,'sound/weapons/drill.ogg',80,1)
		return TRUE
	if(user.equip_to_slot_if_possible(gear, slot))
		playsound(src,'sound/weapons/drill.ogg',80,1)
		return TRUE
	else
		qdel(gear)
		say("Unable to apply prosthetic. Ensure selected zone is free from obstructions.")

/obj/machinery/obsolescent_maturation
	name = "Maturation chamber"
	desc = "A machine used to grow human foetuses primed for conversion using advanced genetic manipulation techniques to minimize wasted stock. <b>It requires biomass from corpses and power to operate.</b>"
	icon = 'nsv13/icons/obj/machines/soul_sucker.dmi'
	icon_state = "maturation_0"
	density = TRUE
	anchored = TRUE
	initial_language_holder = /datum/language_holder/obsolescent
	var/cost_per_growth = 25
	var/growth_progress = 0
	var/next_growth_progression = 0
	var/datum/radio_frequency/radio_connection

/obj/machinery/obsolescent_maturation/MouseDrop_T(mob/living/M, mob/living/user)
	. = ..()
	if(!isobsolescent(user))
		return FALSE
	if(isobsolescent(M) && M.stat != DEAD)
		to_chat(user, "<span class='warning'>This drone is still operable. Aborting biomass reclamation.</span>")
		return
	user.visible_message("<span class='warning'>[user] starts to stuff [M] inside of [src]!</span>")
	if(!do_after(user, 10 SECONDS, target=src) || !Adjacent(M))
		return FALSE
	M.forceMove(get_turf(src))
	M.gib()
	reagents.add_reagent(/datum/reagent/medicine/synthflesh, 100)
	say("Biomass accepted. Livestock production will begin automatically.")

/obj/machinery/obsolescent_maturation/Initialize()
	. = ..()
	add_overlay("window")
	create_reagents(100, OPENCONTAINER)
	if(!radio_connection)
		radio_connection = SSradio.add_object(src, FREQ_OBSOLESCENTS, RADIO_OBSOLESCENTS)

/obj/machinery/obsolescent_maturation/process()
	if(!is_operational())
		return
	if(!reagents.has_reagent(/datum/reagent/medicine/synthflesh, cost_per_growth))
		return FALSE
	if(world.time >= next_growth_progression)
		growth_progress += cost_per_growth
		reagents.remove_reagent(/datum/reagent/medicine/synthflesh, cost_per_growth)
		next_growth_progression = world.time + 1 MINUTES
		playsound(src,pick('nsv13/sound/effects/obsolescent_maturation_1.ogg', 'nsv13/sound/effects/obsolescent_maturation_2.ogg'),80,TRUE)
		visible_message("<span class='boldwarning'>[pick("Something is squirming around inside of [src]...", "You can hear a frantic crying sound as something kicks around inside of [src]", "You can hear a faint crying sound coming from [src].")]</span>")
		if(prob(20))
			shake_animation(1)
		update_icon()
	if(growth_progress >= 100)
		make_baby()

/obj/machinery/obsolescent_maturation/proc/make_baby()
	var/message = "<span class='binarysay'><b>\[Obsolescent collective\]</b> [src]: Growth acceleration cycle complete. Releasing newly formed drone.</span>"
	var/datum/signal/signal = new(list("message" = message))
	for(var/mob/M in GLOB.dead_mob_list)
		var/link = FOLLOW_LINK(M, src)
		to_chat(M, "[link] [message]")
	radio_connection.post_signal(src, signal, filter = RADIO_OBSOLESCENTS)
	growth_progress = 0
	next_growth_progression = world.time + 1 MINUTES
	var/mob/living/carbon/human/H = new /mob/living/carbon/human(get_turf(src))
	playsound(src, 'nsv13/sound/effects/obsolescent_scream.ogg', 100, FALSE)
	for(var/zone in list(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_R_LEG, BODY_ZONE_L_LEG))
		var/obj/item/bodypart/affecting = H.get_bodypart(zone)
		if(affecting)
			affecting.dismember(damtype)
	H.skin_tone = "albino"
	new /obj/effect/gibspawner/human(get_turf(src))
	H.visible_message("<span class='boldwarning'>[H] screams in agony as their limbs fall off! </span>")
	update_icon()
	offer_control(H)

/obj/machinery/obsolescent_maturation/update_icon()
	icon_state = "maturation_[growth_progress]"

//You cannot hide from our sight.

/mob/living/simple_animal/hostile/obsolescent_rat
	name = "cyberbite"
	desc = "A small worm like creature with wheels, it has two electrical prongs in its mouth...."
	icon = 'nsv13/icons/mob/animal.dmi'
	icon_state = "minisoulsucker"
	icon_living = "minisoulsucker"
	icon_dead = "minisoulsucker_dead"
	gender = NEUTER
	health = 100
	maxHealth = 100
	melee_damage = 5
	attacktext = "nips"
	attack_sound = 'sound/weapons/bite.ogg'
	faction = list("creature")
	obj_damage = 5
	environment_smash = ENVIRONMENT_SMASH_NONE
	speak_emote = list("chirrups")
	ventcrawler = VENTCRAWLER_ALWAYS
	initial_language_holder = /datum/language_holder/obsolescent
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = 1500
	movement_type = FLYING
	pressure_resistance = 200
	sight = SEE_MOBS
	see_in_dark = 4
	var/next_stun = 0
	var/datum/radio_frequency/radio_connection
	var/next_message = 0

/mob/living/simple_animal/hostile/obsolescent_rat/Initialize()
	. = ..()
	offer_control(src)
	if(!radio_connection)
		radio_connection = SSradio.add_object(src, FREQ_OBSOLESCENTS, RADIO_OBSOLESCENTS)

/mob/living/simple_animal/hostile/obsolescent_rat/AttackingTarget()
	. = ..()
	if(world.time >= next_stun && isliving(target))
		var/mob/living/L = target
		playsound(src, 'sound/weapons/taser.ogg', 100, TRUE)
		visible_message("<span class='warning'>[src] stabs [target] with its prongs!")
		L.Knockdown(4 SECONDS)
		next_stun = world.time + 5 SECONDS
	else
		to_chat(src, "<span class='warning'>Electrodes recharging!</span>")

/mob/living/simple_animal/hostile/obsolescent_rat/verb/communicate()
	set name = "Communicate"
	set category = "Hivemind"
	if(world.time < next_message)
		return
	next_message = world.time + 2 SECONDS
	var/message = stripped_input(src, "Message the collective:", "[name]", "", MAX_MESSAGE_LEN)
	if(!message)
		return FALSE

	message = "<span class='binarysay'><b>\[Obsolescent collective\]</b> [src.name]: [message]</span>"
	var/datum/signal/signal = new(list("message" = message))
	for(var/mob/M in GLOB.dead_mob_list)
		var/link = FOLLOW_LINK(M, src)
		to_chat(M, "[link] [message]")
	radio_connection.post_signal(src, signal, filter = RADIO_OBSOLESCENTS)

/mob/living/simple_animal/hostile/obsolescent_rat/proc/receive_signal(datum/signal/signal)
	say("Sasdasxc")
	if(!signal.data["message"])
		return
	say("The game! Wahoo!")
	var/msg = signal.data["message"]
	to_chat(src, msg)
