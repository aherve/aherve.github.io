---
layout: post
title: "building a recommendation engine with ruby"
date: 2015-01-16 10:12:33 +0100
comments: true
categories: 
 - ruby
 - tutorial
 - collaborative filtering
 - mongoid
 - mongodb
 - algorithm
 - complexity
---

### What is this about

Today we'll learn what's happening in a recommendation engine by building a simple, yet powerful collaborative filtering engine. 

Yay !

<!-- more -->

## 1. What we have

Let's say we have a music app. We have access to the music our users like, and it'd be tremendous to recommend new music to people (please don't steal my idea, I might get rich with this someday).

We'll use mongodb as our database, along with [mongoid](http://mongoid.org/en/mongoid/index.html) which I find to be quite awesome.

Allright, let's roll !

## Basic class definitions

First of all, let's define some `User` and `Artist` classes. In our app, a user has a list of liked artists, whereas the artist has a list of likers.

```ruby user.rb
class User
  include Mongoid::Document

  field :name 

  has_and_belongs_to_many :liked_artists, class_name: "Artist", inverse_of: :likers

end
```

```ruby artist.rb
class Artist
  include Mongoid::Document

  field :name 

  has_and_belongs_to_many :likers, class_name: "User", inverse_of: :liked_artists

  # add an artist to the list of liked_artists
  def like_artist!(artist)
    liked_artists << artist
  end

end
```

We can use a simple script to load our classes and play with them:

__Note:__ _For better readability I'm not including the `Gemfile`, nor the `mongoid.yml` file here. A complete example is available to download at the end of this post._

```ruby demo.rb
#!/usr/bin/env ruby
# User bundler to install gems
require 'bundler'
Bundler.setup(:default)

require 'mongoid'
require './user.rb'
require './artist.rb'

# load mongoid config file
Mongoid.load!("./mongoid.yml", :development)

# Let's clean the base, then create some users
User.destroy_all
User.create([
  {name: 'Alphonse'},
  {name: 'Hubert'}  ,
  {name: 'Penelope'},
  {name: 'Henri'}   ,
  {name: 'Huguette'},
])

# Let's create some artists:
Artist.destroy_all
Artist.create([
  {name: 'John Coltrane' },
  {name: 'Wayne Shorter' },
  {name: 'McCoy Tyner'   },
  {name: 'Lady Gaga'     },
  {name: 'Franz Schubert'},
])

# Did it work?
puts User.count   #=> 5
puts Artist.count #=> 5

# add a relation:
User.first.like_artist!(Artist.first)

puts User.first.inspect   #=> <User _id: 54b8e2bc6168651713000000, name: "Alphonse", liked_artist_ids: [BSON::ObjectId('54b8e2bc6168651713050000')]>
puts Artist.first.inspect #=> #<Artist _id: 54b8e2bc6168651713050000, name: "John Coltrane", liker_ids: [BSON::ObjectId('54b8e2bc6168651713000000')]>

puts User.first.liked_artists.map(&:name) #=> John Coltrane
```

Allright, everything seems to work just fine. Time for the fancy stuff !

## 2. Collaborative filtering

### Collaborative filtering in a nutshell

Collaborative filtering is not that difficult to understand: 

 - You like stuff
 - There are other people who also like the same stuff
 - These very people do like other stuff (that you don't even know about)
 - You might want to know about it.

Now for the implementation. There is of course a lot of details and variations in the existing algorithms.
The one we are going to implement is the following (in pseudo-code):

 - Find every user that share at least one favorite artist with you
 - For each found user `u`:
   - calculate the number of favorite artists you share. The more artists you share with a user, the more weight we'll had to _his recommendation_.
   - Divide the obtained sum by the total number of artists the user like. We don't want a serial liker to pollute our score and recommend __everything__ with too much of a weight. Let's call `weight(u)` the weight of this user `u`
   - for all the artists `a` the user `u` like, add `weight(u)` to our result: `result(a) += weight(u))`
 - sort the list and get the most recommended artists !

### Shall we implement it?

Yes we can. Let's create a fancy `recommended_artists` method for the users that we write in a `reco` module (in rails we would put this module under `app/models/concerns/reco.rb`) :

```ruby user.rb
require './reco.rb'
class User
  include Mongoid::Document
  include Reco
  
  ...
```

```ruby reco.rb
module Reco

  # will recommend artists to a user
  def recommendations

    # fetch my list of liked artists. We only need their id and liker_ids (not the name, nor anything else)
    my_artists = liked_artists.only(:id, :liker_ids)

    # fetch my list of 'friends'. Again, we only need id and liked_artist_ids :
    friends = User.any_in(id: my_artists.distinct(:liker_ids)).only(:id, :liked_artist_ids)

    # Initialize the result:
    reco = Hash.new(0)

    # Let's roll
    friends.each do |friend|

      # the number of liked artists we share:
      in_common = (friend.liked_artist_ids & self.liked_artist_ids)

      # The friend's weight:
      w = in_common.size.to_f / friend.liked_artist_ids.size

      # Add the recommendations:
      ( friend.liked_artist_ids - in_common).each do |artist_id|
        reco[artist_id] += w
      end

    end

    # find artist names, sort and return in a pretty format:
    Artist.any_in(id: reco.keys)
    .only(:id, :name)                 #only name and id here
    .sort_by{|a| reco[a.id]}          #sort by our reco results
    .reverse                          # higher score first
    .map{|a| [a,reco[a.id].round(2)]} # associate record with its score

  end

end
```

Looks nice, how about we try it with a slightly modified script:

```ruby demo.rb
#!/usr/bin/env ruby
# User bundler to install gems
require 'bundler'
Bundler.setup(:default)

require 'mongoid'
require './user.rb'
require './artist.rb'

# load mongoid config file
Mongoid.load!("./mongoid.yml", :development)

# Create 100 users, and artists
User.destroy_all
Artist.destroy_all

100.times do |i|
  User.create(name: "user_#{i}")
  Artist.create(name: "artist_#{i}")
end

# Each user like 20 random artists:
User.each do |user|
  Artist.all.take(10).each{|a| user.like_artist!(a)}
end

# Get a recommendation for the first user:
puts User.first.recommendations
```

wich outputs

```ruby
[[#<Artist _id: 54b8f9be61686519afc70000, name: "artist_99", liker_ids: nil>, 7.3],
 [#<Artist _id: 54b8f9be61686519af1d0000, name: "artist_14", liker_ids: nil>, 1.7],
 [#<Artist _id: 54b8f9be61686519af150000, name: "artist_10", liker_ids: nil>, 1.7],
 [#<Artist _id: 54b8f9be61686519afc50000, name: "artist_98", liker_ids: nil>, 1.0],
 [#<Artist _id: 54b8f9be61686519af1b0000, name: "artist_13", liker_ids: nil>, 0.9],
 [#<Artist _id: 54b8f9be61686519af190000, name: "artist_12", liker_ids: nil>, 0.9],
 [#<Artist _id: 54b8f9be61686519af170000, name: "artist_11", liker_ids: nil>, 0.9],
 [#<Artist _id: 54b8f9be61686519af250000, name: "artist_18", liker_ids: nil>, 0.9],
 [#<Artist _id: 54b8f9be61686519af1f0000, name: "artist_15", liker_ids: nil>, 0.9],
 [#<Artist _id: 54b8f9be61686519af210000, name: "artist_16", liker_ids: nil>, 0.9],
 [#<Artist _id: 54b8f9be61686519af230000, name: "artist_17", liker_ids: nil>, 0.7],
 [#<Artist _id: 54b8f9be61686519afc30000, name: "artist_97", liker_ids: nil>, 0.2],
 [#<Artist _id: 54b8f9be61686519afb90000, name: "artist_92", liker_ids: nil>, 0.2],
 [#<Artist _id: 54b8f9be61686519afbb0000, name: "artist_93", liker_ids: nil>, 0.2],
 [#<Artist _id: 54b8f9be61686519afbd0000, name: "artist_94", liker_ids: nil>, 0.2],
 [#<Artist _id: 54b8f9be61686519afbf0000, name: "artist_95", liker_ids: nil>, 0.2],
 [#<Artist _id: 54b8f9be61686519afc10000, name: "artist_96", liker_ids: nil>, 0.2]]
```

{% img right /images/happy_people.gif %}

Look Mom, it's working !!!!

[Download the sources](/assets/reco_engine.tgz)

### 3. Performances / Why it's awesome

Let's take a closer look at our algorithm complexity here, and explain how we take advantage of the mongo's NoSQL structure.

Unlike when dealing with a SQL database, we have deliberately denormalized our data. When we open a `User` document, we can see an array of ids that represent the list of his/her favorite artists. When opening the corresponding `Artist` document, whe can see a list of `liker_ids` that correspond to the artist's likers.

Now if we look at our algorithm in terms of requests, what we actually are doing is:

 - Open the current_user document. When recommending for me, this represent my profile.
 - In my document I find an array of artists. No additional query here.
 - Perform one db query to obtain all the `likers` of the artists I like with `friends = User.any_in(id: my_artists.distinct(:liker_ids)).only(:id, :liked_artist_ids)`. Note that we find the `Artist` documents by their ids, then simply concatenate their respective `liker_ids` arrays. No need to index any relation table, or foreign key. Furthermore, from this single request we already know what our 'friends' like, since every friend document contains a `liked_artist_ids` array.
 - At this stage we already nailed down the interesting users among our database, and we can browse through their liked artists without performing any additional query.

This pretty much implies that the complexity of our algorithm doesn't depend on the number of users, but rather to the interconnection level of our graph.

In other words: if we add billions of user that doesn't share any liked artist with you, then your recommendation query would be totally unaffected. But if everybody loved the same artists, then we'd have some trouble.

Another very good example of such an algorithm is the "friend recommender". Having billions of users where evey user have an average of 50 friends is a piece of cake to deal with. But of course, if a single user would become the friend of __everyone__, then you'd simply have to browse the whole database to find your friend's friends. In a social graph this is very unlikely to happen: I'm way too hipster to befriend such a guy.

I've slightly modified the demo script to `big_reco.rb`. We can see what happens with 100k users, that randomly like 10 artists each, among a 1k artists database:

100,000 users, 1,000 artists and 10 likes per user:
```ruby
u = User.all.sample(1).first
puts User.count #=> 100000
puts Benchmark.measure{ u.recommendations} #=> 1.060000   0.000000   1.060000 (  1.127213)
```

As you can see this is still pretty fast and run in about a second on an average laptop. Actually, preparing the database was hat took a while, so I didn't make many more examples. Feel free to send me some if you are brave enough to try :)

Note that even with millions of users, a proper cache structure along with background jobs can garanty recommendations that take less than _300ms_. Let me know if you're intested, I might consider writing a tuto about how to design such a background engine !

### Conclusion

Thanks for reading, I hope this was of some interest for you, feel free to ask any question or to share your feedback !

[Download the sources](/assets/reco_engine.tgz)
