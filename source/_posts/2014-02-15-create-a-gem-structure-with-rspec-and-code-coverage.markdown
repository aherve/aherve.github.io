---
layout: post
title: "create a gem structure with rspec and code coverage"
date: 2014-02-15 21:59:36 +0100
comments: true
categories: 
 - ruby
 - gem
 - rspec
 - coverage
 - recipie
---

###tl;dr

This is a step-by-step tutorial for creating a gem structure, along with some unit tests and code coverage.

##1. Bundle: create the structure

- Create the directories using bundler:
```
$ bundle my_fancy_gem
create  my_fancy_gem/Gemfile
create  my_fancy_gem/Rakefile
create  my_fancy_gem/LICENSE.txt
create  my_fancy_gem/README.md
create  my_fancy_gem/.gitignore
create  my_fancy_gem/my_fancy_gem.gemspec
create  my_fancy_gem/lib/my_fancy_gem.rb
create  my_fancy_gem/lib/my_fancy_gem/version.rb
Initializing git repo in <wherever you are>/my_fancy_gem
```
- fill the gem description in `my_fancy_gem.gemspec`

##2. Configure rspec

- add rspec to the dependencies in `my_fancy_gem.gemspec`:
```ruby my_fancy_gem.gemspec
...
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
```
and make sure you install it: 
    $ bundle

- create `spec/spec_helper.rb` file:
```ruby spec/spec_helper.rb
require 'rspec'
require 'my_fancy_gem'
```

- I like it better with colors. In `.rspec`:
```ruby .rspec
--color
```

### Now let's create some method and test it
Let's write a hello world method with TDD

- in `spec/my_fancy_gem_spec.rb`
```ruby spec/my_fancy_gem_spec.rb
require 'spec_helper'
describe SmartadCollector do 
  it "should greet" do 
    SmartadCollector::greet.should == "Hello, world!"
  end
end
```
- Proudly watch the test failing by running `rspec`
- Now let's write the actual method: `lib/my_fancy_gem_spec.rb`
```ruby lib/my_fancy_gem.rb
require "my_fancy_gem/version"

module MyFancyGem
  def self.greet
    "Hello, world!"
  end
end
```
and (even more) proudly watch the test pass:
    $ rspec #=> 1 example, 0 failures

##3. Adding code coverage tools
[SimpleCov](https://github.com/colszowka/simplecov) to get code coverage:

- add `spec.add_development_dependency "simplecov"` in `my_fancy_gem_spec.gemspec`.
- `$ bundle install` to install the simple cov gem

- create a `.simplecov` file:
```ruby .simplecov
SimpleCov.start do 
  add_group "lib", "lib"
end
```

- add it to rspec: `spec/spec_helper.rb`:
```ruby spec/spec_helper.rb
require 'rspec'
require 'simplecov'
require 'my_fancy_gem_spec'
```
Please note that the `require 'simplecov'` has to be added before `require 'my_fancy_gem_spec'`.

Now running `$ rspec` will output a report on code coverage, as well as a `coverage` directory. You can browse `coverage/index.html` to view the detailed report.
