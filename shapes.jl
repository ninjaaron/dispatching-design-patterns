module Shape
    abstract type T end
    area(shape::T) = throw(MethodError(area, shape))
    combined_area(a::T, b::T) = area(a) + area(b)
end


module Circle
    import ..Shape

    struct T <: Shape.T
        diameter::Float64
    end
    radius(c::T) = c.diameter / 2
    Shape.area(c::T) = π * radius(c) ^ 2
end


module AbstractRectangle
    import ..Shape

    abstract type T <: Shape.T end
    width(rectangle::T) = throw(MethodError(width, rectangle))
    height(rectangle::T) = throw(MethodError(width, rectangle))
    Shape.area(r::T) = width(r) * height(r) 
end


module Rectangle
    import ..AbstractRectangle

    struct T <: AbstractRectangle.T
        width::Float64
        height::Float64
    end
    AbstractRectangle.width(r::T) = r.width
    AbstractRectangle.height(r::T) = r.height
end
 

module Square
    import ..AbstractRectangle

    struct T <: AbstractRectangle.T
        length::Float64
    end
    AbstractRectangle.width(s::T) = s.length
    AbstractRectangle.height(s::T) = s.length
end

c = Circle.T(3)
s = Square.T(3)
r = Rectangle.T(3, 2)

@show Shape.combined_area(c, s)
@show Shape.combined_area(s, r)
