////!!!!!WARNING!!!!!! If you ever add more vars to vectors, you need to change the extools constants. They shouldnt EVER need more than this.
/datum/vector2d
	var/_extools_pointer_vector = 0 // Contains the memory address of the shared_ptr object for this vector in c++ land. Don't. Touch. This. Var.
	var/x = 0
	var/y = 0

/**

Methods that C++ needs to know about live here.

*/
/datum/vector2d/proc/vector_register()
/datum/vector2d/proc/vector_unregister()

/datum/vector2d/proc/__get_x()
/datum/vector2d/proc/get_x()
/datum/vector2d/proc/__get_y()
/datum/vector2d/proc/get_y()

/datum/vector2d/proc/__set_x()
/datum/vector2d/proc/set_x()

/datum/vector2d/proc/__set_y()
/datum/vector2d/proc/set_y()

//Heavy math functions.
/datum/vector2d/proc/__get_seg_intersect()
/datum/vector2d/proc/get_seg_intersect()

/**
Class definition and basic functionality
*/

/datum/vector2d/New(x=0, y=0)
	. = ..()
	src.x = x
	src.y = y
	EXMAP_EXTOOLS_CHECK
	vector_register()

//Wraps in some vectors to C++ land, gets the intersection of their line.
/datum/vector2d/get_seg_intersect(datum/vector2d/p0, datum/vector2d/p1, datum/vector2d/p2, datum/vector2d/p3)
	var/list/lines = list(p0.x, p0.y, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y)
	var/list/out = __get_seg_intersect(lines)
	if(out == null)
		return FALSE
	else
		return new /datum/vector2d(out[1], out[2])

/datum/vector2d/vv_edit_var(var_name, var_value)
	if(var_name == "_extools_pointer_vector")
		return FALSE // No. You can segfault somewhere else.
	switch(var_name)
		if("x")
			set_x(var_value)
		if("y")
			set_y(var_value)
	return ..()

/datum/vector2d/proc/to_string()
	return "{[src.x], [src.y]}"

/**
And now, procs for the vector class!
*/

/datum/vector2d/get_x()
	return __get_x()

/datum/vector2d/get_y()
	return __get_y()

/datum/vector2d/set_x(newX)
	if(QDELETED(src))
		return
	__set_x(newX)
	x = get_x()
	return get_x()

/datum/vector2d/set_y(newY)
	if(QDELETED(src))
		return
	__set_y(newY)
	y = get_y()
	return get_y()

/datum/vector2d/proc/update(newX,newY)
	if(isnum_safe(newX) && !QDELETED(src))
		set_x(newX)
	if(isnum_safe(newY) && !QDELETED(src))
		set_y(newY)
	return src

/datum/vector2d/proc/add(what)
	if(isnum(what))
		update(x+what,y+what)
	else if(istype(what, /datum/vector2d))
		var/datum/vector2d/target = what
		update(x+target.x, y+target.y)

/datum/vector2d/proc/subtract(what)
	if(isnum(what))
		update(x-what, y-what)
	else if(istype(what, /datum/vector2d))
		var/datum/vector2d/target = what
		update(x-target.x, y-target.y)

/datum/vector2d/proc/multiply(what)
	if(isnum(what))
		update(x*what, y*what)
	else if(istype(what, /datum/vector2d))
		var/datum/vector2d/target = what
		update(target.x*x, target.y*y)

/datum/vector2d/proc/divide(what)
	if(isnum_safe(what))
		if(what == 0)
			return
		update(x/what, y/what)
	else if(istype(what, /datum/vector2d))
		var/datum/vector2d/target = what
		update(target.x/x, target.y/y)

/datum/vector2d/proc/copy(datum/vector2d/target)
	if(target == null)
		return
	update(target.x, target.y)

/*
Calculate the dot product of two vectors
@return the dot product of the two vectors
*/
/datum/vector2d/proc/dot(var/datum/vector2d/other)
	return (src.x * other.x) + (src.y * other.y)

/*
Calculate the cross product of two vectors
@return the cross product of the two vectors
*/
/datum/vector2d/proc/cross(var/datum/vector2d/other)
	return src.x * other.y - src.y * other.x

