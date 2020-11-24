#define MAXIMUM_COLLISION_RANGE 30 //In tiles, what is the range of the maximum possible collision that could take place? Please try and keep this low, as it saves a lot of time and memory because it'll just ignore physics bodies that are too far away from each other.
//That being said. If you want to make a ship that is bigger than this in tile size, then you will have to change this number. As of 11/08/2020 the LARGEST possible collision range is 25 tiles, due to the fist of sol existing. Though tbh if you make a sprite much larger than this, byond will likely just cull it from the viewport.

PROCESSING_SUBSYSTEM_DEF(physics_processing)
	name = "Physics Processing"
	wait = 1.5
	priority = FIRE_PRIORITY_PHYSICS
	var/list/physics_bodies = list() //All the physics bodies in the world.
	var/list/physics_levels = list()
	var/next_boarding_time = 0 //This is stupid and lazy but it's 5am and I don't care anymore

/datum/controller/subsystem/processing/physics_processing/proc/flatten_points_on(list/points, datum/vector2d/normal)
	var/minpoint = INFINITY
	var/maxpoint = -INFINITY


	for (var/datum/vector2d/point in points)
		var/dot = point.dot(normal)
		if (dot < minpoint)
			minpoint = dot

		if (dot > maxpoint)
			maxpoint = dot
	return new /datum/vector2d(minpoint, maxpoint)

/**

Helper methods for collision detection, implementing things like the separating axis theorem.

Special thanks to qwertyquerty for explaining and dictating all this! (I've mostly translated his pseudocode into readable byond code)

*/

/datum/controller/subsystem/processing/physics_processing/proc/is_separating_axis(datum/vector2d/a_pos, datum/vector2d/b_pos, list/datum/vector2d/a_points, list/datum/vector2d/b_points, datum/vector2d/axis, datum/collision_response/c_response)

	b_pos.subtract(a_pos)

	var/projected_offset = b_pos.dot(axis)
	var/datum/vector2d/range_a = flatten_points_on(a_points, axis)
	var/datum/vector2d/range_b = flatten_points_on(b_points, axis)

	range_b.update(range_b.x+projected_offset,range_b.y+projected_offset)

	if(range_a.x > range_b.y || range_b.x > range_a.y)
		return TRUE
	if (c_response)
		var/overlap = 0

		if(range_a.x < range_b.x)
			c_response.a_in_b = FALSE

			if(range_a.y < range_b.y)
				overlap = range_a.y - range_b.x
				c_response.b_in_a = FALSE
			else
				var/option_1 = range_a.y - range_b.x
				var/option_2 = range_b.y - range_a.x
				overlap = option_1 < option_2 ? option_1 : -option_2
		else
			c_response.b_in_a = FALSE

			if (range_a.y > range_b.y)
				overlap = range_a.x - range_b.y
				c_response.a_in_b = FALSE
			else
				var/option_1 = range_a.y - range_b.x
				var/option_2 = range_b.y - range_a.x
				overlap = option_1 < option_2 ? option_1 : -option_2

		if (abs(overlap) < c_response.overlap)
			c_response.overlap = abs(overlap)
			c_response.overlap_normal.copy(axis)
			if (overlap < 0)
				c_response.overlap_normal.reverse()
	//Free the vectors
	qdel(range_a)
	qdel(range_b)
	return FALSE

