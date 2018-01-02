module ConstructiveSolidGeometry

export Coord
export Ray
export Surface
export Plane
export Cone
export Sphere
export InfCylinder
export Box
export Region
export Cell
export Geometry
export +,-,*,^,|,~
export reflect
export generate_random_ray
export raytrace
export find_intersection
export halfspace
export is_in_cell
export find_cell_id
export plot_geometry_2D
export plot_cell_2D
export dot
export magnitude
export unitize
export cross

using Plots

"""
    type Coord

An {x,y,z} coordinate type. Used throughout the ConstructiveSolidGeometry.jl package for speed.

# Constructors
* `Coord(x::Float64, y::Float64, z::Float64)`
"""
type Coord
    x::Float64
    y::Float64
    z::Float64
end

"""
    type Ray

A ray is defined by its origin and a unitized direction vector

# Constructors
* `Ray(origin::Coord, direction::Coord)`
"""
type Ray
    origin::Coord
    direction::Coord
end

"""
    abstract Surface

An abstract class that all surfaces (`Sphere`, `Plane`, `InfCylinder`) inherit from. Implementation of new shapes should inherit from `Surface`.
"""
abstract type Surface end

"""
    type Plane <: Surface

Defined by a point on the surface of the plane, its unit normal vector, and an optional boundary condition.

# Constructors
* `Plane(point::Coord, normal::Coord)`
* `Plane(point::Coord, normal::Coord, boundary::String)`

# Arguments
* `point::Coord`: Any point on the surface of the plane
* `normal::Coord`: A unit normal vector of the plane. Recommended to use `unitize(c::Coord)` if normalizing is needed.
* `boundary::String`: Optional boundary condition, defined as a `String`. Options are "transmission" (default), "vacuum", and "reflective".
"""
type Plane <: Surface
    point::Coord
    normal::Coord
    reflective::Bool
	vacuum::Bool
	Plane(point::Coord, normal::Coord, ref::Bool, vac::Bool) = new(point, normal, ref, vac)
	function Plane(point::Coord, normal::Coord, boundary::String)
		if boundary == "reflective"
			new(point, normal, true, false)
		elseif boundary == "vacuum"
			new(point, normal, false, true)
		else
			new(point, normal, false, false)
		end
	end
	Plane(point::Coord, normal::Coord) = new(point, normal, false, false)
end

"""
    type Cone <: Surface

Defined by the tip of the cone, its direction axis vector, the angle between the central axis and the cone surface, and an optional boundary condition.

# Constructors
* `Cone(tip::Coord, axis::Coord, theta::Float64)`
* `Cone(tip::Coord, axis::Coord, theta::Float64, boundary::String)`

# Arguments
* `tip::Coord`: The vertex (tip) of the cone
* `axis::Coord`: A unit vector representing the central axis of the cone. As the cone equation actually defines two cones eminating in a mirrored fashion from the tip, this direction vector also indicates which cone is the true cone. I.e., following the direction of the axis vector when starting from the tip should lead inside the cone you actually want.  Recommended to use `unitize(c::Coord)` if normalizing is needed.
* `theta::Float64`: The angle (in radians) between the central axis (must be between 0 and pi/2)
* `boundary::String`: Optional boundary condition, defined as a `String`. Options are \"transmission\" (default) or \"vacuum\".
"""
type Cone <: Surface
    tip::Coord
    axis::Coord
	theta::Float64
    reflective::Bool
	vacuum::Bool
	Cone(tip::Coord, axis::Coord, theta::Float64, ref::Bool, vac::Bool) = new(tip, axis, theta, ref, vac)
	function Cone(tip::Coord, axis::Coord, theta::Float64, boundary::String)
		if boundary == "reflective"
			new(tip, axis, theta, true, false)
		elseif boundary == "vacuum"
			new(tip, axis, theta, false, true)
		else
			new(tip, axis, theta, false, false)
		end
	end
	Cone(tip::Coord, axis::Coord, theta::Float64) = new(tip, axis, theta, false, false)
end

