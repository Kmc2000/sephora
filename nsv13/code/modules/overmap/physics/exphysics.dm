GLOBAL_VAR(exmap_extools_initialised)
/**
No, this isn't physics about your ex!

Welcome to C++ vector physics land! Adapted from the initial qwer2d implementation by qwerty_trogi and Kmc2000.

If you don't understand what's going on, I don't blame you.

Lag b gone spray lives here:
*/

#define EXMAP_EXTOOLS_CHECK if(!GLOB.exmap_extools_initialised){\
	if(fexists(EXTOOLS)){\
		var/result = call(EXTOOLS,"init_exmap")();\
		if(result != "ok") {CRASH(result);}\
		GLOB.exmap_extools_initialised=TRUE;\
	} else {\
		CRASH("byond-extools.dll or libbyond-extools.so does not exist!");\
	}\
}

/obj/structure/overmap/Initialize()
	. = ..()
	offset = new /datum/vector2d()
	last_offset = new /datum/vector2d()
	position = new /datum/vector2d(x*32,y*32)
	velocity = new /datum/vector2d(0, 0)
	overlap = new /datum/vector2d(0, 0)
	if(collision_positions.len)
		physics2d = AddComponent(/datum/component/physics2d)
		physics2d.setup(collision_positions, angle)
	else
		message_admins("[src] does not have collision points set! It will float through everything.")

/obj/structure/overmap
	var/last_process = 0
	var/processing_failsafe = FALSE //Has the game lagged to shit and we need to handle our own processing until it clears up?
	var/obj/vector_overlay/vector_overlay
	var/pixel_collision_size_x = 0
	var/pixel_collision_size_y = 0
	var/datum/vector2d/offset
	var/datum/vector2d/last_offset
	var/datum/vector2d/position
	var/datum/vector2d/velocity
	var/datum/vector2d/overlap // Will be subtracted from the ships offset as soon as possible, then set to 0
	var/list/collision_positions = list() //See the collisions doc for how these work. Theyre a pain in the ass.
	var/datum/component/physics2d/physics2d = null

