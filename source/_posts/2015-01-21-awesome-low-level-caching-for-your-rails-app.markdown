---
layout: post
title: "Awesome low level caching for your Rails app"
date: 2015-01-21 13:13:20 +0100
comments: true
categories: 
 - ruby
 - tutorial
 - api
 - rails
 - RoR
 - cache
 - mongoid
 - redis
---

### Performant cache structure to save duplicate calculations

Rubyist love the DRY moto (Don't Repeat Yourself). Here's how to implement a cache structure so that we Don't Calculate Twice.

What we want: 

 - Don't compute anything twice, until there is a good reason to think the result might change
 - Any change in the database should be immediatly visible to users (no caching for a few minutes, hoping things won't change too fast)
 - Don't compute anything that has not be requested by a user (_i.e._ don't pre-calculate everything )

Sounds awesome, how do we proceed ?

<!-- more -->

## The best blog app ever

Say we have a blogging platform where your users can write posts. For each post can be commented by the viewers, and each comment itself can be upvoted or downvoted.

{% img center /images/cache_diag.png %}

We could define an _interesting comment_  is a comment where the number of upvoters is higher than the number of downvoters, so it has a `comment.score > 0`.

Now what about we extract the number of interesting comments a user generated through his/her posts ? 


### Methods definitions without cache

First, let's define a structure that will define `User`, `Post` and `Comment`:

```ruby app/models/comment.rb
class Comment
  include Mongoid::Document
  include Mongoid::Timestamps

  # the comment have a content
  field :content, type: String

  # stores the score for queries
  field :score, type: Integer

  # the comment belongs to a post
  belongs_to :post

  # the comment have upvoters
  has_and_belongs_to_many :upvoters  , class_name: "User", inverse_of: "liked_comments"

  # the comment have downvoters
  has_and_belongs_to_many :downvoters, class_name: "User", inverse_of: "disliked_comments"

  # score is computed, then stored at each save:
  before_save :set_score

  def set_score
    self.write_attributes(score: upvoter_ids.size - downvoter_ids.size)
  end

end
```

```ruby app/models/post.rb
class Post
  include Mongoid::Document
  include Mongoid::Timestamps

  # the post belongs to its author
  belongs_to :author, class_name: "User", inverse_of: :posts

  # the post content
  field :content, type: String

  # the post has many comments
  has_many :comments

  # How many interesting comments does it have?
  def interesting_comments_count
    comments.gt(score: 0).count #gt = greater than
  end
end
```

```ruby app/models/user.rb
class User
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :posts, class_name: "Post", inverse_of: :author

  # the post score is the sum of all posts scores
  def interesting_comments_count
    posts.map(&:interesting_comments_count).reduce(:+) #map/reduce rules
  end
end
```

## The _fastest_ blog app ever

Now that we have our structure working, let's add some cache to make this the fastest (and smartest) engine ever.

Rails has a nice tool for managing cache. You can either configure `Rails.cache` to use a [redis](http://redis.io/) database, or keep the default parameters.

In particular, we can use `Rails.cache.fetch( key, expires_in: seconds) do ...` that will do the following:

 - If a value is found at the given key, then return it
 - If no value is found (_i.e._ such key doesn't exist), then execute the block, returns its result, and store the result as the new value for key `key`.


Let's use the cache to cache methods results at low level:
In `comment.rb` we add:
```ruby app/models/comment.rb
class Comment
  ...
  after_save :touch_post
  def touch_post
    post.save # this will update the `updated_at` key of our post
  end
end
```

This first addition will change the `post` timestamp each time a comment is upvoted or downvoted so that from the `post` model, we'll know something has changed.

```ruby app/models/post.rb
  def interesting_comments_count

    # when was the last update ?
    date_key = self.updated_at

    # create unique key for each post, method, and timestamp
    cache_key = "postInterestingCommentCount|#{id}|{date_key}"

    # Fetch the value, or calculate it then store it into cache:
    Rails.cache.fetch(cache_key, expires_in: 2.days) do 
      comments.gt(score: 0).count #gt = greater than
    end
  end
```

__Explanations__: 

 - First run: a key is created, the result is calculated and stored at the key address.
 - Another `interesting_comments_count` call happens. If no comment score has been updated, then the key will be the same, and the result will be presented without running any query. Fine
 - Someone upvote a comment. The post timestamp updates thanks to our `comment` callback. Thus, the `date_key` returns a different value. The computed `cache_key` changes, and we are now looking at a key address where no results exists yet. Back to step one.

 As a result of this, we can see that when a cache key becomes outdated, then it is not destroyed nor looked for: it is simply ignored and replaced by a new key that will be used until further change.

To avoid overloading your base, an expiration date is set, so that after a while, any key will simply be destroyed after a while.

Simple, isn't it ? 

Now let's go a step further with the same idea in mind:

in our `Post definition`: 
```ruby app/models/post.rb
class Post
  ...
  after_save :touch_user
  def touch_user
    user.save # this will update the `updated_at` key of our user
  end
end
```

in `User`:
```ruby app/models/user.rb
class User
  ...
  def interesting_comments_count
    cache_timestamp = self.updated_at
    cache_key = "userInterestingCommentCount|#{id}|#{cache_timestamp}"

    Rails.cache.fetch(cache_key, expires_in: 2.days) do 
      posts.map(&:interesting_comments_count).reduce(:+) 
    end
  end
end
```

This additional step uses exactly the same strategy as before.

Now take a look at what would happen in real conditions.

 - A user `u` has 10 posts.
 - __`u.interesting_comments_count` is called:__
   - A cache key is generated for each `Post` that belongs to `u`
   - An additional cache key is generated for our user `u`.
 - __`u.interesting_comments_count` is called again:__ 
   - The higher level cache key finds a result, and return. No db query is run.
 - A comment is being upvoted
   - it touches the corresponding comment
   - the corresponding comment itself triggers a callback => the corresponding user is touched
 - __`u.interesting_comments_count` is called:__
   - the user cache key is outdated and the method is run again.
   - For 9 of the 10 posts, the `post.interesting_comments_count` has an active cache key and the result is instantly returned
   - For the post that changed, the result is calculated, and returned while a new cache key is being generated.
 - back to step 2

If you're still with me here, then you've probably seen how this cache structure allows to calculate __exactly__ what is necessary, and __only__ when required to do so.

How awesome is that ?


{% img center /images/awesome.gif %}

### Conclusion

For most of the apis I write, I'm using this trick quite extensively. It allows any user/developper to call any method without having to fear to trigger unnecessary long calculations. 

I hope this was of some help, feel free to give your feedback or to ask any questions !