"""
    type Sphere <: Surface

Defined by the center of the sphere, its radius, and an optional boundary condition.

# Constructors
* `Sphere(center::Coord, radius::Float64)`
* `Sphere(center::Coord, radius::Float64, boundary::String)`

# Arguments
* `center::Coord`: The center of the sphere
* `radius::Float64`: The radius of the sphere
* `boundary::String`: Optional boundary condition, defined as a `String`. Options are \"transmission\" (default) or \"vacuum\".
"""
type Sphere <: Surface
    center::Coord
    radius::Float64
    reflective::Bool
	vacuum::Bool
	Sphere(c::Coord, r::Float64, ref::Bool, vac::Bool) = new(c, r, ref, vac)
	function Sphere(c::Coord, r::Float64, boundary::String)
		if boundary == "reflective"
			new(c, r, true, false)
		elseif boundary == "vacuum"
			new(c, r, false, true)
		else
			new(c, r, false, false)
		end
	end
	Sphere(c::Coord, r::Float64) = new(c, r, false, false)
end

"""
    type InfCylinder <: Surface

An arbitrary direction infinite cylinder defined by any point on its central axis, its radius, the unit normal direction of the cylinder, and an optional boundary condition. A finite cylinder can be generated by defining the intersection of an infinite cylinder and two planes.

# Constructors
* `InfCylinder(center::Coord, normal::Coord, radius::Float64)`
* `InfCylinder(center::Coord, normal::Coord, radius::Float64, boundary::String)`

# Arguments
* `center::Coord`: The center of the infinite cylinder
* `normal::Coord`: A unit normal direction vector of the cylinder (i.e., a vector along its central axis), Recommended to use `unitize(c::Coord)` if normalizing is needed.
* `radius::Float64`: The radius of the infinite cylinder
* `boundary::String`: Optional boundary condition, defined as a `String`. Options are \"transmission\" (default) or \"vacuum\".
"""
type InfCylinder <: Surface
    center::Coord
    normal::Coord
    radius::Float64
    reflective::Bool
	vacuum::Bool
	InfCylinder(c::Coord, n::Coord, r::Float64, ref::Bool, vac::Bool) = new(c, n, r, ref, vac)
	function InfCylinder(c::Coord, n::Coord, r::Float64, boundary::String)
		if boundary == "reflective"
			new(c, n, r, true, false)
		elseif boundary == "vacuum"
			new(c, n, r, false, true)
		else
			new(c, n, r, false, false)
		end
	end
	InfCylinder(c::Coord, n::Coord, r::Float64) = new(c, n, r, false, false)
end

"""
    type Box

An axis aligned box is defined by the minimum `Coord` and maximum `Coord` of the box. Note that a Box is only used by ConstructiveSolidGeometry.jl for bounding box purposes, and is not a valid surface to define CSG cells with. Instead, you must define all six planes of a box independently.

# Constructors
* `Box(min::Coord, max::Coord)`
"""
type Box
    lower_left::Coord
    upper_right::Coord
end

"""
    type Region

The volume that is defined by a surface and one of its halfspaces

# Constructors
* `Region(surface::Surface, halfspace::Int64)`

# Arguments
* `surface::Surface`: A `Sphere`, `Plane`, or `InfCylinder`
* `halfspace::Int64`: Either +1 or -1
"""
type Region
    surface::Surface
    halfspace::Int64
end

"""
    type Cell

Defined by an array of regions and the logical combination of those regions that define the cell

# Constructors
* `Cell(regions::Array{Region}, definition::Expr)`

# Arguments
* `regions::Array{Region}`: An array of regions that are used to define the cell
* `definition::Expr`: A logical expression that defines the volume of the cell. The intersection operator is ^, the union operator is |, and the complement operator is ~. Regions are defined by their integer indices in the regions array.
"""
type Cell
    regions::Array{Region}
    definition::Expr
end

"""
    type Geometry

The top level object that holds all the cells in the problem. This object contains all data regarding the geometry within a system.

# Constructors
* `Geometry(cells::Array{Cell}, bounding_box::Box)`

# Arguments
* `cells::Array{Cell}`: All cells inside the geometry. The cells must combine to fill the entire space of the bounding box. No two cells should overlap.
* `bounding_box::Box`: The bounding box around the problem.
"""
type Geometry
    cells::Array{Cell}
    bounding_box::Box
end

_p = Coord(0,0,0)
typeassert(_p, Coord)

