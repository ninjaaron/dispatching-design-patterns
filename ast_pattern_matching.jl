macro replace_1_with_x(expr)
   esc(replace_1(expr))
end

replace_1(atom) = atom == 1 ? :x : atom
replace_1(e::Expr) =
    Expr(e.head, map(replace_1, e.args)...)