/*
Get the magnitude of a vector squared
@return the magnitude of the vector squared (hypot)^2
*/
/datum/vector2d/proc/ln2()
	return src.dot(src)

/*
Get the magnitude of a vector
@return the magnitude of the vector (hypot)
*/
/datum/vector2d/proc/ln()
	return sqrt(src.ln2())

/*
Get the angle of a vector
@return the angle of the vector (atan) in radians
*/
/datum/vector2d/proc/angle()
	return ATAN2(src.x, src.y)

/*
Normalize the vector so it has a magnitude of 1
@return a normalized version of the vector
*/
/datum/vector2d/proc/normalize()
	return src.divide(src.ln())

/*
Methods for projecting a vector onto another
*/
/datum/vector2d/proc/project(var/datum/vector2d/other)
	RETURN_TYPE(/datum/vector2d)
	var/amt = src.dot(other) / other.ln2()
	update(amt * other.x, amt * other.y)
	return src

/datum/vector2d/proc/project_n(var/datum/vector2d/other)
	RETURN_TYPE(/datum/vector2d)
	var/amt = src.dot(other)
	update(amt * other.x, amt * other.y)
	return src

/*
Methods for reflecting a vector across an axis
*/
/datum/vector2d/proc/reflect(axis)
	src.project(axis)
	src.multiply(-2)

/datum/vector2d/proc/reflect_n(axis)
	src.project_n(axis)
	src.multiply(-2)

/*
Quickly rotate the vector a 4th turn
@return the rotated vector
*/
/datum/vector2d/proc/perp()
	RETURN_TYPE(/datum/vector2d)
	var/newx = src.y
	var/newy = -src.x
	update(x-newx, y-newy)
	return src

/*
A method to make a clone of this vector
@return a new vector2d with the same stats as this one
*/
/datum/vector2d/proc/clone()
	var/datum/vector2d/out = new /datum/vector2d(x, y)
	qdel(src)
	return out

/*
Method to turn this vector counter clockwise by a desired angle
@return the rotated vector
*/
/datum/vector2d/proc/rotate(angle)
	RETURN_TYPE(/datum/vector2d)
	var/s = sin(angle)
	var/c = cos(angle)
	var/newx = c*x + s*y
	var/newy = -s*x + c*y
	update(newx, newy)
	return src

/*
Negate both values of a vector without making a new one
@return the reversed vector
*/
/datum/vector2d/proc/reverse(angle)
	RETURN_TYPE(/datum/vector2d)
	update(-x, -y)
	return src

/proc/get_seg_intersection(datum/vector2d/p0, datum/vector2d/p1, datum/vector2d/p2, datum/vector2d/p3)
	var/datum/vector2d/p12 = new /datum/vector2d(p1.x, p1.y)
	var/datum/vector2d/p32 = new /datum/vector2d(p3.x,p3.y)
//	message_admins("Seg intercept")
	p12.subtract(p0)
	p32.subtract(p2)

	var/datum/vector2d/s10 = p12
	var/datum/vector2d/s32 = p32

	var/denom = s10.cross(s32)

	if (denom == 0)
		return FALSE
	message_admins("denom: [denom]")

	var/denom_is_positive = denom > 0

	var/datum/vector2d/s02 = new /datum/vector2d()
	s02.copy(p0)
	s02.subtract(p2)

	var/s_numer = s10.cross(s02)

	if ((s_numer < 0) == denom_is_positive)
		return FALSE

	message_admins("S numer: [s_numer]")

	var/t_numer = s32.cross(s02)

	if ((t_numer < 0) == denom_is_positive)
		return FALSE

	message_admins("T numer: [t_numer]")
	//Stops after this line...
	if ((s_numer > denom) == denom_is_positive || (t_numer > denom) == denom_is_positive)
		return FALSE

	var/t = t_numer / denom

	message_admins("T: [t]")

	var/datum/vector2d/out = new /datum/vector2d(p0.x + (t * s10.x), p0.y + (t * s10.y))
	message_admins("[out.to_string()]")
	qdel(s10)
	qdel(s32)
	qdel(s02)
	return out