/obj/structure/overmap/process()
	set waitfor = FALSE
	var/time = min(world.time - last_process, 10)
	time /= 10 // fuck off deciseconds
	last_process = world.time
	if(world.time > last_slowprocess + 7)
		last_slowprocess = world.time
		slowprocess()
	last_offset.copy(offset)
	var/last_angle = angle
	var/desired_angular_velocity = 0
	if(isnum(desired_angle))
		// do some finagling to make sure that our angles end up rotating the short way
		while(angle > desired_angle + 180)
			angle -= 360
			last_angle -= 360
		while(angle < desired_angle - 180)
			angle += 360
			last_angle += 360
		if(abs(desired_angle - angle) < (max_angular_acceleration * time))
			desired_angular_velocity = (desired_angle - angle) / time
		else if(desired_angle > angle)
			desired_angular_velocity = 2 * sqrt((desired_angle - angle) * max_angular_acceleration * 0.25)
		else
			desired_angular_velocity = -2 * sqrt((angle - desired_angle) * max_angular_acceleration * 0.25)

	var/angular_velocity_adjustment = CLAMP(desired_angular_velocity - angular_velocity, -max_angular_acceleration*time, max_angular_acceleration*time)
	if(angular_velocity_adjustment)
		last_rotate = angular_velocity_adjustment / time
		angular_velocity += angular_velocity_adjustment
	else
		last_rotate = 0
	angle += angular_velocity * time
	// calculate drag and shit

	var/velocity_mag = velocity.ln() // magnitude
	if(velocity_mag)
		var/drag = 0
		for(var/turf/T in locs)
			if(isspaceturf(T))
				continue
			drag += 0.001
			var/floating = FALSE
			if(T.has_gravity() && velocity_mag >= 4)
				floating = TRUE // Count them as "flying" if theyre going fast enough indoors. If you slow down, you start to scrape due to no lift or something
			var/datum/gas_mixture/env = T.return_air()
			var/pressure = env.return_pressure()
			drag += velocity_mag * pressure * 0.001 // 1 atmosphere should shave off 10% of velocity per tile
			if(pressure >= 10) //Space doesn't have air resistance or much gravity, so we'll assume theyre floating if theyre in space.
				if((!floating && T.has_gravity())) // brakes are a kind of magboots okay?
					drag += 0.5 // some serious drag. Damn.
					if(velocity_mag <= 2 && istype(T, /turf/open/floor) && prob(30))
						var/turf/open/floor/TF = T
						TF.make_plating() // pull up some floor tiles. Stop going so damn slow, ree.
						take_damage(3, BRUTE, "melee", FALSE)

		if(velocity_mag > 20)
			drag = max(drag, (velocity_mag - 20) / time)
		if(drag)
			if(velocity_mag)
				var/drag_factor = 1 - CLAMP(drag * time / velocity_mag, 0, 1)
				velocity.multiply(drag_factor)
			if(angular_velocity != 0)
				var/drag_factor_spin = 1 - CLAMP(drag * 30 * time / abs(angular_velocity), 0, 1)
				angular_velocity *= drag_factor_spin

	// Alright now calculate the THRUST
	var/thrust_x
	var/thrust_y
	var/fx = cos(90 - angle)
	var/fy = sin(90 - angle) //This appears to be a vector.
	var/sx = fy
	var/sy = -fx
	last_thrust_forward = 0
	last_thrust_right = 0
	if(brakes) //If our brakes are engaged, attempt to slow them down
		// basically calculates how much we can brake using the thrust
		var/forward_thrust = -((fx * velocity.x) + (fy * velocity.y)) / time
		var/right_thrust = -((sx * velocity.x) + (sy * velocity.y)) / time
		forward_thrust = CLAMP(forward_thrust, -backward_maxthrust, forward_maxthrust)
		right_thrust = CLAMP(right_thrust, -side_maxthrust, side_maxthrust)
		thrust_x += forward_thrust * fx + right_thrust * sx;
		thrust_y += forward_thrust * fy + right_thrust * sy;
		last_thrust_forward = forward_thrust
		last_thrust_right = right_thrust
	else // Add our thrust to the movement vector
		if(can_move())
			if(user_thrust_dir & NORTH)
				thrust_x += fx * forward_maxthrust
				thrust_y += fy * forward_maxthrust
				last_thrust_forward = forward_maxthrust
			if(user_thrust_dir & SOUTH)
				thrust_x -= fx * backward_maxthrust
				thrust_y -= fy * backward_maxthrust
				last_thrust_forward = -backward_maxthrust
			if(user_thrust_dir & EAST)
				thrust_x += sx * side_maxthrust
				thrust_y += sy * side_maxthrust
				last_thrust_right = side_maxthrust
			if(user_thrust_dir & WEST)
				thrust_x -= sx * side_maxthrust
				thrust_y -= sy * side_maxthrust
				last_thrust_right = -side_maxthrust

	//Stops you yeeting off at lightspeed. This made AI ships really frustrating to play against.
	velocity.x = max(min(velocity.x, speed_limit), -speed_limit)
	velocity.y = max(min(velocity.y, speed_limit), -speed_limit)

	velocity.update(velocity.x + thrust_x * time, velocity.y + thrust_y * time)//And speed us up based on how long we've been thrusting (up to a point)
	if(inertial_dampeners) //An optional toggle to make capital ships more "fly by wire" and help you steer in only the direction you want to go.
		var/side_movement = (sx*velocity.x) + (sy*velocity.y)
		var/friction_impulse = side_maxthrust * time
		var/clamped_side_movement = CLAMP(side_movement, -friction_impulse, friction_impulse)
		velocity.update(velocity.x - clamped_side_movement * sx, velocity.y - clamped_side_movement * sy)

	offset.update(velocity.x * time, velocity.y * time)
	if(!position || QDELETED(position))
		position = new /datum/vector2d()
	position.update(x * 32 + offset.x * 32, y * 32 + offset.y * 32)

	if(physics2d)
		physics2d.update(position.x, position.y, angle)

	// alright so now we reconcile the offsets with the in-world position.
	while((offset.x > 0 && velocity.x > 0) || (offset.y > 0 && velocity.y > 0) || (offset.x < 0 && velocity.x < 0) || (offset.y < 0 && velocity.y < 0))
		var/failed_x = FALSE
		var/failed_y = FALSE
		if(offset.x > 0 && velocity.x > 0)
			dir = EAST
			if(!Move(get_step(src, EAST)))
				offset.set_x(0)
				failed_x = TRUE
				velocity.x *= -bounce_factor
				velocity.y *= lateral_bounce_factor
			else
				offset.x--
				last_offset.x--
		else if(offset.x < 0 && velocity.x < 0)
			dir = WEST
			if(!Move(get_step(src, WEST)))
				offset.set_x(0)
				failed_x = TRUE
				velocity.x *= -bounce_factor
				velocity.y *= lateral_bounce_factor
			else
				offset.x++
				last_offset.x++
		else
			failed_x = TRUE
		if(offset.y > 0 && velocity.y > 0)
			dir = NORTH
			if(!Move(get_step(src, NORTH)))
				offset.set_y(0)
				failed_y = TRUE
				velocity.y *= -bounce_factor
				velocity.x *= lateral_bounce_factor
			else
				offset.y--
				last_offset.y--
		else if(offset.y < 0 && velocity.y < 0)
			dir = SOUTH
			if(!Move(get_step(src, SOUTH)))
				offset.set_y(0)
				failed_y = TRUE
				velocity.y *= -bounce_factor
				velocity.x *= lateral_bounce_factor
			else
				offset.y++
				last_offset.y++
		else
			failed_y = TRUE
		if(failed_x && failed_y)
			break
	// prevents situations where you go "wtf I'm clearly right next to it" as you enter a stationary spacepod
	if(velocity.x == 0)
		if(offset.x > 0.5)
			if(Move(get_step(src, EAST)))
				offset.x--
				last_offset.x--
			else
				offset.set_x(0)
		if(offset.x < -0.5)
			if(Move(get_step(src, WEST)))
				offset.x++
				last_offset.x++
			else
				offset.set_x(0)
	if(velocity.y == 0)
		if(offset.y > 0.5)
			if(Move(get_step(src, NORTH)))
				offset.y--
				last_offset.y--
			else
				offset.set_y(0)
		if(offset.y < -0.5)
			if(Move(get_step(src, SOUTH)))
				offset.y++
				last_offset.y++
			else
				offset.set_y(0)
	dir = NORTH //So that the matrix is always consistent
	var/matrix/mat_from = new()
	mat_from.Turn(last_angle)
	var/matrix/mat_to = new()
	mat_to.Turn(angle)
	var/matrix/targetAngle = new() //Indicate where the ship wants to go.
	targetAngle.Turn(desired_angle)
	if(resize > 0)
		for(var/i = 0, i < resize, i++) //We have to resize by 0.5 to shrink. So shrink down by a factor of "resize"
			mat_from.Scale(0.5,0.5)
			mat_to.Scale(0.5,0.5)
			targetAngle.Scale(0.5,0.5) //Scale down their movement indicator too so it doesnt look comically big
	if(pilot?.client && desired_angle && !move_by_mouse)//Preconditions: Pilot is logged in and exists, there is a desired angle, we are NOT moving by mouse (dont need to see where we're steering if it follows mousemovement)
		vector_overlay.transform = targetAngle
		vector_overlay.alpha = 255
	else
		vector_overlay.alpha = 0
		targetAngle = null
	transform = mat_from

	pixel_x = last_offset.x*32
	pixel_y = last_offset.y*32

	animate(src, transform=mat_to, pixel_x = offset.x*32, pixel_y = offset.y*32, time = time*10, flags=ANIMATION_END_NOW)
	if(last_target)
		var/target_angle = Get_Angle(src,last_target)
		var/matrix/final = matrix()
		final.Turn(target_angle)
		if(last_fired)
			last_fired.transform = final
	else if(last_fired)
		last_fired.transform = mat_to

	for(var/mob/living/M in operators)
		var/client/C = M.client
		if(!C)
			continue
		C.pixel_x = last_offset.x*32
		C.pixel_y = last_offset.y*32
		animate(C, pixel_x = offset.x*32, pixel_y = offset.y*32, time = time*10, flags=ANIMATION_END_NOW)
	user_thrust_dir = 0
	update_icon()
	if(autofire_target && !aiming)
		if(!gunner) //Just...just no. If we don't have this, you can get shot to death by your own fighter after youve already left it :))
			autofire_target = null
			return
		fire(autofire_target)


