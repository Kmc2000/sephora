/////////////////////////////////////////////////////////////////////////
// ACKNOWLEDGEMENTS:  Credit to yogstation (Monster860) for this code. //
// I had no part in writing this movement engine, that's his work      //
/////////////////////////////////////////////////////////////////////////

/obj/vector_overlay
	name = "Vector overlay for overmap ships"
	desc = "Report this to a coder"
	icon = 'nsv13/icons/overmap/thrust_vector.dmi'
	icon_state = "thrust_low"
	mouse_opacity = FALSE
	alpha = 0
	layer = WALL_OBJ_LAYER

/**

ATTENTION ADMINS. This proc is important, EXTREMELY important. In fact, welcome to your new religion.

This proc is to be used when someone gets stuck in an overmap ship, gauss, WHATEVER. You should no longer have to use the ancient chimp technique to unfuck people, use this instead, way cleaner, AND no monkies to boot!

*/
#define VV_HK_UNFUCK_OVERMAP "unFuckOvermap"

/mob/living/proc/unfuck_overmap()
	if(overmap_ship)
		overmap_ship.stop_piloting(src)
	for(var/datum/action/innate/camera_off/overmap/fuckYOU in actions)
		if(!istype(fuckYOU))
			continue
		qdel(fuckYOU) //Because this is a thing. Sure. Ok buddy.
	sleep(1) //Ok, are they still scuffed? Time to manually fix them...
	if(!overmap_ship)
		return //OK cool we're done here.
	remote_control = null
	overmap_ship = null
	cancel_camera()
	focus = src
	if(!client)
		return //Early return instead of possibly making 4 worthless reads. Is this a dumb microopt? Yes.
	client.pixel_x = 0
	client.pixel_y = 0
	client.overmap_zoomout = 0
	client.view_size.resetToDefault()

/mob/living/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION(VV_HK_UNFUCK_OVERMAP, "Unfuck Overmap")

/mob/living/vv_do_topic(list/href_list)
	. = ..()
	if(href_list[VV_HK_UNFUCK_OVERMAP])
		if(!check_rights(NONE))
			return
		unfuck_overmap()

//Helper proc to get the actual center of the ship, if the ship's hitbox is placed in the bottom left corner like they usually are.

/obj/structure/overmap/proc/get_center()
	return get_turf(locate((src.x+(pixel_collision_size_x/32)/2), src.y+((pixel_collision_size_y/32)/2), z))

/obj/structure/overmap/proc/get_pixel_bounds()
	for(var/turf/T in obounds(src, pixel_x + pixel_collision_size_x/4, pixel_y + pixel_collision_size_y/4, pixel_x  + -pixel_collision_size_x/4, pixel_y + -pixel_collision_size_x/4) )//Forms a zone of 4 quadrants around the desired overmap using some math fuckery.
		to_chat(world, "FOO!")
		T.SpinAnimation()

/obj/structure/overmap/proc/show_bounds()
	for(var/turf/T in locs)
		T.SpinAnimation()

/obj/effect/overmap_hitbox_marker
	name = "Hitbox display"
	icon = 'nsv13/icons/overmap/default.dmi'
	icon_state = "hitbox_marker"

/obj/effect/overmap_hitbox_marker/Initialize(mapload, pixel_x, pixel_y, pixel_z, pixel_w)
	. = ..()
	src.pixel_x = pixel_x
	src.pixel_y = pixel_y
	src.pixel_z = pixel_z
	src.pixel_w = pixel_w

//Method to show the hitbox of your current ship to see if youve set it up correctly
/obj/structure/overmap/proc/display_hitbox()
	if(!collision_positions.len)
		return

	for(var/datum/vector2d/point in collision_positions)
		var/obj/effect/overmap_hitbox_marker/H = new(src, point.x, point.y, abs(pixel_z), abs(pixel_w))
		vis_contents += H

/obj/structure/overmap/proc/can_move()
	return TRUE //Placeholder for everything but fighters. We can later extend this if / when we want to code in ship engines.

