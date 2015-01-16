require './reco.rb'
class User
  include Mongoid::Document
  include Reco

  field :name 

  has_and_belongs_to_many :liked_artists, class_name: "Artist", inverse_of: :likers

  # add an artist to the list of liked_artists
  def like_artist!(artist)
    liked_artists << artist
  end

end
