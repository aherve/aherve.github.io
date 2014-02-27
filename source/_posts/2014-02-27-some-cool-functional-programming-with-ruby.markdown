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

### Level 1 : some basic functions 
In ruby you can define a _lambda_ operator, that is an anonyomous function that reads exactly as a mathematician would define it. For instance, 
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

For instance, let's define some basic operators `minus`,`mult`,`div` that can respectively add, substract, multiplicate or divide functions altogether. 

Note that we want `new_function = minus.(f,g)` to return a function. 
Rather than describing how to substract two values, we want to define what `f -g` means when both f and g are functions.


```ruby
minus = -> f,g { -> x { f.(x) - g.(x) } }
div   = -> f,g { -> x { f.(x) / g.(x) } }
mult  = -> f,g { -> x { f.(x) * g.(x) } }
```

does that works ? With the previously defined functions:

```ruby
my_fancy_func = minus.(square,plus_one) # defining a new function
my_fancy_func.(3) #=> 5 = 3*3 - ( 3 + 1)
```

Sweet.

- _Allright, but how is that really fancy?_

Well, let's take our trip to a next step: 

### Level 2 : I can haz derivative ?

_Hey, I know an operator that works on functions : the derivative operator. How about we build one ?_

Alright. Le't build a derivative operator. That is, a function that takes a function as an argument, and return another function: its derivate.

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
    ( f.(x+1e-3) - f.(x-1e3) ) / ( 2e-3 ) # apply the scheme
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

let's go one order higher and define the _nth derivative operator_

Since we can derivate a function, and we want to do it n times, what we miss is simply a `n-times combinator`. For example, `n_times.(f).(2)` should return `x -> f(f(x))` regardless of what `f` and `x` are.

What about we do it recursively ? 
```ruby
n_times = -> n,f {
  n == 1 ? f : -> x { f.(n_times.(n-1,f).(x))}
}
```

**Explanation** : 

- if _n = 1_ then we want f. so return f. So far so good.
- If _n > 1_, then we want to apply f( (n-1)times.(f) )
