
Great links related to this talk.

Most of the material in this talk, along with a bit more, is available
as a notebook here:
https://github.com/ninjaaron/oo-and-polymorphism-in-julia

I should also say that many of the things I will talk about now were
covered some years ago in a great blog post by Chris Rackaucus,
[Type-Dispatch Design: Post Object-Oriented Programming for Julia](
http://www.stochasticlifestyle.com/type-dispatch-design-post-object-oriented-programming-julia/),
which is linked in the github repo for this talk.

Tom Kwong also has a (relatively) new book about Design patterns in
Julia which is helpful, [Hands-On Design Patterns and Best Practices
with Julia](
https://www.packtpub.com/eu/application-development/hands-design-patterns-julia-10).

Old Peter Norvig talk about design patterns in Dynamic languages:
http://www.norvig.com/design-patterns/

It's mostly about Dylan, which is kind of a legacy language, but in
many ways it is a close cousin of Julia with a very similar feature
set. (It's semantically a Lisp, but it has "normal" syntax, very much
like Julia) For this reason, many of the things he addresses in the
talk are applicable to Julia as well.

# Dispatching Design Patterns

> design pattern:
>
> 1. A formal way of documenting a general reusable solution to a
>    design problem in a particular field of expertise.

(wiktionary.org)

> dispatch:
>
> [...]
>
> 7. To destroy quickly and efficiently.
> 8. (computing) To pass on for further processing,
>    especially via a dispatch table [...]

(also wiktionary.org)

Julia is a different kind of programming language. Most Julia users
come to the language because it combines the intuitive, high-level
abstractions of dynamic languages like Python or Matlab with
performance that rivals statically compiled languages like
Fortran or C++ in some cases.

However, while this is Julia's "claim to fame", there are many
additional qualities which distinguish Julia from more mainstream
programming languages. Specifically, Julia's type system looks more
like the type systems found in functional programming
languages---taking influence both from Common Lisp, as well as,
perhaps to a lesser extent, from ML-style languages like Haskell
and OCaml

Perhaps the most striking thing for users coming from a language like
Python, Java, or C++ is that Julia has no classes. I feel that what
Julia has is much better, but for programmers oriented towards
objects, Julia's approach can be disorienting.

## Dispatching the Gang of Four

I'm pretty active on Quora.com, and one of the most frequent
complaints I see there (and elsewhere) about Julia is that the lack of
classes makes it difficult to use for large software projects. I
believe this is because many of the most widely taught software design
patterns presuppose the availability of classes in a language---though
of course many are just complaining that you can't inherit data layout
from a super type. I would remind those people that inheriting data
layout breaks the principle of dependency inversion (i.e. one should
depend on abstractions, not concretions)

The good news for the former group (those who miss their
object-oriented design patterns) is that Julia's high-level
abstractions provide a built-in way to eliminate many of the problems
these design patterns were originally intended to address. A classic
example is the strategy pattern, where you may want to use one
approach to a problem in a one context and approach in another
context. In a language like Julia with first-class functions,
different "strategies" (i.e. functions) can simply be passed around as
function arguments, so classes are unnecessary.

This is just one example, but if you want more, there is an old Peter
Norvig talk called _Design Patterns in Dynamic Programming_ where he
discusses these things, as well as patterns that emerge in dynamic
programming languages---almost all of which are applicable to
Julia. (The example language in the talk, Dylan, is one of Julia's
nearest neighbors in terms of design)

slides here: http://www.norvig.com/design-patterns/

In this sense, Julia "dispatches" many traditional design patterns by
providing flexible high-level language features.

However, the main thrust of this talk about design patterns that
emerge specifically for Julia and how create fast, flexible data
structures and interfaces in the Julian way using structs, methods,
abstract types, and parameterized types---design patterns based on
Julia's unique approach to method dispatch.


For me, the best features of object orientation are the ability to
encapsulate complexity in a simple interface and the ability to write
flexible, polymorphic. Julia is one of the best languages out there
when it comes to flexibility and polymorphism. It has good parts and
bad parts when it comes to encapsulation, but I want to show you how
to make the most of the good parts.

## Encapsulation

### Structs

In Julia, the data layout of objects is defined as a `struct`. This is
like C and many other languages. A `struct` definition looks like this:

```julia
struct Point
    x::Float64
    y::Float64
end
```

It's a block that has the name of the `struct` followed by a list of
field names and their types. The types of fields are technically optional,
but this is one of the few places in Julia where type declarations
make a big difference for performance. Unless it's a case where
performance absolutely doesn't matter, you should be putting types on
your `struct` fields. Later we'll come back and look at how to make
these fields polymorphic without sacrificing the performance.

Defining a struct also creates a constructor:

```julia
julia> mypoint = Point(5, 7)
Point(5.0, 7.0)
```

Attribute access should also look familiar:

```julia
julia> mypoint.x
5.0
```

One thing you may notice if you're familiar with more strict object
oriented languages is that there is no privacy for struct fields in
Julia. For better or for worse, Julia, like Python, relies on the
discipline of the user not to rely on implementation details of a
struct. I personally would like to see some form of enforced privacy
in a future version of Julia, perhaps at a module level, but this is
what we have for now.

To package authors, I would recommend using the Python convention of
prefixing field names of private attributes with an underscore, and to
library users, I would recommend never accessing struct fields
directly unless invited to do so in the package documentation. Relying
on code that is considered an implementation detail by the package's
author is a recipe for pain.

On the bright side, Julia's structs are immutable by default, which I
suppose is a limited form of access control---not to mention, it's a
guarantee that the compiler can use to preform some interesting
optimizations.

If we try to change an immutable struct in place, we get an error:

```julia
julia> mypoint.x = 3.0
ERROR: setfield! immutable struct of type Point cannot be changed
```

This is often a good thing. In the case of a point, it's a way to
designate a fixed location. However, perhaps we want to define an
entity that can change locations:

```julia
julia> mutable struct Starship
           name::String
           location::Point
       end

julia> ship = Starship("U.S.S. Enterprise", Point(5, 7))y
Starship("U.S.S. Enterprise", Point(5.0, 7.0))
```

We can now "move" the ship by changing its location:

```julia
ship.location = Point(6, 8)
```

Let's say we don't want to to use the `Point` constructor explicitly
every time we create new ship. Adding an alternative constructor for
an object is as easy as adding a new dispatch to a function:

```julia
julia> Starship(name, x, y) = Starship(name, Point(x, y))
Starship

julia> othership = Starship("U.S.S. Defiant", 10, 2)
Starship("U.S.S. Defiant", Point(10.0, 2.0))
```

You _override_ the default constructor for a struct by defining a
constructor inside of the struct's definition, using the `new` keyword
to access the default constructor internally:

```julia
julia> mutable struct FancyStarship
           name::String
           location::Point
           FancyStarship(name, x, y) = new(name, Point(x, y))
       end

julia> fancy = FancyStarship("U.S.S. Discovery", 14, 32)
fancy = FancyStarship("U.S.S. Discovery", 14, 32)
```

This could be used, for example, to insure that initialization values
fall with a certain valid range.

### Methods

In general, you don't want your user to have to care how your starship
is implemented. You simply give an interface for how it acts. If
someone wants to move their ship, a function should be supplied to
allow them to do so without the need for extra math.

```julia
function move!(starship, heading, distance)
    Δx = distance * cosd(heading)
    Δy = distance * sind(heading)
    old = starship.location
    starship.location = Point(old.x + Δx, old.y + Δy)
end
```

Then we can move our ships like this:

```julia
julia> foo_ship = Starship("Foo", 3, 4)
Starship("Foo", Point(3.0, 4.0))

julia> move!(foo_ship, 45, 1.5)
Point(4.060660171779821, 5.060660171779821)
```

This may be so obvious it goes without saying. Where it gets
interesting is when we start adding multiple methods to functions for
different types. Yes---in Julia, methods belong to functions, not to
data types. However, methods can still be defined in terms of types
(as well as number of arguments).

As a very basic example, let's compare a struct for a square and a
rectangle:

```julia
struct Rectangle
    width::Float64
    height::Float64
end
width(r::Rectangle) = r.width
height(r::Rectangle) = r.height

struct Square
    length::Float64
end
width(s::Square) = s.length
height(s::Square) = s.length
```

We need to know the width and height to define a rectangle, but for a
square, we only need to store length of one side. However, since a
Square is also a kind of rectangle, we want to give it the same
interface, defining width and height functions for it as well.

We use the type declarations here to show that these are different
function methods for different types. The compiler keeps track of this
information and will select the right method based on the input
types. Note that type declarations on function parameters are _not_
used to improve performance.

Once we have that basic rectangle interface, we can define an area
function that uses this interface and does the right thing for both
squares and rectangles:

```julia
julia> area(shape) = width(shape) * height(shape)
area (generic function with 1 method)

julia> area(Rectangle(3, 4))
12.0

julia> area(Square(3))
9.0
```

Because methods in Julia can be defined in terms of types, they can do
everything methods can do in a language with classes---they can simply
do other things as well!

## Polymorphism

### Abstract Types

_Polymorphism_ in programming just means that you can reuse the same
code for different types. Julia is really good at this.

In the previous example, we defined an `area` function that would work
with any type that provides `height` and `width` methods. This sort of
"free" polymorphism is very common in Julia, but sometimes it can be
useful to organize interfaces in a more constrained, hierarchical
way. To do this, we would use abstract types. In Julia, abstract types
have no data layout. They can only used for sub-typing and for
type declarations on function methods.

Continuing with shapes, let's define our first abstract type:

```julia
"""Types which inherit from `Shape` should provide an
`area` method.
"""
abstract type Shape end
```

Julia doesn't currently provide a way to define interface constrains
for subtypes, so I've added a doc string that explains the required
interface for anyone who wishes to subtype from this abstract
type. Now, let's give it a method:

```julia
combined_area(a::Shape, b::Shape) = area(a) + area(b)
```

Now let's define struct that is a subtype of `Shape` and provides the
necessary `area` interface:

```julia
struct Circle <: Shape
    diameter::Float64
end
radius(c::Circle) = c.diameter / 2
area(c::Circle) = π * radius(c) ^ 2
```

Form `TypeName <: AbstractType` is used to declare that `TypeName` is
a subtype of `AbstractType` in the context of a struct definition. In
an expression, the same syntax is used to test if one type is a
subtype of another.

An abstract type can also be a subtype of another abstract type:

```julia
"""Types which inherit from `AbstractRectangle should
provide `height` and `width` methods.
"""
abstract type AbstractRectangle <: Shape end
area(r::AbstractRectangle) = width(r) * height(r)
```

Here, we make an `AbstractRectangle` type which is a subtype of
`Shape`, and provides a function for computing the area of a
rectangle. From there, we can once again define our concrete rectangle
types from earlier, but this time inheriting from `AbstractRectangle`:

```julia
struct Rectangle <: AbstractRectangle
    width::Float64
    height::Float64
end
width(r::Rectangle) = r.width
height(r::Rectangle) = r.height
 
struct Square <: AbstractRectangle
    length::Float64
end
width(s::Square) = s.length
height(s::Square) = s.length
```

Using this approach, we can combine the areas of different shapes in
arbitrary ways:

```julia
c = Circle(3)
s = Square(3)
r = Rectangle(3, 2)

@assert combined_area(c, s) == 16.068583470577035
@assert combined_area(s, r) == 15.0
```

Julia's method resolution algorithm can find the right execution path
for each shape, even though the exact code is different in every
case. What's more, in cases where the code is _type stable_, this
polymorphism has no runtime cost. Cases that require runtime
polymorphism do, of course, have a cost.

### Code organization with modules

One possible downside of the flexibility of Julia's approach to
defining structs and methods is that it doesn't provide an obvious
method for code organization. Methods for different types can be
defined anywhere. Sometimes this is useful, but it isn't necessarily
the best way to organize your code. I've been working with OCaml a lot
recently, and the way the language uses modules to encapsulate types
got me thinking that a similar approach might be helpful in
Julia. This should pattern should be seen as somewhat provisional,
since I haven't observed it in Julia code in the wild. Nonetheless,
here it is:
```julia
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
```

This approach is obviously quite boiler-plate-y for a short program,
but I think it may be useful in larger projects and libraries, because
it makes it explicit where the struct is implementing the interface of the
abstract type, and it is also more friendly to tab completion
(something people sometimes complain about in Julia), since the
methods specific to a certain type are in the type's module.

This is just one suggestion for how one might approach code
organization in the absence of classes similar to what some other
languages use. I'm putting it out into the universe to see what
happens.

### Parametric Types: statically typed dynamic typing

Parametric types (known as "generics" in some languages) don't really
give you dynamic typing, but languages like Haskell and OCaml that use
them everywhere can almost feel dynamically typed because of the
flexibility they provide. Julia is already dynamically typed, but type
parameters give extra information to the compiler to help it create
efficient code without having to pin down specific types at dev time.

Coming back to the `Point` example from earlier, one potential
weakness is that it only works with `Float64` types. However, we might
want it to work with other types as well. What we can do is declare a
struct as a _type constructor_. This isn't the same as an object
constructor. This is an incomplete type that takes another type as a
parameter to complete it. Here's an example:

```julia
julia> struct Point{T}
           x::T
           y::T
       end

julia> Point(1, 3)
Point{Int64}(1, 3)
```

Here, `struct Point{T}` shows that we are declaring a type constructor
for concrete types where the type variable `T` is filled in with
another type. `T` could be anything. It's just a convention.

`x::T` and `y::T` shows that both `x` and `y` will be of type T when
the value of T is known. The types for type variables can be specified
manually with the constructor, but it is normally inferred from the
input arguments. Here, we use `Int64`s as the input arguments, so
`Int64` becomes the type parameter. Now, because both `x` and `y` are
specified in terms of the same type variable, they must be the same
type.

```julia
julia> Point(1, 3.0)
ERROR: MethodError: no method matching Point(::Int64, ::Float64)
Closest candidates are:
  Point(::T, ::T) where T at REPL[2]:2
```

If we want different types (which would sort of be unusual in the
context of a point, though perhaps there could be a good reason), we
would use two type variables in the struct definition:

```julia
julia> struct TwoTypePoint{X,Y}
           x::X
           y::Y
       end

julia> TwoTypePoint(1, 3.0)
TwoTypePoint{Int64,Float64}(1, 3.0)
```

One thing to keep in mind about the type variables we've used so far
is that they are unconstrained, so they could literally be anything:

```julia
julia> Point("foo", "bar")
Point{String}("foo", "bar")
```

Obviously a point with strings for `x` and `y` is a pretty bad idea
and breaks a lot of assumptions about what a point is by functions
that might deal with this type. We probably want to limit the
constructor to only working with numeric types. We _could_ do this with
an absract type:

```julia
julia> struct RealPoint
           x::Real
           y::Real
       end

julia> RealPoint(0x5, 0xaa)
RealPoint(0x05, 0xaa)
```

This _works_, but it doesn't insure that both `x` and `y` are the same
concrete type, and much more importantly, it makes it impossible for
the compiler to infer the concrete types of `x` and `y`, meaning it
cannot optimize very well.

What we can do instead is constrain the type variable:

```julia
julia> struct Point{T <: Real}
           x::T
           y::T
       end

julia> Point(1, 3)
Point{Int64}(1, 3)

julia> Point(1.4, 2.5)
Point{Float64}(1.4, 2.5)

julia> Point("foo", "bar")
ERROR: MethodError: no method matching Point(::String, ::String)
```

Using this approach, we can make reasonable type constraints, keep
good performance, and still keep our point from being limited to one
concrete numeric type.

Parameterized types are especially useful for defining container types
that are meant to store all kinds of objects. As an example, we're
going to define a linked list. This is not really a very practical
data structure in Julia, but it's easy to define, and it shows the
kind of situation where type variables are really useful.

```julia
# the list itself
struct Nil end

struct List{T}
    head::T
    tail::Union{List{T}, Nil}
end
```

So the empty struct, `Nil` is to signal the end of a list. The list
itself has one field which is the value the node contains, and a
second field which contains the rest of the list (which is either
another instance of `List{T}` or `Nil`).

```julia
# built a list from an array
mklist(array::AbstractArray{T}) where T =
    foldr(List{T}, array, init=Nil())
```

Next, we implement a function that create a list from an array (for
demonstration purposes).

```julia
# implement the iteration protocol
Base.iterate(l::List) = iterate(l, l)
Base.iterate(::List, l::List) = l.head, l.tail
Base.iterate(::List, ::Nil) = nothing
```

Finally, we implement the iteration protocol on the list, which what
`for` loops use internally. I don't want to cover this specific code
in too much detail, but this is a common theme in Julia code: If you
want to override part of Julia's syntax for your specific type, there
is usually a function somewhere in Base that you can add methods to
for your type. You have to look through the documentation to find
them, but I have a link specifically for the iteration protocol in the
notes.

https://docs.julialang.org/en/v1/base/collections/#lib-collections-iteration-1

The important thing here is that we have a basic implementation of a
linked list here that is as efficient as it can be and works with any
kind of value thanks to parametric types.

```julia
julia> list = mklist(1:3)
List{Int64}(1, List{Int64}(2, List{Int64}(3, Nil())))

julia> for val in list
           println(val)
       end
1
2
3

julia> foreach(println, mklist(["foo", "bar"]))
foo
bar
```

### The Trait Pattern

One thing I don't love about Julia's design is that types can only
inherit from one super type. Julia's types are strictly
hierarchical. This doesn't always map well to real world problems.

For example, `Int64` is a type of number, while `String` is a type of
text. However, both things can be sorted. In some languages, like
Haskell or Rust, you could explicitly add an `Ord` trait to these with
the appropriate methods to implement an interface that allows
ordering. They can implement methods from multiple traits for a more
flexible interface.

Julia doesn't have a language-level feature like this, and you could
argue that it doesn't need it. You can simply add methods to support
any interface you like without needing to say anything about it in
terms of types. However, it still can be useful in terms of mentally
mapping how different types in your code are related. In practical
terms, it can be useful for dispatching to different strategies for
different types.

The trait pattern, sometimes called "the Holy trait" after Tim Holy,
who suggested it on the Julia mailing list, emerged to address this
usecase. It is now used a fair amount in `Base` and the Julia standard
library.

As an example, let's use our newly created linked-list:

```julia
julia> map(uppercase, mklist(["foo", "bar", "baz"]))
ERROR: MethodError: no method matching length(::List{String})
Closest candidates are:
  length(::Core.SimpleVector) at essentials.jl:596
  length(::Base.MethodList) at reflection.jl:852
  length(::Core.MethodTable) at reflection.jl:938
```

The error message reports that this doesn't work because `List`
doesn't have a `length` method. This is true, but it's not the whole
story. In order to be efficient, `map` tries to determine the length
of the output in advance so it can allocate all the space needed for
the new array in advance. *However*, this is not actually
necessary. Julia arrays can be dynamically resized as they are built
up, so there `map` could still theoretically work without a `length`
method, and indeed, you can make it do this. Simply add
`Base.IteratorSize` trait---in this case of the type
`Base.SizeUnknown`. The funny thing in Julia is that the default

```julia
julia> Base.IteratorSize(::Type{List}) = Base.SizeUnknown()

julia> map(uppercase, mklist(["foo", "bar", "baz"]))
3-element Array{String,1}:
 "FOO"
 "BAR"
 "BAZ
 ```

Now, everything works as expected.

What's going on? If we look at `generator.jl` in the source code for
`Base`, we will find these lines:

```julia
abstract type IteratorSize end
struct SizeUnknown <: IteratorSize end
struct HasLength <: IteratorSize end
struct HasShape{N} <: IteratorSize end
struct IsInfinite <: IteratorSize end
```

This is the beginning of how a trait is implemented. Just descriptions
of different iterator sizes with no data layout. These traits exist
purely to give the compiler extra information. If we look down a
little further, we find code like this:

```julia
IteratorSize(x) = IteratorSize(typeof(x))
IteratorSize(::Type) = HasLength()  # HasLength is the default
```

For some reason, the default `IteratorSize` is `HasLength`. This is
great for efficiency if your type actually has a length method, but
leads to a rather unfortunate scenario if your data structure has no
length, like if it is a generator, since the error you get gives no
indication that there is any fix aside from implementing a `length`
method.

Anyway, you can use traits to efficiently implement similar patterns.
This is a simple case where there are no sub-types of the trait.

```julia
struct FooBar end

# default case: error out
FooBar(::T) where T = FooBar(T)
FooBar(T::Type) = 
    error("Type $T doesn't implement the FooBar interface.")

add_foo_and_bar(x) = add_foo_and_bar(FooBar(x), x)
add_foo_and_bar(::FooBar, x) = foo(x) + bar(x)
```

The downside here is that there is no way to tell if the type actually
implements the required interface:

```julia
julia> FooBar(Int) = FooBar()
FooBar

julia> add_foo_and_bar(3)
ERROR: MethodError: no method matching foo(::Int64)
```

We could add a registration function to ensure a registered type has
the correct interface beforehand:

```julia
register_foobar(T::Type) =
    if hasmethod(foo, Tuple{T}) && hasmethod(bar, Tuple{T})
        @eval FooBar(::Type{$T}) = FooBar()
    else
        error("Type $T must implement `foo` and `bar` methods")
    end
```

then:

```julia
julia> register_foobar(Int)
ERROR: Type Int64 must implement `foo` and `bar` methods

julia> foo(x::Int) = x + 1
foo (generic function with 2 methods)

julia> bar(x::Int) = x * 2
bar (generic function with 1 method)

julia> register_foobar(Int)
FooBar

julia> add_foo_and_bar(3)
10
```

## Dispatches for basic pattern matching

In some functional languages, you can define different function
definitions for different values. This is how one might define a
factorial function in Haskell:

```haskell
factorial 0 = 1
factorial x = x * fact (x-1)
```

That means, when the input argument is 0, the output is 1. For all
other inputs, the second definition is used, which is defined
recursively and will continue reducing the input on recursive calls by
1 until it reaches 0.

You can't do exactly this in Julia (actually, you can if you encode
numbers into types, but that makes the compiler sad). However, in
practice, this feature is often used with tags that allow functions to
deal with different input types. Because Julia functions dispatch
based on types, that usecase actually is possible.

One of the places this is most useful in Julia is when dealing with
abstract syntax trees of the sort you interact with when defining
macros, since you will often want to walk the syntax trees in a
recursive way:

```julia
macro replace_1_with_x(expr)
   esc(replace_1(expr))
end

replace_1(atom) = atom == 1 ? :x : atom
replace_1(e::Expr) =
    Expr(e.head, map(replace_1, e.args)...)
```

Here, we define an idiotic macro that replaces all instances of `1`
with `x` in the code. Because abstract syntax trees are a recursively
data structure composed of expressions containing lists of expressions
and atoms, we can define actions on the nodes we're looking for while
passing all the sub-nodes of an expression recursively to the same
replace_1 function.

```julia
julia> x = 10
10

julia> @replace_1_with_x 5 + 1
15

julia> @replace_1_with_x 5 + 1 * (3 + 1)
135

julia> @macroexpand @replace_1_with_x 5 + 1 * (3 + 1)
:(5 + x * (3 + x))
```

This approach is also useful for intercepting other types of nodes in
syntax trees, if you want them, and can be helpful when traversing any
kind of recursively-defined data structure. The linked list from above
is another good example.

```julia
julia> Base.map(f, nil::Nil) = nil 

julia> Base.map(f, l::List) = List(f(l.head), map(f, l.tail))

julia> map(uppercase, mklist(["foo", "bar"]))
List{String}("FOO", List{String}("BAR", Nil()))
```
