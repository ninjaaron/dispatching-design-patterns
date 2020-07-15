struct FooBar end

# default case: error out
FooBar(::T) where T = FooBar(T)
FooBar(T::Type) = 
    error("Type $T doesn't implement the FooBar interface.")

add_foo_and_bar(x) = add_foo_and_bar(FooBar(x), x)
add_foo_and_bar(::FooBar, x) = foo(x) + bar(x)

register_foobar(T::Type) =
    if hasmethod(foo, Tuple{T}) && hasmethod(bar, Tuple{T})
        @eval FooBar(::Type{$T}) = FooBar()
    else
        error("Type $T must implement `foo` and `bar` methods")
    end
