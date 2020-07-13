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

For example, here is a strategy pattern for calculating the price of
drinks during happy hour in Java. This code even "cheats" a little
because it's using the new Java syntax for anonymous functions:

```Java
import java.util.ArrayList;

interface BillingStrategy {
    int getActPrice(int rawPrice);
    static BillingStrategy normalStrategy() {
        return rawPrice -> rawPrice;
    }
    static BillingStrategy happyHourStrategy() {
        return rawPrice -> rawPrice / 2;
    }
}

class Customer {
    private final List<Integer> drinks = new ArrayList<>();
    private BillingStrategy strategy;

    public Customer(BillingStrategy strategy) {
        this.strategy = strategy;
    }

    public void add(int price, int quantity) {
        this.drinks.add(this.strategy.getActPrice(price*quantity));
    }

    public void printBill() {
        int sum = this.drinks.stream().mapToInt(v -> v).sum();
        System.out.println("Total due: " + sum);
        this.drinks.clear();
    }

    public void setStrategy(BillingStrategy strategy) {
        this.strategy = strategy;
    }
}

public class StrategyPattern {
    public static void main(String[] arguments) {
        BillingStrategy normalStrategy    = BillingStrategy.normalStrategy();
        BillingStrategy happyHourStrategy = BillingStrategy.happyHourStrategy();

        Customer firstCustomer = new Customer(normalStrategy);
        firstCustomer.add(100, 1);

        firstCustomer.setStrategy(happyHourStrategy);
        firstCustomer.add(100, 2);

        Customer secondCustomer = new Customer(happyHourStrategy);
        secondCustomer.add(80, 1);

        firstCustomer.printBill();

        secondCustomer.setStrategy(normalStrategy);
        secondCustomer.add(130, 2);
        secondCustomer.add(250, 1);
        secondCustomer.printBill();
    }
}
```

Here's a Julia program to do the same thing:

```julia
happy_hour_price(x) = x÷2
normal_price(x) = x

struct Customer
    drinks::Vector{Int}
end
Customer() = Customer(Int[])

add_drink!(c::Customer, strategy, price, quantity) =
    push!(c.drinks, strategy(price * quantity))

function print_bill!(c::Customer)
    println("total due: ", sum(c.drinks))
    empty!(c.drinks)
end

function main()
    strategy = normal_price
    add!(customer, price, quantity) =
        add_drink!(customer, strategy, price, quantity)

    first_customer = Customer()
    add!(first_customer, 100, 1)
    
    strategy = happy_hour_price
    add!(first_customer, 100, 2)

    second_customer = Customer()
    add!(second_customer, 80, 1)

    print_bill!(first_customer)

    strategy = normal_price
    add!(second_customer, 130, 2)
    add!(second_customer, 250, 1)
    print_bill!(second_customer)
end
```

Let's forget about the main function for a moment because it's
essentially the same in both cases.

```Java
interface BillingStrategy {
    int getActPrice(int rawPrice);
    static BillingStrategy normalStrategy() {
        return rawPrice -> rawPrice;
    }
    static BillingStrategy happyHourStrategy() {
        return rawPrice -> rawPrice / 2;
    }
}

class Customer {
    private final List<Integer> drinks = new ArrayList<>();
    private BillingStrategy strategy;

    public Customer(BillingStrategy strategy) {
        this.strategy = strategy;
    }

    public void add(int price, int quantity) {
        this.drinks.add(this.strategy.getActPrice(price*quantity));
    }

    public void printBill() {
        int sum = this.drinks.stream().mapToInt(v -> v).sum();
        System.out.println("Total due: " + sum);
        this.drinks.clear();
    }

    public void setStrategy(BillingStrategy strategy) {
        this.strategy = strategy;
    }
}
```

Compared with the Julia version:

```julia
happy_hour_price(x) = x÷2
normal_price(x) = x

struct Customer
    drinks::Vector{Int}
    Customer() = new(Int[])
end

add_drink!(c::Customer, strategy, price, quantity) =
    push!(c.drinks, strategy(price * quantity))

function print_bill!(c::Customer)
    println("total due: ", sum(c.drinks))
    empty!(c.drinks)
end
```

The use of first-class functions (i.e. functions as values) makes
implementation of `Customer` much simpler and the implementation of
`BillingStrategy` completely unnecessary.

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

In Julia, the data layout of objects is defined as a `struct`. This is
like C and many other languages. A `struct` definition looks like this:

```julia
struct Point
    x::Float64
    y::Float64
end
```

It's a block that has the name of the `struct` followed by a list of
fields and their types. The types of fields are technically optional,
but this is one of the few places in Julia where type declarations
make a big difference for performance. Unless it's a case where
performance absolutely doesn't matter, you should be putting types on
your `struct` fields.

Defining a struct also creates a constructor (which can be overridden):

```julia
julia> mypoint = Point(5, 7)
Point(5.0, 7.0)
```
