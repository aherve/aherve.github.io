---
layout: post
title: "Having fun with functional programming in ruby"
date: 2014-02-27 21:51:46 +0100
comments: true
categories: 
 - ruby
 - functional programming
 - maths
---

Today we're going to play around with functional programming. Yay !

- _Ok, what's that exactly ?_

Wikipedia says it pretty much: 
> functional programming is a programming paradigm, a style of building the structure and elements of computer programs, that treats computation as the evaluation of mathematical functions and avoids state and mutable data. 

- Alright, now let's have some fun with functional programming style, and of course, let's do that with ruby :)

In this post we're going to manipulate some (high order) functions, and build a derivative operator in a functional style.

<!-- more -->

### Level 1 : some basic functions 
In ruby you can define a _lambda_ operator, that is an anonymous function that reads exactly as a mathematician would define it. For instance, 
```ruby 
square = -> x { x*x} #or its equivalent notation: square = lambda { |x| x*x }
plus_one = -> x { x+1}
```
defines a function that, when given an argument `x`, returns `x*x`.

We can call it and see the result : 
```ruby
square.(2) #=> 4
plus_one.(2) #=> 3
```

More interestingly, higher order function can be defined, whose purpose is to manipulate other functions.

For instance, let's define some basic operators `minus`,`mult`,`div` that can respectively add, subtract, multiply or divide functions altogether. 

Note that we want `new_function = minus.(f,g)` to return a function. 
Rather than describing how to subtract two values, we want to define what `f -g` means when both f and g are functions.


```ruby
minus = -> f,g { -> x { f.(x) - g.(x) } }
div   = -> f,g { -> x { f.(x) / g.(x) } }
mult  = -> f,g { -> x { f.(x) * g.(x) } }
```

Does that works ? With the previously defined functions:

```ruby
my_fancy_func = minus.(square,plus_one) # defining a new function
my_fancy_func.(3) #=> 5 = 3*3 - ( 3 + 1)
```

Sweet.

- _Allright, but how is that really fancy?_

Well, let's take our trip to a next step: 

### Level 2 : I can haz derivative ?

_Hey, I know an operator that works on functions : the derivative operator. How about we build one ?_

Alright. Let's build a derivative operator. That is, a function that takes a function as an argument, and return another function: its derivate.

The derivative of a function at some point _x_ can be obtained by evaluating
![derivative](/images/derivative.gif), _i.e._ the limit when epsilon -> 0 of a derivative scheme based on f at point x.

Here's the plan : 

- Define a limit operator
- define a derivative scheme
- define the derivative operator as the limit of the derivative scheme of a function
- Since we're at it, define any _nth derivative operator_ : We should be able to derivate n times any function.
- Profit and use it on _any function_ 

For the sake of clarity, let's begin with a simplified version, and assume that `epsilon = 1e-3` is low enough to approximate the limit of our derivative scheme.

Once we're more comfortable with the concepts, we'll get rid of this assumption and implement a true derivative operator.

```ruby
derivative = -> f { # we take a function as argument
  -> x { # the function takes a real x as argument
    ( f.(x+1e-3) - f.(x-1e-3) ) / ( 2e-5 ) # apply the scheme
  }
}

# Let's try:
derivative_of_square = derivative.(square)  => #<Proc:0x00000001b7c270@(irb):24 (lambda)> . Yay, a new function ! 

#Can we use it ? 
square.(3) # => 9
derivative_of_square.(3) #  => 5.999999999999339 ~ 2*3. Cool !
```

_Sooo... can I derivate twice ?_

Yup. Simply get the derivative of the derivative : 
```ruby
second_derivative_of_square = derivative.( derivative.(square) ) # this should be a constant function that return 2
second_derivative_of_square.(2) #=> 1.999999999946489
second_derivative_of_square.(3) #=> 2.000000000279556
```

_Sooooooo... can I derivate n times ?_

Yup. Although we don't want to create thousands of `third_derivative`,`forth_derivative`...etc, right ? 

Let's go one order higher and define the _nth derivative operator_

Since we can derivate a function, and we want to do it n times, what we miss is simply a `n-times combinator`. For example, `n_times.(f).(2)` should return `x -> f(f(x))` regardless of what `f` and `x` are.

What about we do it recursively ? 
```ruby
n_times = -> n,f {
  n == 1 ? f : -> x { f.(n_times.(n-1,f).(x))}
}
```

