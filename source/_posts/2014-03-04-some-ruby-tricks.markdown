---
layout: post
title: "some ruby tricks"
date: 2014-03-04 11:30:20 +0100
comments: true
categories: 
  - ruby

---

```ruby
a = [1,2,3]
b = a

a << 4
p a #=> [1,2,3,4]
p b #=> [1,2,3,4]

a = [1,2,3]
b = a.dup
a << 4

p a #=> [1,2,3,4]
p b #=> [1,2,3]

class Foo
  attr_accessor :msg
  def initialize(msg)
    @msg = msg
  end
end

f1 = Foo.new(1)
f2 = Foo.new(2)
f3 = Foo.new(3)

a = [f1,f2,f3]
b = a.dup

a << Foo.new(4)
p a.map(&:msg) #=> [1,2,3,4]
p b.map(&:msg) #=> [1,2,3]

f1.msg = -1
p a.map(&:msg) #=> [-1,2,3,4]
p b.map(&:msg) #=> [-1,2,3]
```


<!--

#- if a = b  #=> test assignement. useful to set a and reuse

#- duplicate objects : Foo.dup => new object. [Foo.new, Foo.new].dup => new array, with pointers...etc. Use marshall

#- k = 0. if k then  #=> true

#- include vs extend

#- p vs puts

-->
