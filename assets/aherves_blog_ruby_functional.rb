#!/usr/bin/env ruby
# Our fancy function. Could be exactly anything
square = -> x { x*x}

# some tools
minus = -> f,g { -> x { f.(x) - g.(x) } }
div   = -> f,g { -> x { f.(x) / g.(x) } }
mult  = -> f,g { -> x { f.(x) * g.(x) } }
norm  = -> f   { -> x { f.(x).abs}}
const = -> const { -> x { const} }

plus_eps = -> eps { -> f { -> x { f.(x+eps) } } }
min_eps  = -> eps { -> f { -> x { f.(x-eps) } } }

inf = -> f,g { -> x { f.(x) < g.(x) } }

# The limit operator
lim = -> f,eps,prec {
   -> x {
    inf.(norm.(minus.(plus_eps.(eps/2.0).(f), plus_eps.(eps).(f))) , const.(prec) ).(x) ? plus_eps.(eps).(f).(x) : lim.(f,eps/2.0,prec).(x)
  }
}

# The derivative scheme
derivative_sheme = -> f {
  -> x { 
  -> eps {
  div.( minus.(plus_eps.(eps).(f), min_eps.(eps).(f) ), mult.(const.(2), const.(eps))).(x)
}
}
}

# The derivative operator at precision 1e-16 is the limit of the derivative scheme
derivate = -> f{
  -> x { 
  lim.(derivative_sheme.(f).(x),1,1e-16).(0)
}
}

# call any function n times
n_times = -> n,f {
  n == 1 ? f : -> x { f.(n_times.(n-1,f).(x))}
}

# an nth derivator is a derivator called n times:
nth_derivator = -> n { 
  n_times.(n,derivate)
}


p nth_derivator.(1).(square).(3) # => 6 =  2*(3)
p nth_derivator.(2).(square).(3) # => 2 =  constant(2)
p nth_derivator.(3).(square).(3) # => 0 = constant(0)

logarithm = -> x { Math.log(x) }
p nth_derivator.(1).(logarithm).(3) #=> 0.3333333333430346 ~ 1/3 I can derivate whatever I want !