**Explanation** : 

- if _n = 1_ then we want f. so return f. So far so good, `n_times(1,f) = f`
- If _n = 2_, then we want f(f) = f( n_times.(1,f) )
- If _n = 3_, then we want f(f(f)) = f( n_times.(2,f) )

...etc. Get it ?

_Wait... that's all ? Where's my nth derivative ?_

Now it's quite easy to derivate n times : 

```ruby
nth_derivator = -> n { 
  n_times.(n,derivate)
}
```
This `nth_derivator` will take `n` as an argument, and derivate n times whatever we decide to pass to it.

Let's play with it!
```ruby
derivative_of_square = nth_derivator.(1).(square) #derivate one time
second_derivative_of_square = nth_derivator.(2).(square) #derivate two times
third_derivative_of_square = nth_derivator.(3).(square) #derivate three times

p derivative_of_square.(3) # => 5.999999999999339
p second_derivative_of_square.(3) # => 2.000000000279556
p third_derivative_of_square.(3) # => 0.0
```

_That's cool ! but those are approximations, right ? we never actually calculated the limit_

Yet.

### Level 3 : More functional, and a true limit operator

Now that we have a better feel for it (have we?), let's refactor our derivative operator so that is is _actually_ defined as a limit. And hey, let's parametrize the precision that we want since we're at it.

First, let's write a bunch of tools that are going to be useful: 
```ruby
minus = -> f,g { -> x { f.(x) - g.(x) } } # f - g
div   = -> f,g { -> x { f.(x) / g.(x) } } # f / g
mult  = -> f,g { -> x { f.(x) * g.(x) } } # f * g
norm  = -> f   { -> x { f.(x).abs}} # absolute value
const = -> const { -> x { const} } # That's right, the constant function !

# You should recognize these:
plus_eps = -> eps { -> f { -> x { f.(x+eps) } } }
min_eps  = -> eps { -> f { -> x { f.(x-eps) } } }

# is f < g ? 
inf = -> f,g { -> x { f.(x) < g.(x) } }
```

Now the limit function. Here we are going to define a function, that actually implement the following (naive) algorithm: 

- variables : a function `f`, a starting epsilon `eps`, and a threshold `tres`
- 1. Evaluate y = ||f(x + epsilon/2) - f(x + epsilon) ||
- 2. if y < tres, then f(x+epsilon) we are converged, and lowering epsilon wouldn't change the result much. Return f(x+epsilon).
- 3. else, reduce epsilon and try again (i.e. go to 1.)

Obviously, this algorithm is quite simple, and will only work when dealing with smooth, continuous, and gracious functions.

Ready ?
```ruby
lim = -> f,eps,tres {
  -> x {
    inf.(
      norm.(
        minus.(
          plus_eps.(eps/2.0).(f),
          plus_eps.(eps).(f)
        )
      ), const.(tres) ).(x) ? plus_eps.(eps).(f).(x) : lim.(f,eps/2.0,tres).(x)
  }
}

# Does it even work ?
lim.(square,1,1).(2) #=> 5.0625 wut ?
lim.(square,1,1e-2).(2) #=> 4.0156402587890625 Ah. Better
lim.(square,1,1e-16).(2) #=> 4.0 How nice !
```

Now we're getting close ! Let's refactor our derivative operator in a more appropriate way and get our final derivative operator: 

```ruby
# derivative_sche.(f).(x) will be a function of epsilon
derivative_sheme = -> f {
  -> x { 
    -> eps {
      div.( minus.(plus_eps.(eps).(f), min_eps.(eps).(f) ), mult.(const.(2), const.(eps))).(x)
    }
  }
}

# And the derivative operator: 
# Let's fix the treshold at tres = 1e-16
derivate = -> f {
  -> x { 
    lim.(derivative_sheme.(f).(x),1,1e-16).(0) # limit of the derivative scheme of f(x), taken at epsilon = 0
  }
}

# Isn't that fancy ? We juste define the derivative operator
# exactly as the limit of (f(x + e) - f(x - e))/(2e) when epsilon -> 0
```

### Summary

Here's a full code of what we implemented [(download it)](/assets/aherves_blog_ruby_functional.rb)

```ruby
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
```

Well that's all, hope you enjoyed reading this (at least) as much as I enjoyed writing it. Feel free to drop some comments, suggest anything, c orrect some code (or my english ) :)

