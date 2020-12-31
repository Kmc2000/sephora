
//Space Pirate ships go here

//AI versions

/obj/structure/overmap/spacepirate/ai
	name = "Space Pirate"
	desc = "A Space Pirate Vessel"
	icon = 'icons/obj/janitor.dmi'
	icon_state = "mop"
	faction = "pirate"
	mass = MASS_SMALL
	max_integrity = 400
	integrity_failure = 400
	armor = list("overmap_light" = 30, "overmap_heavy" = 10)
	ai_controlled = TRUE
	ai_behaviour = AI_AGGRESSIVE
	ai_trait = AI_TRAIT_DESTROYER //might need a custom trait here

/obj/structure/overmap/spacepirate/ai/Initialize()
	. = ..()
	name = "[name] ([rand(0,999)])" //pirate names go here
	var/random_appearance = pick(1,2,3,4,5)
	switch(random_appearance)
		if(1)
			icon_state = "mop"
		if(2)
			icon_state = "advmop"
		if(3)
			icon_state = "smmop"
		if(4)
			icon_state = "adv_smmop"
		if(5)
			icon_state = "broom0"

/obj/structure/overmap/spacepirate/ai/apply_weapons()
	var/random_weapons = pick(1, 2, 3, 4, 5)
	switch(random_weapons) //Dakkagang
		if(1)
			weapon_types[FIRE_MODE_PDC] = new /datum/ship_weapon/pdc_mount(src)
			weapon_types[FIRE_MODE_TORPEDO] = new /datum/ship_weapon/torpedo_launcher(src)
			weapon_types[FIRE_MODE_RAILGUN] = null
			weapon_types[FIRE_MODE_FLAK] = null
			weapon_types[FIRE_MODE_GAUSS] = null
			weapon_types[FIRE_MODE_MISSILE] = null
			weapon_types[FIRE_MODE_50CAL] = new /datum/ship_weapon/fiftycal(src)
			torpedoes = 10
		if(2)
			weapon_types[FIRE_MODE_PDC] = new /datum/ship_weapon/pdc_mount(src)
			weapon_types[FIRE_MODE_TORPEDO] = null
			weapon_types[FIRE_MODE_RAILGUN] = new /datum/ship_weapon/railgun(src)
			weapon_types[FIRE_MODE_FLAK] = null
			weapon_types[FIRE_MODE_GAUSS] = null
			weapon_types[FIRE_MODE_MISSILE] = null
			weapon_types[FIRE_MODE_50CAL] = new /datum/ship_weapon/fiftycal(src)
			shots_left = 10
		if(3)
			weapon_types[FIRE_MODE_PDC] = new /datum/ship_weapon/pdc_mount(src)
			weapon_types[FIRE_MODE_TORPEDO] = null
			weapon_types[FIRE_MODE_RAILGUN] = null
			weapon_types[FIRE_MODE_FLAK] = null
			weapon_types[FIRE_MODE_GAUSS] = new /datum/ship_weapon/gauss(src)
			weapon_types[FIRE_MODE_MISSILE] = null
			weapon_types[FIRE_MODE_50CAL] = new /datum/ship_weapon/fiftycal(src)
		if(4)
			weapon_types[FIRE_MODE_PDC] = new /datum/ship_weapon/pdc_mount(src)
			weapon_types[FIRE_MODE_TORPEDO] = null
			weapon_types[FIRE_MODE_RAILGUN] = null
			weapon_types[FIRE_MODE_FLAK] = null
			weapon_types[FIRE_MODE_GAUSS] = null
			weapon_types[FIRE_MODE_MISSILE] = new /datum/ship_weapon/missile_launcher(src)
			weapon_types[FIRE_MODE_50CAL] = new /datum/ship_weapon/fiftycal(src)
			missiles = 10
		if(5)
			weapon_types[FIRE_MODE_PDC] = new /datum/ship_weapon/pdc_mount(src)
			weapon_types[FIRE_MODE_TORPEDO] = null
			weapon_types[FIRE_MODE_RAILGUN] = null
			weapon_types[FIRE_MODE_FLAK] = new /datum/ship_weapon/flak(src)
			weapon_types[FIRE_MODE_GAUSS] = null
			weapon_types[FIRE_MODE_MISSILE] = null
			weapon_types[FIRE_MODE_50CAL] = new /datum/ship_weapon/fiftycal(src)
			flak_battery_amount = 1