import Base: +, -, *, ^, |, ~, dot, cross
+(a::Coord, b::Coord)     = Coord(a.x+b.x, a.y+b.y, a.z+b.z)
-(a::Coord, b::Coord)     = Coord(a.x-b.x, a.y-b.y, a.z-b.z)
*(a::Float64, b::Coord)   = Coord(a*b.x, a*b.y, a*b.z)
*(b::Coord, a::Float64,)  = Coord(a*b.x, a*b.y, a*b.z)
*(a::Int, b::Coord)       = Coord(a*b.x, a*b.y, a*b.z)
*(b::Coord, a::Int)       = Coord(a*b.x, a*b.y, a*b.z)
dot(a::Coord, b::Coord)   = (a.x*b.x + a.y*b.y + a.z*b.z)
"""
    magnitude(a::Coord)

A utility function to determine the magnitude of a `Coord` object. Typical use case is to subtract two Coord objects and check the resulting Coord object's magnitude to determine the distance between the two Coords.
"""
magnitude(a::Coord)       = sqrt(dot(a,a))
"""
    unitize(a::Coord)

A utility function to unitize a `Coord`
"""
unitize(a::Coord)         = (1. / magnitude(a) * a)
cross(a::Coord, b::Coord) = Coord(a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x)


# Ray - 3D Plane Intersection
# Returns: hit, distance
# hit: a boolean indicating if an intersection occurred
# distance: the distance to intersection
# Edge case policies:
#    1. Ray is inside the plane: Returns (true, NaN)
#    2. Ray is parallel to the plan, but not inside: Returns (false, NaN)
#    3. Ray never hits plane: Returns (false, NaN)
"""
    function raytrace(ray::Ray, surface::Surface)

Determines if a `Ray` and a `Surface` intersect, and the distance to that intersection.

# Returns
* `Bool`: Indicates if the ray intersects the surface or not
* `Float64`: The distance between the ray's origin and the point of intersection
"""
function raytrace(ray::Ray, plane::Plane)
    dist::Float64 = dot( plane.point - ray.origin, plane.normal) / dot( ray.direction, plane.normal)
    # Check if parallel
    if dist < 0 || dist == Inf
        return false, NaN
    end
    return true, dist
end

# Ray - 3D Cone Intersection
# Returns hit, distance
# hit: a boolean indicating if an intersection occurred (false if parallel or negative)
# dist: distance to closest intersection point
function raytrace(ray::Ray, cone::Cone)

	cos_theta_squared::Float64 = (cos(cone.theta))^2
	CO::Coord = ray.origin - cone.tip

	a::Float64 = dot(ray.direction, cone.axis)^2 - cos_theta_squared
	b::Float64 = 2.0 * (dot(ray.direction, cone.axis) * dot(CO, cone.axis) - dot(ray.direction, CO) * cos_theta_squared)
	c::Float64 = dot(CO, cone.axis)^2 - dot(CO, CO) * cos_theta_squared

	determinant::Float64 = b^2 - 4.0*a*c

	if determinant < 0
		return false, NaN
	elseif determinant == 0
		return true, -b/(2*a)
	end

	# Now we need to verify we are not intersecting with the shadow cone
	one_over_two_a::Float64 = 1.0 / (2.0 * a)
	t1::Float64 = (-b - sqrt(determinant)) * one_over_two_a
	t2::Float64 = (-b + sqrt(determinant)) * one_over_two_a

	p1::Coord = ray.origin + ray.direction * t1
	p2::Coord = ray.origin + ray.direction * t2

	valid1::Bool = false
	valid2::Bool = false

	# Check against shadow cone & ensure intersection is in front of ray
	if t1 >= 0 && dot((p1-cone.tip),cone.axis) > 0
		valid1 = true
	end
	if t2 >= 0 && dot((p2-cone.tip),cone.axis) > 0
		valid2 = true
	end

	# If both points hit real cone, return closer one
	if valid1 && valid2
		if t1 < t2
			return true, t1
		else
			return true, t2
		end
	end

	if valid1 && !valid2
		return true, t1
	end

	if !valid1 && valid2
		return true, t2
	end

	return false, NaN
end

# Ray - 3D Sphere Intersection
# Returns hit, distance
# hit: a boolean indicating if an intersection occurred (false if parallel or negative)
# dist: distance to closest intersection point
function raytrace(ray::Ray, sphere::Sphere)
    d::Coord = ray.origin - sphere.center
    t::Float64 = -dot(ray.direction, d)
    discriminant::Float64 = t^2
    discriminant -= magnitude(d)^2
    discriminant += sphere.radius^2

    # If the discriminant is less than zero, they don't hit
    if discriminant < 0
        return false, Inf
    end
    sqrt_val::Float64 = sqrt(discriminant)
    pos::Float64 = t - sqrt_val
    neg::Float64 = t + sqrt_val

    if pos < 0  && neg < 0
        return false, NaN
    end
    if pos < 0 && neg > 0
        return true, neg
    end
    if pos < neg && pos > 0
        return true, pos
    end

    return true, neg
end