/obj/structure/overmap/proc/collide(obj/structure/overmap/other, datum/collision_response/c_response, collision_velocity)
	if(layer < other.layer || other.layer > layer)
		return FALSE
	if(istype(other, /obj/structure/overmap/fighter))
		var/obj/structure/overmap/fighter/F = other
		if(F.docking_act(src))
			return FALSE
	if(istype(src, /obj/structure/overmap/fighter))
		var/obj/structure/overmap/fighter/F = src
		if(F.docking_act(other))
			return FALSE
	//Update the colliders before we do any kind of calc.
	if(physics2d)
		physics2d.update(position.x, position.y, angle)
	if(other.physics2d)
		other.physics2d.update(other.position.x, other.position.y, angle)
	var/datum/vector2d/point_of_collision = physics2d?.collider2d.get_collision_point(other.physics2d?.collider2d)
	check_quadrant(point_of_collision)

	//So what this does is it'll calculate a vector (overlap_vector) that makes the two objects no longer colliding, then applies extra velocity to make the collision smooth to avoid teleporting. If you want to tone down collisions even more
	//Be sure that you change the 0.25/32 bit as well, otherwise, if the cancelled out vector is too large compared to the speed jump, you just get teleportation and it looks really jank ~K
	if (point_of_collision)
		var/col_angle = c_response.overlap_normal.angle()
		var/src_vel_mag = src.velocity.ln()
		var/other_vel_mag = other.velocity.ln()

		// Elastic collision equations
		var/new_src_vel_x = ((																	\
			(src_vel_mag * cos(src.velocity.angle() - col_angle) * (other.mass - src.mass)) +	\
			(2 * other.mass * other_vel_mag * cos(other.velocity.angle() - col_angle))			\
		) / (src.mass + other.mass)) * (cos(col_angle) + (src_vel_mag * sin(src.velocity.angle() - col_angle) * cos(col_angle + 90)))

		var/new_src_vel_y = ((																	\
			(src_vel_mag * cos(src.velocity.angle() - col_angle) * (other.mass - src.mass)) +	\
			(2 * other.mass * other_vel_mag * cos(other.velocity.angle() - col_angle))			\
		) / (src.mass + other.mass)) * (sin(col_angle) + (src_vel_mag * sin(src.velocity.angle() - col_angle) * sin(col_angle + 90)))

		var/new_other_vel_x = ((																		\
			(other_vel_mag * cos(other.velocity.angle() - col_angle) * (src.mass - other.mass)) +		\
			(2 * src.mass * src_vel_mag * cos(src.velocity.angle() - col_angle))						\
		) / (other.mass + src.mass)) * (cos(col_angle) + (other_vel_mag * sin(other.velocity.angle() - col_angle) * cos(col_angle + 90)))

		var/new_other_vel_y = ((																		\
			(other_vel_mag * cos(other.velocity.angle() - col_angle) * (src.mass - other.mass)) +		\
			(2 * src.mass * src_vel_mag * cos(src.velocity.angle() - col_angle))						\
		) / (other.mass + src.mass)) * (sin(col_angle) + (other_vel_mag * sin(other.velocity.angle() - col_angle) * sin(col_angle + 90)))

		src.velocity.update(new_src_vel_x*bounce_factor, new_src_vel_y*bounce_factor)
		other.velocity.update(new_other_vel_x*other.bounce_factor, new_other_vel_y*other.bounce_factor)
	var/datum/vector2d/output = c_response.overlap_vector.multiply(0.25 / 32)
	src.offset.subtract(output)
	other.offset.add(output)
	qdel(output)
	qdel(point_of_collision)
	qdel(c_response)
