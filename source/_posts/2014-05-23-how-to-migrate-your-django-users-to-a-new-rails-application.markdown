---
layout: post
title: "how to migrate your django users to a new rails application"
date: 2014-05-23 10:59:28 +0200
comments: true
categories: 
  - rails
  - django
  - devise
  - security
---

I recently had to migrate a users database from a django app to a brand new rails app. Is it possible to do that without having to request all our users to change their passwords ?

<!-- more -->

As you probably already know, plain-text passwords are not, and should **never** be stored in your database. When a user sign up, his/her password is [hashed](http://en.wikipedia.org/wiki/Cryptographic_hash_function) before the resulting hash is saved to the database.
When signin in, the user given password is hashed again, so both hashes (one is stored, the other is provided during the login process) can be checked against each other.

If you're working with rails then you probably know about [Devise](https://github.com/plataformatec/devise): an awesome authentication solution for rails.

Both django and rails/devise properly hash the users passwords. However the process is not the same, and a _django encrypted_ password will not be recognized by the Devise engine as it is.

### The pbkdf2-password-hasher gem

The app I had to deal with uses [pbkdf2](http://en.wikipedia.org/wiki/PBKDF2) encryption algorithm (I'm guessing it is a django standard but I have honestly no idea wether it is or not). The idea is then to teach devise how to check such an encrypted password.

I had some trouble to find something satisfying, so I wrote a gem : [pbkdf2-password-hasher](https://github.com/aherve/pbkdf2-password-hasher) to solve this issue. Basically, it implements in ruby the pbkdf2 encryption process, so we can easily check a password against a hashed string: 

```ruby
# hashed string from django app
hsh ='pbkdf2_sha256$12000$PEnXGf9dviXF$2soDhu1WB8NSbFDm0w6NEe6OvslVXtiyf4VMiiy9rH0=' 

# with right password:
Pbkdf2PasswordHasher.check_password('bite',hsh) #=> true

#with wrong password:
Pbkdf2PasswordHasher.check_password('bitten',hsh) #=> false
```

### Rasils/Devise integration

To use this gem in your rails application, simply call it from your Gemfile: 

```ruby Gemfile
gem pbkdf2_password_hasher
```

and run `bundle install`. Now that the gem is installed, we simply need to tell devise how to use it. To do this, let's override the `valid_password?` method on our model.

Let's say you created a `User` model, then simply add 

```ruby app/models/user.rb
def valid_password?(pwd)
  begin
    super(pwd) # try the standard way
  rescue
    Pbkdf2PasswordHasher.check_password(pwd,self.encrypted_password) # if failed, then try the django's way
  end
end
```
to your model's definition.

And *voilà* ! Old users can login using their old passwords, whereas new users will still be able to create new accounts, that will be dealt with in the usual devise way.

Isn't that nice ?

Aurélien