/obj/structure/overmap/slowprocess()
	. = ..()
	//SS Crit Timer
	if(structure_crit)
		if(world.time > last_critprocess + 10)
			last_critprocess = world.time
			handle_critical_failure_part_1()
	if(cabin_air && cabin_air.return_volume() > 0)
		var/delta = cabin_air.return_temperature() - T20C
		cabin_air.set_temperature(cabin_air.return_temperature() - max(-10, min(10, round(delta/4,0.1))))
	if(internal_tank && cabin_air)
		var/datum/gas_mixture/tank_air = internal_tank.return_air()
		var/release_pressure = ONE_ATMOSPHERE
		var/cabin_pressure = cabin_air.return_pressure()
		var/pressure_delta = min(release_pressure - cabin_pressure, (tank_air.return_pressure() - cabin_pressure)/2)
		var/transfer_moles = 0
		if(pressure_delta > 0) //cabin pressure lower than release pressure
			if(tank_air.return_temperature() > 0)
				transfer_moles = pressure_delta*cabin_air.return_volume()/(cabin_air.return_temperature() * R_IDEAL_GAS_EQUATION)
				var/datum/gas_mixture/removed = tank_air.remove(transfer_moles)
				cabin_air.merge(removed)
		else if(pressure_delta < 0) //cabin pressure higher than release pressure
			var/turf/T = get_turf(src)
			var/datum/gas_mixture/t_air = T.return_air()
			pressure_delta = cabin_pressure - release_pressure
			if(t_air)
				pressure_delta = min(cabin_pressure - t_air.return_pressure(), pressure_delta)
			if(pressure_delta > 0) //if location pressure is lower than cabin pressure
				transfer_moles = pressure_delta*cabin_air.return_volume()/(cabin_air.return_temperature() * R_IDEAL_GAS_EQUATION)
				var/datum/gas_mixture/removed = cabin_air.remove(transfer_moles)
				if(T)
					T.assume_air(removed)
				else //just delete the cabin gas, we're in space or some shit
					qdel(removed)

/*

This proc allows overmaps to survive even in the laggiest of server conditions. Overmaps MUST always process, and sometimes the game will throttle the subsystems during lag. We cannot, however, live without them. That's where this beauty comes into play.
Basically, when we process, we store the last time we were able to be processed. If the last time we were processed was 1 or more seconds ago, then we take control of our own processing with a while() loop.
The while loop runs at a programatic level and is thus separated from any throttling that the server may put in place. 5 minutes after starting the failsafe processing, we'll see if the game is ready to take back control or not.

*/

/obj/structure/overmap/proc/start_failsafe_processing()
	set waitfor = FALSE //Don't hang the process call.
	processing_failsafe = TRUE
	addtimer(VARSET_CALLBACK(src, processing_failsafe, FALSE), 10 MINUTES) //At this point, the game is under immense strain. In a few minutes time we'll attempt to hand back control to processing, but for now, we're going to handle it ourselves.
	while(processing_failsafe)
		stoplag() //Lock up the thread for a bit, throttle the process down to whatever the server can handle right now.
		if(last_process < world.time - 0.5 SECONDS)
			process()

/obj/structure/overmap/Bumped(atom/movable/A)
	if(brakes || ismob(A) || istype(A, /obj/structure/overmap)) //No :)
		return FALSE
	handle_cloak(CLOAK_TEMPORARY_LOSS)
	if(A.dir & NORTH)
		velocity.set_y(velocity.get_y()+bump_impulse)
	if(A.dir & SOUTH)
		velocity.set_y(velocity.get_y()-bump_impulse)
	if(A.dir & EAST)
		velocity.set_x(velocity.get_x()+bump_impulse)
	if(A.dir & WEST)
		velocity.set_x(velocity.get_x()-bump_impulse)
	return ..()

/obj/structure/overmap/Bump(atom/movable/A, datum/collision_response/c_response)
	var/bump_velocity = 0
	if(dir & (NORTH|SOUTH))
		bump_velocity = abs(velocity.y) + (abs(velocity.x) / 10)
	else
		bump_velocity = abs(velocity.x) + (abs(velocity.y) / 10)
	if(istype(A, /obj/machinery/door/airlock) && should_open_doors) // try to open doors
		var/obj/machinery/door/D = A
		if(!D.operating)
			if(D.allowed(D.requiresID() ? pilot : null))
				spawn(0)
					D.open()
			else
				D.do_animate("deny")
	if(layer < A.layer) //Allows ships to "Layer under" things and not hit them. Especially useful for fighters.
		return ..()
	// if a bump is that fast then it's not a bump. It's a collision.
	if(istype(A, /obj/structure/overmap) && c_response)
		collide(A, c_response, bump_velocity)
		return FALSE
	if(isprojectile(A)) //Clears up some weirdness with projectiles doing MEGA damage.
		return ..()
	handle_cloak(CLOAK_TEMPORARY_LOSS)
	if(bump_velocity >= 3 && !impact_sound_cooldown && isobj(A)) //Throttled collision damage a bit
		var/obj/O = A
		var/strength = bump_velocity
		strength = strength * strength
		strength = min(strength, 5) // don't want the explosions *too* big
		// wew lad, might wanna slow down there
		message_admins("[key_name_admin(pilot)] has impacted an overmap ship into [A] with velocity [bump_velocity]")
		take_damage(strength*10, BRUTE, "melee", TRUE)
		O.take_damage(strength*5, BRUTE, "melee", TRUE)
		log_game("[key_name(pilot)] has impacted an overmap ship into [A] with velocity [bump_velocity]")
		visible_message("<span class='danger'>The force of the impact causes a shockwave</span>")
	var/atom/movable/AM = A
	if(istype(AM) && !AM.anchored && bump_velocity > 1)
		step(AM, dir)
	if(isliving(A) && bump_velocity > 2)
		var/mob/living/M = A
		M.apply_damage(bump_velocity * 2)
		take_damage(bump_velocity, BRUTE, "melee", FALSE)
		playsound(M.loc, "swing_hit", 1000, 1, -1)
		M.Knockdown(bump_velocity * 2)
		M.visible_message("<span class='warning'>The force of the impact knocks [M] down!</span>","<span class='userdanger'>The force of the impact knocks you down!</span>")
		log_combat(pilot, M, "impacted", src, "with velocity of [bump_velocity]")
	return ..()

