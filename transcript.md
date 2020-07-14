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

Most of the material in this talk, along with a bit more, is available
as a notebook here:
https://github.com/ninjaaron/oo-and-polymorphism-in-julia

I should also say that many of the things I will talk about now were
covered some years ago in a great blog post by Chris Rackaucus,
[Type-Dispatch Design: Post Object-Oriented Programming for Julia](
http://www.stochasticlifestyle.com/type-dispatch-design-post-object-oriented-programming-julia/),
which is linked in the github repo for this talk.

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
Stacktrace:
 [1] setproperty!(::Point, ::Symbol, ::Float64) at ./Base.jl:34
 [2] top-level scope at REPL[4]:1
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

end # module Shape


module Circle
import ..Shape

struct T <: Shape.T
    diameter::Float64
end
radius(c::T) = c.diameter / 2
Shape.area(c::T) = π * radius(c) ^ 2

end # module Circle
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

Coming back to the `Point` example from earlier
