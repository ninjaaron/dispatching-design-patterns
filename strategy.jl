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
