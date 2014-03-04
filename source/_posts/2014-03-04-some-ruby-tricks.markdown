---
layout: post
title: "some ruby tricks"
date: 2014-03-04 11:30:20 +0100
comments: true
categories: 
  - ruby
  - deep copy
  - pointers
---


### pointers, duplicate and deep copy


```ruby
a = [1,2,3]
b = a

a << 4 # modify the array

p a #=> [1,2,3,4] # 4 is added to a
p b #=> [1,2,3,4] # b is also modified

a += [5] # this does not modify a, it creates a new one

p a #=> [1,2,3,4,5] # a now includes 5
p b #=> [1,2,3,4]   # b is NOT modified
```

```ruby
a = [1,2,3]
b = a.dup # create a duplicate of a
a << 4    # modify a

p a #=> a =  [1,2,3,4] # a is modified
p b #=> a =  [1,2,3]   # b is unchanged
```

```ruby
class Foo
  attr_accessor :msg
  def initialize(msg)
    @msg = msg
  end
end

#Create 3 objects
f1 = Foo.new(1)
f2 = Foo.new(2)
f3 = Foo.new(3)

a = [f1,f2,f3] # new array
b = a.dup      # duplicate the array

a << Foo.new(4) # modify a

p a.map(&:msg) #=> [1,2,3,4] # a is changed
p b.map(&:msg) #=> [1,2,3]   # a is unchanged

# modify the object f1
f1.msg = -1 

p a.map(&:msg) #=> [-1,2,3,4] # output changed
p b.map(&:msg) #=> [-1,2,3]   # output also changed !
```

```ruby
f1 = Foo.new(1)
f2 = Foo.new(2)
f3 = Foo.new(3)

a = [f1,f2,f3]
b = Marshal.load(Marshal.dump(a)) #dump binary value of a and reload it in new object

a << Foo.new(4)
a.first.msg = -1

p a.map(&:msg) #=> [-1,2,3,4] # a has changed
p b.map(&:msg) #=> [1,2,3]    # b is now completely independant
```

```ruby
# generate arrays of consecutive numbers
def consecutives(size)
  Enumerator.new do |enum|
    integers = (0..Float::INFINITY).lazy   # integers generator
    a = []                                 # initialyze array
    size.times { a << integers.next }      # get first elements
    loop do 
      enum << a                            # yield result
      a << integers.next                   # add next integer to array
      a.shift                              # remove array's first item
    end
  end
end

# Create an iterator that yields arrays of size 3
c3 = consecutives(3) 

p c3.take(5) #=> [[4, 5, 6], [4, 5, 6], [4, 5, 6], [4, 5, 6], [4, 5, 6]]
```

```ruby
a = a + [integers.next] 
a += [integers.next]
```
