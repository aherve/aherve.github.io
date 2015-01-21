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
User.each do |user,i|
  Artist.all.take(10).each{|a| user.like_artist!(a)}
end

# Get a recommendation for the first user:
puts User.first.recommendations