/obj/structure/overmap/spacepirate/ai/boarding //our boarding capable variant (we want to control how many of these there are)
	ai_trait = AI_TRAIT_BOARDER

/obj/structure/overmap/spacepirate/ai/nt_missile
	name = "Space Pirate Missile Boat"
	desc = "This vessel appears to have been commandeered by the space pirates"
	icon_state = "mop"
	mass = MASS_SMALL
	sprite_size = 48
	damage_states = FALSE
	max_integrity = 1000
	integrity_failure = 1000
	armor = list("overmap_light" = 50, "overmap_heavy" = 10)
	ai_trait = AI_TRAIT_BATTLESHIP
	torpedoes = 20
	missiles = 20

/obj/structure/overmap/spacepirate/ai/nt_missile/apply_weapons()
	.=..()
	weapon_types[FIRE_MODE_GAUSS] = null //removed the guass to load more torp

/obj/structure/overmap/spacepirate/ai/syndie_gunboat
	name = "Space Pirate Gunboat"
	desc = "This vessel appears to have been commandeered by the space pirates"
	icon = 'nsv13/icons/overmap/new/nanotrasen/frigate.dmi'
	icon_state = "pirate_frigate"
	mass = MASS_MEDIUM
	sprite_size = 48
	damage_states = FALSE
	bound_width = 128
	bound_height = 128
	max_integrity = 700
	integrity_failure = 700
	shots_left = 20
	armor = list("overmap_light" = 50, "overmap_heavy" = 15)
	ai_trait = AI_TRAIT_DESTROYER

/obj/structure/overmap/spacepirate/ai/syndie_gunboat/apply_weapons()
	weapon_types[FIRE_MODE_PDC] = new /datum/ship_weapon/pdc_mount/aa_guns(src)
	weapon_types[FIRE_MODE_AMS] = null
	weapon_types[FIRE_MODE_TORPEDO] = null
	weapon_types[FIRE_MODE_RAILGUN] = null
	weapon_types[FIRE_MODE_FLAK] = new/datum/ship_weapon/flak(src)
	weapon_types[FIRE_MODE_GAUSS] = new /datum/ship_weapon/gauss(src)
	weapon_types[FIRE_MODE_MISSILE] = null
	weapon_types[FIRE_MODE_50CAL] = new /datum/ship_weapon/fiftycal(src)
	flak_battery_amount = 1

/obj/structure/overmap/spacepirate/ai/dreadnought //And you thought the pirates only had small ships
	name = "Space Pirate Dreadnought"
	desc = "Hoist the colours high"
	icon_state = "smmop"
	mass = MASS_TITAN
	sprite_size = 48
	damage_states = TRUE
	pixel_z = -350
	pixel_w = -150
	max_integrity = 10000
	integrity_failure = 10000
	shots_left = 35
	torpedoes = 35
	collision_positions = ""
	armor = list("overmap_light" = 90, "overmap_heavy" = 50)
	can_resupply = TRUE
	ai_trait = AI_TRAIT_SUPPLY

/obj/structure/overmap/spacepirate/ai/dreadnought/apply_weapons()
	weapon_types[FIRE_MODE_PDC] = new /datum/ship_weapon/pdc_mount/aa_guns(src)
	weapon_types[FIRE_MODE_TORPEDO] = new /datum/ship_weapon/torpedo_launcher(src)
	weapon_types[FIRE_MODE_MISSILE] = null
	weapon_types[FIRE_MODE_RAILGUN] = new /datum/ship_weapon/railgun(src)
	weapon_types[FIRE_MODE_FLAK] = new /datum/ship_weapon/flak(src)
	weapon_types[FIRE_MODE_GAUSS] = new /datum/ship_weapon/gauss(src)
