#!/usr/bin/env ruby
# User bundler to install gems
require 'bundler'
Bundler.setup(:default)

require 'benchmark'
require 'mongoid'
require './user.rb'
require './artist.rb'

# load mongoid config file
Mongoid.load!("./mongoid.yml", :development)

# Create 1_000_000 users, and 1_000 artists
Mongoid.purge!

user_count                     = 100_000 
artist_count                   = 1_000 
average_liked_artists_per_user = 10 

User.collection.insert( (0..user_count - 1).map{|i| {name: "user_#{i}"}} )
Artist.collection.insert( (0..artist_count - 1).map{|i| {name: "artist#{i}"}} )

artists = Artist.all.to_a

# Warning, this is highly inefficient, and will take forever to load :D
User.each_with_index do |u,i|
  puts i if i % 100 ==  0
  u.liked_artists << artists.sample(average_liked_artists_per_user)
end

#Benchmark the recommendation engine:
u = User.all.sample(1).first

puts Benchmark.measure{ u.recommendations}