# Ray - 3D Infinite Cylinder Intersection (works for cylinder direction)
# Returns hit, distance
# hit: a boolean indicating if an intersection occurred (false if parallel or negative)
# dist: distance to closest intersection point
function raytrace(ray::Ray, infcylinder::InfCylinder)
    A = infcylinder.center
    # Generate point new point in cylinder for math
    B = infcylinder.center + infcylinder.normal
    O = ray.origin
    r = infcylinder.radius
    AB = B - A
    AO = O - A
    AOxAB = cross(AO, AB)
    VxAB = cross(ray.direction, AB)
    ab2::Float64 = dot(AB, AB)
    a::Float64 = dot(VxAB, VxAB)
    b::Float64 = 2.0 * dot(VxAB, AOxAB)
    c::Float64 = dot(AOxAB, AOxAB) - (r*r * ab2)

    # Check Determininant
    det::Float64 = b^2 - 4.0 * a * c
    if det < 0
        return false, Inf
    end

    pos::Float64 = (-b + sqrt(det)) / (2.0 * a)
    neg::Float64 = (-b - sqrt(det)) / (2.0 * a)

    if pos < 0
        if neg < 0
            return false, NaN
        end
        return true, neg
    end
    if neg < 0
        return true, pos
    end
    if pos < neg
        return true, pos
    else
        return true, neg
    end
end

"""
    reflect(ray::Ray, plane::Plane)

Reflects a ray off a plane.

# Return
* `Ray`: A new ray with the same origin as input, but with the new reflected direction
"""
function reflect(ray::Ray, plane::Plane)
    a = dot(ray.direction, plane.normal)
    b = plane.normal * (2.0 * a)
    c = ray.direction - b
    reflected_ray::Ray = Ray(ray.origin, c)
    return reflected_ray
end

"""
    generate_random_ray(box::Box)

Returns a randomly sampled ray from within an axis aligned bounding box.
"""
function generate_random_ray(box::Box)
    ray = Ray(Coord(0.0, 0.0, 0.0), Coord(0.0, 0.0, 0.0))

    # Sample Origin
    width = Coord(box.upper_right.x - box.lower_left.x, box.upper_right.y - box.lower_left.y, box.upper_right.z - box.lower_left.z)
    ray.origin.x = box.lower_left.x + rand(Float64)*width.x
    ray.origin.y = box.lower_left.y + rand(Float64)*width.y
    ray.origin.z = box.lower_left.z + rand(Float64)*width.z

    # Sample Direction From Sphere
    theta::Float64 = rand(Float64) * 2.0 * pi
    z::Float64 = -1.0 + 2.0 * rand(Float64)
    zo::Float64 = sqrt(1.0 - z*z)
    ray.direction.x = zo * cos(theta);
    ray.direction.y = zo * sin(theta);
    ray.direction.z = z;

    # Normalize Direction
    ray.direction = unitize(ray.direction)

    return ray
end

"""
    find_intersection(ray::Ray, regions::Array{Region})

Performs ray tracing on an array of regions.

# Return
* `Ray`: A new Ray that has been moved just accross the point of intersection.
* `Int64`: The surface id that was hit.
* `String`: The boundary condition of the surface that was hit.
"""
function find_intersection(ray::Ray, regions::Array{Region})
    BUMP::Float64 = 1.0e-9
    min::Float64 = 1e30
    id::Int64 = -1
    for i = 1:length(regions)
        hit, dist = raytrace(ray, regions[i].surface)
        if hit == true
            if dist < min
                min = dist
                id = i
            end
        end
    end

    new_ray::Ray = Ray(ray.origin + ray.direction * (min + BUMP), ray.direction)

    if regions[id].surface.reflective == true
        new_ray = reflect(new_ray, regions[id].surface)
        new_ray.origin = new_ray.origin + new_ray.direction * (2.0 * BUMP)
		return new_ray, id, "reflective"
    end

	if regions[id].surface.vacuum == true
		return new_ray, id, "vacuum"
    end

    return new_ray, id, "transmission"

end

"""
    find_intersection(ray::Ray, geometry::Geometry)

Performs ray tracing on a Geometry

# Return
* `Ray`: A new Ray that has been moved just accross the point of intersection.
* `Int64`: The surface id that was hit.
* `String`: The boundary condition of the surface that was hit.
"""
function find_intersection(ray::Ray, geometry::Geometry)
	cell_id = find_cell_id(ray.origin, geometry)
	regions::Array{Region} = geometry.cells[cell_id].regions
	return find_intersection(ray, regions)
