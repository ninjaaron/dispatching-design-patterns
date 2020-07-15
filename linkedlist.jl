struct Nil end

struct List{T}
    head::T
    tail::Union{List{T}, Nil}
end

# built a list from an array
mklist(array::AbstractArray{T}) where T =
    foldr(List{T}, array, init=Nil())

# implement the iteration protocol
Base.iterate(l::List) = iterate(l, l)
Base.iterate(::List, l::List) = l.head, l.tail
Base.iterate(::List, ::Nil) = nothing
