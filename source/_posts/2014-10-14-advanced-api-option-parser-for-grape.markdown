---
layout: post
title: "Building an advanced api option parser for grape"
date: 2014-10-14 09:52:35 +0200
comments: true
categories: 
 - ruby
 - grape
 - api
---


When building an elaborated api, you might want your users to pass parameters in order to describe exactly what response they expect from the api.

For instance, it is useful to be able to do something as 

```ruby
GET '/users/:id', {users: {name: true}}  # => find a user and get his name only
GET '/users/:id', {users: {email: true, name: true}} # => find a user and get both his name and email
GET '/users/:id', {users: {email: true, name: true, posts: true}, post: {title: true}} # => find a user and get his name, his email, and all his posts titles
```
instead of presenting all of the model's attributes at each api call.
## 1. Basic grape/entity usage

At [Shapter](http://shapter.com) we use the awesome [Grape](https://github.com/intridea/grape) api framework, along with [grape-entity](https://github.com/intridea/grape-entity).

For instance, let's say we wan to build a route that finds and present a user:

```ruby AwesomeApp/entities/user.rb
module AwesomeApp
  module Entities
    module User < Grape::Entity
      expose :id
      expose :name
      expose :email
    end
  end
end
```

```ruby api/users.rb
namespace :users do  # prefix routes with 'users/'
  desc "get a user" # describe your method for the documentation
  params do 
    requires "user_id", desc: "id of the user" # requires a user_id to be passed
  end
  get ':user_id' do  # this will get the params[:user_id] from the url
    user = User.find(params[:user_id]) || error!('user not found',404) # find the user
    present user, with: AwesomeApp::Entities::User  # use grape-entity to present the model
  end
end
```

This setup will create a `/users/:id/` route that returns a user in a hash of the form `{id: 123, name: "John Doe", email: "foo@bar.com"}`

## 2. With a bit of optimization

If your api is to grow more complex, the number of exposed attributes can quickly increase, and with it the size of the json hash the api sends. However you do not want all of the `User`'s attributes to be return each time you call your route.

To avoid unnecessary overload, you can build an option parser that allow the api-user to describe the type of response he's expecting.

#### Add conditional exposures to your entity

First we tell entity to expose attributes only when asked to:

```ruby AwesomeApp/entities/user.rb
module AwesomeApp
  module Entities
    module User < Grape::Entity
      expose :id # always expose the id
      expose :name, if: lambda{ |user,options| options[:entity_options]["user"][:name]}   #conditional exposure
      expose :email, if: lambda{ |user,options| options[:entity_options]["user"][:email]} #conditional exposure
    end
  end
end
```

#### create a helper to parse the options

Next, we create a helper that will read `params` to avoid tedious code duplication:

```ruby AwesomeApp/Helpers/OptionsHelper
# white-list params[:entities][<some_model>], and create empty hashes if needed:
def entity_options
  {
    "user" => (params[:entities]["user"] rescue nil) || {},
    "post" => (params[:entities]["post"] rescue nil) || {},
  }
end
```

#### pass the options hash to Grape::Entity

Finally, we need to connect everything in the api method description:

```ruby api/users.rb
helpers AwesomeApp::Helpers::OptionsHelper #include the helper

namespace :users do  
    ...
    present user, with: AwesomeApp::Entities::User, entity_options: entity_options #simple call entity_options
end
```

#### Profit

And _Voila_ !

Now your api-users can efficiently call the routes to get the attributes they want:
```ruby
GET '/users/:id', {users: {name: true}}  # => find a user and get his name only
GET '/users/:id', {users: {email: true, name: true}} # => find a user and get both his name and email
```

### Bonus: it works with nested model exposures !

Note that this system supports nested models exposures. For instance, if you want to get a user, and a list of his post ids and titles, then the following will work like a charm:

```ruby AwesomeApp/entities/user.rb
#AwesomeApp/entities/user.rb
module AwesomeApp
  module Entities
    module User < Grape::Entity
      expose :id # always expose the id
      expose :name, if: lambda{ |user,options| options[:entity_options]["user"][:name]}   #conditional exposure
      expose :email, if: lambda{ |user,options| options[:entity_options]["user"][:email]} #conditional exposure
      expose :posts, using: AwesomeApp::Entities::Post, if: lambda{ |user,options| options[:entity_options]["user"][:posts]} # present user's posts
    end
  end
end

#AwesomeApp/Entities/post.rb
module AwesomeApp
  module Entities
    module Post < Grape::Entity
      expose :id # always expose the id
      expose :title, if: lambda{ |post,options| options[:entity_options]["post"][:name]}   #conditional exposure
      expose :content, if: lambda{ |post,options| options[:entity_options]["post"][:email]} #conditional exposure
    end
  end
end
```

Without changing anything to the api, you can now call
```ruby
GET '/users/123', entity_options: { user: {name: true, posts: true}, post: {title: true}}
```
To tell the api you want to include the user's post ids in the response. You will then get something that looks like
```
{
  id: 123,
  name: "John Doe",
  posts: [
    {id: 456, title: "first post" }, #post content is not asked for, therefore not sent
    {id: 789, title: "second post" },
  ]
}
```