end


# The halfpsace functions are private methods, and all take a coordinate and a surface to determine which halfspace the coordinate is in.

# Plane halfspace determination
function halfspace(c::Coord, plane::Plane)
    d::Float64 = -dot(plane.normal, plane.point)
    half::Float64 = dot(plane.normal, c) + d
    if half <= 0
        return -1
    else
        return 1
    end
end

# Cone halfspace determination
function halfspace(c::Coord, cone::Cone)
	p_minus_c::Coord = c - cone.tip
    half::Float64 = dot(p_minus_c,cone.axis)^2 - dot(p_minus_c,p_minus_c) * (cos(cone.theta))^2
    if half <= 0
        return -1
    else
        return 1
    end
end

# Sphere halfspace determination
function halfspace(c::Coord, sphere::Sphere)
    half::Float64 = (c.x - sphere.center.x)^2 + (c.y - sphere.center.y)^2 + (c.z - sphere.center.z)^2 - sphere.radius^2
    if half <= 0
        return -1
    else
        return 1
    end
end

# Infinite cylinder halfspace
function halfspace(c::Coord, cyl::InfCylinder)
    tmp::Coord = cross((c-cyl.center), cyl.normal)
    half::Float64 = dot(tmp, tmp) - cyl.radius^2
    if half <= 0
        return -1
    else
        return 1
    end
end


function ^(a::Region, b::Region)
    if halfspace(_p, a.surface) == a.halfspace
        if halfspace(_p, b.surface) == b.halfspace
            return true
        end
    end
    return false
end

function ^(a::Region, b::Bool)
    if halfspace(_p, a.surface) == a.halfspace
        if b == true
            return true
        end
    end
    return false
end

function ^(b::Bool, a::Region)
    if halfspace(_p, a.surface) == a.halfspace
        if b == true
            return true
        end
    end
    return false
end

function |(a::Region, b::Region)
    if halfspace(_p, a.surface) == a.halfspace
        return true
    end
    if halfspace(_p, b.surface) == b.halfspace
        return true
    end
    return false
end

function |(a::Region, b::Bool)
    if halfspace(_p, a.surface) == a.halfspace
        return true
    end
    if b == true
        return true
    end
    return false
end

function |(b::Bool, a::Region)
    if halfspace(_p, a.surface) == a.halfspace
        return true
    end
    if b == true
        return true
    end
    return false
end

function ~(a::Region)
    b::Region = Region(a.surface, a.halfspace)
    if a.halfspace == -1
        b.halfspace = 1
    else
        b.halfspace = -1
    end
    return b
end

"""
    is_in_cell(p::Coord, cell::Cell)

Determines if a point (such as a Ray origin) is inside a given cell
"""
function is_in_cell(p::Coord, cell::Cell)
    result = navigate_tree(p, cell.regions, cell.definition)
    return result
end

function navigate_tree(p::Coord, r::Array{Region}, ex::Expr)
    global _p = Coord(p.x, p.y, p.z)

	# Check if Complement
	if ex.args[1] == :~
		if typeof(ex.args[2]) == typeof(1)
			return ~ r[ex.args[2]]
		else
			return ~ navigate_tree(p, r, ex.args[2])
		end
	end

	if typeof(ex.args[2]) == typeof(1)
		# Case 1 - Both operands are leaves
		if typeof(ex.args[3]) == typeof(1)
			if ex.args[1] == :^
            	return r[ex.args[2]] ^ r[ex.args[3]]
			end
			if ex.args[1] == :|
            	return r[ex.args[2]] | r[ex.args[3]]
			end
		end
		# Case 2 - Left operand is leaf, right is not
		if typeof(ex.args[3]) != typeof(1)
			if ex.args[1] == :^
            	return r[ex.args[2]] ^ navigate_tree(p, r, ex.args[3])
			end
			if ex.args[1] == :|
            	return r[ex.args[2]] | navigate_tree(p, r, ex.args[3])
			end
		end
	end

	if typeof(ex.args[2]) != typeof(1)
		# Case 3 - left operand is not leaf, but right is
		if typeof(ex.args[3]) == typeof(1)
			if ex.args[1] == :^
            	return navigate_tree(p, r, ex.args[2]) ^ r[ex.args[3]]
			end
			if ex.args[1] == :|
            	return navigate_tree(p, r, ex.args[2]) | r[ex.args[3]]
			end
		end
		# Case 4 - Neither operand is a leaf
		if typeof(ex.args[3]) != typeof(1)
			if ex.args[1] == :^
            	return navigate_tree(p, r, ex.args[2]) ^ navigate_tree(p, r, ex.args[3])
			end
			if ex.args[1] == :|
            	return navigate_tree(p, r, ex.args[2]) | navigate_tree(p, r, ex.args[3])
			end
		end
	end