/datum/controller/subsystem/processing/physics_processing/fire(resumed)
	. = ..()
	//This is O(n), but it could be worse, far worse.
	for(var/I in physics_levels)
		var/list/za_warudo = physics_levels[I]
		for(var/datum/component/physics2d/body in za_warudo)
			if(!body.collider2d)
				continue
			if(!body || QDELETED(body) || !body.holder)
				za_warudo -= body
				continue
			if(body.holder.z == null || body.holder.z == 0)
				continue //If we're in nullspace.
			var/list/recent_collisions = list() //So we don't collide two things together twice.
			for(var/datum/component/physics2d/neighbour in za_warudo) //Now we check the collisions of every other physics body with this one. I hate that I have to do this, but I can't think of a better way just yet.
				//Precondition: body and neighbour both exist, and are attached to something.
				if(!neighbour || QDELETED(neighbour) || !neighbour.holder)
					za_warudo -= neighbour
					continue
				if(neighbour.holder.z == null  || neighbour.holder.z == 0)
					continue //If we're in nullspace.
				//Precondition: body and neighbour are different entities.
				if(body == neighbour)
					continue
				//Precondition: neighbour has a collider2d (IE, hitboxes set up for it)
				if(!neighbour.collider2d)
					continue
				//Precondition: They're actually somewhat near each other. This is a nice and simple way to cull collisions that would never happen, and save some CPU time.
				if(get_dist(body.holder, neighbour.holder) > MAXIMUM_COLLISION_RANGE) //Too far away to even bother with this calculation.
					continue
				if(neighbour.holder.z != body.holder.z) //Just in case some freak accident happened
					continue
				//Let's not bother checking collisions that we already ran.
				if(neighbour in recent_collisions)
					continue
				//OK, now we get into the expensive calculation. This is our absolute last resort because it's REALLY expensive.
				if(isovermap(body.holder) && isovermap(neighbour.holder)) //Dirty, but necessary. I want to minimize in-depth collision calc wherever I possibly can, so only overmap prototypes use it.
					var/datum/collision_response/outcome = null
					outcome = body.collider2d?.collides(neighbour.collider2d)
					if(outcome)
						message_admins("OM Collision response was: [outcome]")
						body.holder.Bump(neighbour.holder, outcome) //More in depth calculation required, so pass this information on.
						recent_collisions += neighbour
						qdel(outcome)
				else //OK great, we get more simplified calc!
					if(isprojectile(body) && isprojectile(neighbour))
						continue //Bullets don't want to "bump" into each other, we actually handle that code in "crossed()"
					var/datum/collision_response/outcome = null
					outcome = body.collider2d?.collides(neighbour.collider2d)
					if(outcome)
						message_admins("Collision response was: [outcome]")
						body.holder.Bump(neighbour.holder)
						recent_collisions += neighbour
						qdel(outcome)



/datum/component/physics2d
	var/datum/shape/collider2d = null //Our box collider. See the collision module for explanation
	var/datum/vector2d/position = null //Positional vector, used exclusively for collisions with overmaps
	var/datum/vector2d/velocity = null
	var/last_registered_z = 0 //Placeholder. Overridden on process()
	var/atom/movable/holder = null
	var/next_collision = 0

/datum/component/physics2d/Initialize()
	. = ..()
	if(!istype(parent, /atom/movable))
		return COMPONENT_INCOMPATIBLE //Precondition: This is something that actually moves.
	holder = parent
	SSphysics_processing.physics_bodies += src
	last_registered_z = holder.z
	LAZYADD(SSphysics_processing.physics_levels["[last_registered_z]"], src)

/datum/component/physics2d/Destroy(force, silent)
	//Stop fucking referencing this I sweAR
	if(holder)
		var/obj/structure/overmap/OM = holder
		if(istype(OM))
			OM.physics2d = null
		var/obj/item/projectile/P = holder
		if(istype(P))
			P.physics2d = null
	for(var/I in SSphysics_processing.physics_levels)
		var/list/za_warudo = SSphysics_processing.physics_levels[I]
		za_warudo.Remove(src)
	//De-alloc references.
	qdel(collider2d)
	qdel(position)
	qdel(velocity)
	. = ..()

/datum/component/physics2d/proc/setup(list/hitbox, angle)
	position = new /datum/vector2d(holder.x*32,holder.y*32)
	collider2d = new /datum/shape(position, hitbox, angle) // -TORADIANS(src.angle-90)
	last_registered_z = holder.z
	START_PROCESSING(SSphysics_processing, src)

/datum/component/physics2d/proc/update(x, y, angle)
	collider2d?.set_angle(angle) //Turn the box collider
	collider2d?._set(x, y)

/datum/component/physics2d/process()
	if(QDELETED(holder) || !holder)
		RemoveComponent()
		qdel(src)
		return PROCESS_KILL
	if(holder.z != last_registered_z) //Z changed? Update this unit's processing chunk.
		var/list/stats = SSphysics_processing.physics_levels["[last_registered_z]"]
		if(stats) //If we're already in a list.
			stats -= src
		last_registered_z = holder.z
		stats = SSphysics_processing.physics_levels["[last_registered_z]"]
		LAZYADD(stats, src) //If the SS isn't tracking this Z yet with a list, this will take care of it.
