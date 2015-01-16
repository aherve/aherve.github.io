class Artist
  include Mongoid::Document

  field :name 

  has_and_belongs_to_many :likers, class_name: "User", inverse_of: :liked_artists

end