/obj/structure/overmap/proc/fire_projectile(proj_type, atom/target, homing = FALSE, speed=10, explosive = FALSE) //Fire one shot. Used for big, hyper accelerated shots rather than PDCs
	var/fx = cos(90 - angle)
	var/fy = sin(90 - angle)
	var/sx = fy
	var/sy = -fx
	var/new_offset = sprite_size/4
	var/ox = (offset.x * 32) + new_offset
	var/oy = (offset.y * 32) + new_offset
	var/list/origins = list(list(ox + fx - sx, oy + fy - sy))
	for(var/list/origin in origins)
		var/this_x = origin[1]
		var/this_y = origin[2]
		var/turf/T = get_turf(src)
		while(this_x > 16)
			T = get_step(T, EAST)
			this_x -= 32
		while(this_x < -16)
			T = get_step(T, WEST)
			this_x += 32
		while(this_y > 16)
			T = get_step(T, NORTH)
			this_y -= 32
		while(this_y < -16)
			T = get_step(T, SOUTH)
			this_y += 32
		if(!T)
			continue
		var/obj/item/projectile/proj = new proj_type(T)
		proj.starting = T
		if(gunner)
			proj.firer = gunner
		else
			proj.firer = src
		proj.def_zone = "chest"
		proj.original = target
		proj.overmap_firer = src
		proj.pixel_x = round(this_x)
		proj.pixel_y = round(this_y)
		proj.faction = faction
		proj.setup_collider()
		if(isovermap(target) && explosive) //If we're firing a torpedo, the enemy's PDCs need to worry about it.
			var/obj/structure/overmap/OM = target
			OM.torpedoes_to_target += proj //We're firing a torpedo, their PDCs will need to shoot it down, so notify them of its existence
		if(homing)
			proj.set_homing_target(target)
		spawn()
			proj.preparePixelProjectile(target, src, null, round((rand() - 0.5) * proj.spread))
			proj.fire(angle)
		return proj

/obj/structure/overmap/proc/fire_projectiles(proj_type, target) // if spacepods of other sizes are added override this or something
	var/fx = cos(90 - angle)
	var/fy = sin(90 - angle)
	var/sx = fy
	var/sy = -fx
	var/new_offset = sprite_size/4
	var/ox = (offset.x * 32) + new_offset
	var/oy = (offset.y * 32) + new_offset
	var/list/origins = list(list(ox + fx*new_offset - sx*new_offset, oy + fy*new_offset - sy*new_offset), list(ox + fx*new_offset + sx*new_offset, oy + fy*new_offset + sy*new_offset))
	var/list/what_we_fired = list()
	for(var/list/origin in origins)
		var/this_x = origin[1]
		var/this_y = origin[2]
		var/turf/T = get_turf(src)
		while(this_x > 16)
			T = get_step(T, EAST)
			this_x -= 32
		while(this_x < -16)
			T = get_step(T, WEST)
			this_x += 32
		while(this_y > 16)
			T = get_step(T, NORTH)
			this_y -= 32
		while(this_y < -16)
			T = get_step(T, SOUTH)
			this_y += 32
		if(!T)
			continue
		var/obj/item/projectile/proj = new proj_type(T)
		proj.starting = T
		if(gunner)
			proj.firer = gunner
		else
			proj.firer = src
		proj.def_zone = "chest"
		proj.original = target
		proj.overmap_firer = src
		proj.pixel_x = round(this_x)
		proj.pixel_y = round(this_y)
		proj.faction = faction
		proj.setup_collider()
		spawn()
			proj.preparePixelProjectile(target, src, null, round((rand() - 0.5) * proj.spread))
			proj.fire(angle)
		what_we_fired += proj
	return what_we_fired

/obj/structure/overmap/proc/fire_lateral_projectile(proj_type,target,speed=null, mob/living/user_override=null, homing=FALSE)
	var/turf/T = get_turf(src)
	var/obj/item/projectile/proj = new proj_type(T)
	proj.starting = T
	proj.firer = (!user_override && gunner) ? gunner : user_override
	proj.def_zone = "chest"
	proj.original = target
	proj.overmap_firer = src
	proj.pixel_x = round(pixel_x)
	proj.pixel_y = round(pixel_y)
	proj.faction = faction
	proj.setup_collider()
	if(homing)
		proj.set_homing_target(target)
	if(gunner)
		proj.firer = gunner
	else
		proj.firer = src
	spawn()
		proj.preparePixelProjectile(target, src, null, round((rand() - 0.5) * proj.spread))
		proj.fire()
	return proj