end

"""
    find_cell_id(p::Coord, geometry::Geometry)

Finds the cell id that a point resides within
"""
function find_cell_id(p::Coord, geometry::Geometry)
    for i = 1:length(geometry.cells)
        if is_in_cell(p, geometry.cells[i]) == true
            return i
        end
    end
    return -1
end

"""
    plot_geometry_2D(geometry::Geometry, view::Box, dim::Int64)

Plots a 2D x-y slice of a geometry.

# Arguments
* `geometry::Geometry`: the geometry we want to plot
* `view::Box`: The view box is an axis aligned box that defines where the picture will be taken, with both min and max z dimensions indicating the single z elevation the slice is taken at.
* `dim::Int64`: The dimension is the number of pixels along the x and y axis to use, which determines the resolution of the picture.
"""
function plot_geometry_2D(geometry::Geometry, view::Box, dim::Int64)
    delta_x = (view.upper_right.x - view.lower_left.x) / (dim)
    delta_y = (view.upper_right.y - view.lower_left.y) / (dim)

    x_coords = collect(view.lower_left.x + delta_x/2.0:delta_x:view.upper_right.x - delta_x/2.0)
    y_coords = collect(view.lower_left.y + delta_y/2.0:delta_y:view.upper_right.y - delta_y/2.0)

    pixels = Array{Int64, 2}(dim, dim)

    for i=1:dim
        for j=1:dim
            pixels[i,j] = find_cell_id(Coord(x_coords[i], y_coords[j], view.lower_left.z), geometry)
        end
    end
    pixels = rotl90(pixels)
    colors = Array{RGBA}(0)
    for i=1:length(geometry.cells)
        if (i-1)%4 == 0
            push!(colors, RGBA(1.0, 0.0, 0.0, 1.0))
        elseif (i-1)%4 == 1
            push!(colors, RGBA(0, 1.0, 0, 1.0))
        elseif (i-1)%4 == 2
            push!(colors, RGBA(1.0, 0.0, 1.0, 1.0))
        elseif (i-1)%4 == 3
            push!(colors, RGBA(0, 0, 1.0, 1.0))
        end
        #push!(colors, RGBA(rand(),rand(),rand(),1.0) )
    end
    gradient = ColorGradient(colors)
    heatmap(x_coords,y_coords,pixels,aspect_ratio=1, color=gradient, leg=false)
end

"""
    plot_cell_2D(geometry::Geometry, view::Box, dim::Int64, cell_id::Int64)

Plots a 2D x-y slice of a geometry, highlighting a specific cell in black.

# Arguments
* `geometry::Geometry`: the geometry we want to plot
* `view::Box`: The view box is an axis aligned box that defines where the picture will be taken, with both min and max z dimensions indicating the single z elevation the slice is taken at.
* `dim::Int64`: The dimension is the number of pixels along the x and y axis to use, which determines the resolution of the picture.
* `cell_id::Int64`: The index of the cell we wish to view
"""
function plot_cell_2D(geometry::Geometry, view::Box, dim::Int64, cell_id::Int64)
    delta_x = (view.upper_right.x - view.lower_left.x) / (dim)
    delta_y = (view.upper_right.y - view.lower_left.y) / (dim)

    x_coords = collect(view.lower_left.x + delta_x/2.0:delta_x:view.upper_right.x - delta_x/2.0)
    y_coords = collect(view.lower_left.y + delta_y/2.0:delta_y:view.upper_right.y - delta_y/2.0)

    pixels = Array{Int64, 2}(dim, dim)

    for i=1:dim
        for j=1:dim
            pixels[i,j] = find_cell_id(Coord(x_coords[i], y_coords[j], view.lower_left.z), geometry)
            if pixels[i, j] == cell_id
                pixels[i, j] = 0
            else
                pixels[i, j] = 1
            end
        end
    end
    pixels = rotl90(pixels)
    colors = Array{RGBA}(0)
    push!(colors, RGBA(0.0, 0.0, 0.0, 1.0))
    push!(colors, RGBA(1.0, 1.0, 1.0, 1.0))
    gradient = ColorGradient(colors)
    heatmap(x_coords,y_coords,pixels,aspect_ratio=1, color=gradient, leg=false)
end

end # module
