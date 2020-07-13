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
programming languages---almost all of which are applicable to Julia.

slides here: http://www.norvig.com/design-patterns/
