For example, here is a strategy pattern for calculating the price of
drinks during happy hour in Java. This code even "cheats" a little
because it's using the new Java syntax for anonymous functions:

```java
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

main()
```

Let's forget about the main function for a moment because it's
essentially the same in both cases.

```java
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
